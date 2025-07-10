import 'dart:async';
import 'dart:convert';

import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:gadgets/shared/utils/wrapped_logger.dart';

/// first-level use case
/// 防止假死
/// [delay] 秒, 要比心跳间隔稍大一点
class ClipboardAutoDisconnect {
  late final StreamSubscription<ClipboardNotify> _notifySub;
  late final StreamSubscription<SseConnectionState> _stateSub;
  final int delay;
  final ClipboardNotifyRepository _repository;
  Timer? _timer;

  ClipboardAutoDisconnect(ClipboardNotifyRepository repository, this.delay)
    : _repository = repository {
    _notifySub = repository.notifyStream.listen((data) {
      _resetTimer();
    });
    _stateSub = repository.stateStream.listen((state) {
      if (state is SseDisconnectedState) {
        _timer?.cancel();
      }
      if (state is SseConnectedState) {
        _resetTimer();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: delay), _timerCallback);
  }

  void _timerCallback() {
    _repository.disconnect();
  }

  void dispose() {
    _stateSub.cancel();
    _notifySub.cancel();
  }
}

class ClipboardConfigUpdate {
  const ClipboardConfigUpdate();
}

/// 提供配置
/// 提供一个配置更新事件
class ClipboardConfigUseCase {
  late final StreamSubscription<ClipboardNotify> _subscription;
  late final StreamSubscription<SseConnectionState> _stateSubscription;

  final _configController = StreamController<ClipboardConfigUpdate>.broadcast();
  final _availableController = StreamController<bool>.broadcast();

  Stream<ClipboardConfigUpdate> get stream => _configController.stream;

  Stream<bool> get availableStream => _availableController.stream;

  ClipboardConfigUseCase(ClipboardNotifyRepository repository) {
    _subscription = repository.notifyStream.listen(_onNotify);
    _stateSubscription = repository.stateStream.listen(_onState);
  }

  void _onState(SseConnectionState state) {
    if (state is SseConnectedState) {
      _connected = true;
    } else {
      _connected = false;
      _cursor = null;
      _usage = null;
      _config = null;
    }
    _checkAvailabilityChange();
  }

  void _checkAvailabilityChange() {
    bool newAvailable =
        _connected && (_cursor != null && _usage != null && _config != null);
    if (_available != newAvailable) {
      _available = newAvailable;
      _availableController.add(_available);
    }
  }

  void _onNotify(ClipboardNotify notify) {
    if (notify is NotifyInit) {
      _cursor = notify.cursor;
      _config = notify.config;
      _usage = notify.usage;
      _checkAvailabilityChange();
      _configController.add(const ClipboardConfigUpdate());
    } else {
      ClipboardUsage? usage = ClipboardNotify.getUsage(notify);
      if (usage != null &&
          (_usage == null || _usage!.timestamp < usage.timestamp)) {
        _usage = usage;
        _configController.add(const ClipboardConfigUpdate());
      }
    }
  }

  bool _connected = false;

  bool _available = false;

  int? _cursor;

  int? get cursor => _cursor;

  ClipboardUsage? _usage;

  ClipboardUsage? get usage => _usage;

  ClipboardConfig? _config;

  ClipboardConfig? get config => _config;

  bool get available => _available;

  void dispose() {
    _subscription.cancel();
    _stateSubscription.cancel();
    _configController.close();
    _availableController.close();
  }
}

enum ClipboardOperation { add, remove, clear, copy, scan }

class ClipboardOperationState {
  final ClipboardOperation operation;
  final bool success;
  final dynamic cause;
  final dynamic data;

  ClipboardOperationState({
    required this.operation,
    required this.success,
    this.cause,
    this.data,
  });
}

class CannotOperationException implements Exception {}

class ValidationFailedException implements Exception {}

/// 共享操作提示流
class ClipboardTipUseCase {
  final _operationStream =
      StreamController<ClipboardOperationState>.broadcast();

  Stream<ClipboardOperationState> get stream => _operationStream.stream;

  void addOperationState(ClipboardOperationState state) {
    _operationStream.add(state);
  }

  void dispose() {
    _operationStream.close();
  }
}

abstract class _ClipboardOperationBase {
  final _logger = WrappedLogger();
  final ClipboardTipUseCase _tipUseCase;
  final ClipboardConfigUseCase _configUseCase;

  _ClipboardOperationBase({
    required ClipboardConfigUseCase configUseCase,
    required ClipboardTipUseCase tipUseCase,
  }) : _tipUseCase = tipUseCase,
       _configUseCase = configUseCase;

  Future<void> _makeRequest<T>({
    required ClipboardOperation op,
    bool Function()? validate,
    required Future<T> Function() call,
    void Function(T)? doOnNext,
  }) async {
    if (!_configUseCase.available) {
      _tipUseCase.addOperationState(
        ClipboardOperationState(
          operation: op,
          success: false,
          cause: CannotOperationException(),
        ),
      );
      return;
    }
    if (validate != null) {
      final result = validate();
      if (!result) {
        _tipUseCase.addOperationState(
          ClipboardOperationState(
            operation: op,
            success: false,
            cause: ValidationFailedException(),
          ),
        );
        return;
      }
    }
    try {
      final response = await call();
      if (doOnNext == null) {
        _tipUseCase.addOperationState(
          ClipboardOperationState(operation: op, success: true, data: response),
        );
      } else {
        doOnNext(response);
      }
    } catch (e) {
      _logger.e("operation: $op failed, cause: $e");
      _tipUseCase.addOperationState(
        ClipboardOperationState(operation: op, success: false, cause: e),
      );
    }
  }
}

/// second-level use case
class ClipboardOperationUseCase extends _ClipboardOperationBase {
  final ClipboardDataRepository _repository;

  ClipboardOperationUseCase({
    required super.configUseCase,
    required super.tipUseCase,
    required ClipboardDataRepository repository,
  }) : _repository = repository;

  Future<void> addMessage(ClipboardMessage message) async {
    await _makeRequest(
      validate: () {
        if (message.content.isEmpty) {
          return false;
        }
        // check _usage && _config non-null before
        final bytes = utf8.encode(message.content).length;
        return _configUseCase.usage!.count + 1 <=
                _configUseCase.config!.maxCount &&
            (_configUseCase.usage!.bytes + bytes <=
                _configUseCase.config!.maxBytes);
      },
      op: ClipboardOperation.add,
      call: () => _repository.addMessage(message),
    );
  }

  Future<void> removeMessage(String id) async {
    await _makeRequest(
      op: ClipboardOperation.remove,
      call: () => _repository.removeMessage(id),
    );
  }

  Future<void> clear() async {
    await _makeRequest(
      validate: () => _configUseCase.usage!.count != 0,
      op: ClipboardOperation.clear,
      call: _repository.clear,
    );
  }

  Future<void> copy(String id) async {
    await _makeRequest(
      op: ClipboardOperation.copy,
      call: () => _repository.copy(id),
    );
  }
}

class ClipboardDataScannerUseCase extends _ClipboardOperationBase {
  late final StreamSubscription<bool> _initSubscription;
  final ClipboardDataRepository _repository;

  ClipboardDataScannerUseCase({
    required ClipboardDataRepository repository,
    required super.configUseCase,
    required super.tipUseCase,
  }) : _repository = repository {
    _initSubscription = _configUseCase.availableStream.listen(_onNotify);
  }

  bool _hasMore = true;

  bool get hasMore => _hasMore;

  bool scanning = false;

  int? _cursor;

  void _onNotify(bool available) {
    if (available) {
      _cursor = _configUseCase.cursor;
      _hasMore = true;
      scan();
    } else {
      _cursor = null;
      _hasMore = false;
    }
  }

  final _scanController = StreamController<ClipboardScanResult>.broadcast();

  Stream<ClipboardScanResult> get stream => _scanController.stream;

  Future<void> scan() async {
    if (!hasMore) {
      // no more data
      return;
    }
    if (_cursor == null) {
      // cursor not ready
      return;
    }
    // todo: sync here
    if (scanning) {
      return;
    }
    scanning = true;
    await _makeRequest(
      op: ClipboardOperation.scan,
      call: () => _repository.scan(timestamp: _cursor!, limit: 20),
      doOnNext: (result) {
        if (result.messages == null || result.messages!.isEmpty) {
          _hasMore = false;
          _tipUseCase.addOperationState(
            ClipboardOperationState(
              operation: ClipboardOperation.scan,
              success: false,
              cause: const ErrorMessage(code: 3, message: 'no more data'),
            ),
          );
        } else {
          _cursor = result.cursor;
          _scanController.add(result);
        }
      },
    );
    scanning = false;
  }

  void dispose() {
    _initSubscription.cancel();
  }
}

sealed class DataChangeState {}

class DataAddedState extends DataChangeState {
  final int index;

  DataAddedState({required this.index});
}

class DataRemovedState extends DataChangeState {
  final int index;
  final ClipboardMessageMeta meta;

  DataRemovedState({required this.index, required this.meta});
}

class DataAllRemovedState extends DataChangeState {}

/// third-level use case
class ClipboardDataUseCase {
  late final StreamSubscription<ClipboardNotify> _notifySubscription;
  late final StreamSubscription<ClipboardScanResult> _scanSubscription;
  final List<ClipboardMessageMeta> _metas = [];
  final List<String> _removed = [];
  Timer? _timer;
  final StreamController<DataChangeState> _controller =
      StreamController<DataChangeState>.broadcast();

  Stream<DataChangeState> get stream => _controller.stream;
  int? _expireTime;

  ClipboardDataUseCase({
    required ClipboardNotifyRepository repository,
    required ClipboardDataScannerUseCase useCase,
  }) {
    _notifySubscription = repository.notifyStream.listen(_onNotify);
    _scanSubscription = useCase.stream.listen(_onScanResult);
  }

  void _onNotify(ClipboardNotify notify) {
    switch (notify) {
      case NotifyInit():
        _clear();
        _expireTime = notify.config.expire;
        _setNextTimer();
        break;
      case NotifyAdd():
        _addItem(notify.meta);
        break;
      case NotifyRemove():
        _removeItem(notify.id);
        break;
      case NotifyClear():
        _clear();
        break;
      default:
      // ignore others
    }
  }

  void _onScanResult(ClipboardScanResult result) {
    for (int i = result.messages!.length - 1; i >= 0; i--) {
      _addItem(result.messages![i]);
    }
  }

  void _clear() {
    if(_metas.isNotEmpty) {
      _controller.add(DataAllRemovedState());
    }
    _metas.clear();
    _removed.clear();
    _timer?.cancel();
  }

  void _addItem(ClipboardMessageMeta meta) {
    if (_removed.contains(meta.id)) {
      return;
    }
    int existIndex = _metas.indexWhere((item) => item.id == meta.id);
    if (existIndex == -1) {
      int insertIndex = _metas.indexWhere(
        (item) => meta.timestamp > item.timestamp,
      );
      if (insertIndex == -1) {
        // 最早的条目
        insertIndex = _metas.length;
        _metas.add(meta);
        _setNextTimer();
      } else {
        _metas.insert(insertIndex, meta);
      }
      _controller.add(DataAddedState(index: insertIndex));
    }
  }

  void _removeItem(String id) {
    _removed.add(id);
    int index = _metas.indexWhere((item) => item.id == id);
    if (index != -1) {
      final msg = _metas.removeAt(index);
      _controller.add(DataRemovedState(index: index, meta: msg));
    }
  }

  void _checkExpired() {
    if (_metas.isEmpty || _expireTime == null || _expireTime == 0) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    for (int i = _metas.length - 1; i >= 0; i--) {
      final item = _metas[i];
      if (now - item.timestamp > _expireTime!) {
        _removed.add(item.id);
      } else {
        break;
      }
    }

    for (var id in _removed.toList()) {
      _removeItem(id);
    }
    _setNextTimer();
  }

  void _setNextTimer() {
    _timer?.cancel();
    if (_metas.isEmpty || _expireTime == null || _expireTime == 0) {
      return;
    }
    final passed =
        DateTime.now().millisecondsSinceEpoch - _metas.last.timestamp;
    final delay = Duration(milliseconds: _expireTime! - passed);
    _timer = Timer(delay, _checkExpired);
  }

  ClipboardMessageMeta? operator [](int index) => _metas[index];

  void dispose() {
    _timer?.cancel();
    _notifySubscription.cancel();
    _scanSubscription.cancel();
    _controller.close();
  }
}
