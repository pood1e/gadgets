import 'dart:async';

import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_usecase.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository.dart';
import 'package:gadgets/shared/services/sse_service.dart';

// no state
class ClipboardConnectionViewModel {
  final ClipboardNotifyRepository _repository;

  ClipboardConnectionViewModel({required ClipboardNotifyRepository repository})
    : _repository = repository;

  Stream<SseConnectionState> get stream => _repository.stateStream;

  void connect() {
    _repository.connect();
  }

  void refresh() {
    _repository.reconnect();
  }

  void resume() {
    if (_repository.status == SseConnectionStatus.disconnected) {
      _repository.reconnect();
    }
  }

  void pause() {
    _repository.disconnect();
  }
}

class ClipboardDataOperationViewModel {
  final ClipboardOperationUseCase _useCase;
  final ClipboardTipUseCase _tipUseCase;

  ClipboardDataOperationViewModel({
    required ClipboardOperationUseCase useCase,
    required ClipboardTipUseCase tipUseCase,
  }) : _useCase = useCase,
       _tipUseCase = tipUseCase;

  Stream<ClipboardOperationState> get stream => _tipUseCase.stream;

  Future<void> addData(String text) async {
    await _useCase.addMessage(ClipboardMessage(content: text));
  }

  Future<void> copy(String id) async {
    await _useCase.copy(id);
  }

  Future<void> remove(String id) async {
    await _useCase.removeMessage(id);
  }

  Future<void> clear() async {
    await _useCase.clear();
  }
}

class ClipboardDataViewModel {
  final ClipboardDataUseCase _useCase;
  final ClipboardDataScannerUseCase _scannerUseCase;

  ClipboardMessageMeta? operator [](int index) => _useCase[index];

  Stream<DataChangeState> get stream => _useCase.stream;

  bool get hasMore => _scannerUseCase.hasMore;

  Future<void> scan() async {
    _scannerUseCase.scan();
  }

  ClipboardDataViewModel({
    required ClipboardDataUseCase useCase,
    required ClipboardDataScannerUseCase scannerUseCase,
  }) : _useCase = useCase,
       _scannerUseCase = scannerUseCase;
}
