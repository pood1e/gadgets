import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:gadgets/shared/utils/wrapped_logger.dart';

/// 连接状态
enum SseConnectionStatus { connecting, disconnected, connected }

/// 连接事件 - 用于向上一层汇报事件
sealed class SseConnectionState {
  final SseConnectionStatus state;

  const SseConnectionState({required this.state});
}

class SseConnectingState extends SseConnectionState {
  const SseConnectingState() : super(state: SseConnectionStatus.connecting);
}

class SseConnectedState extends SseConnectionState {
  const SseConnectedState() : super(state: SseConnectionStatus.connected);
}

class SseDisconnectedState extends SseConnectionState {
  final dynamic cause;

  const SseDisconnectedState({this.cause})
    : super(state: SseConnectionStatus.disconnected);
}

class SseRetryState extends SseConnectingState {
  final int time;
  final int maxRetries;

  const SseRetryState({required this.time, required this.maxRetries});
}

/// sse 对外提供的接口
abstract class SseSession<T> {
  /// 事件流
  Stream<T> get event;

  /// 连接事件流
  Stream<SseConnectionState> get connectionState;

  /// 发起连接，这是一个异步操作
  Future<void> connect();

  /// 主动断开连接
  void disconnect();

  /// 主动关闭会话
  void close();
}

/// Sse 会话异常
class SseSessionException implements Exception {
  final String message;

  final Uri? uri;

  SseSessionException(this.message, [this.uri]);

  @override
  String toString() {
    if (uri != null) {
      return 'SseSessionException: $message, uri=$uri';
    } else {
      return 'SseSessionException: $message';
    }
  }
}

enum SseRequestMethod { get, post }

class SseRequest {
  final Uri uri;
  final SseRequestMethod method;
  final Map<String, String>? headers;
  final String? body;

  SseRequest({
    required this.uri,
    required this.method,
    this.headers,
    this.body,
  });
}

/// 提供基础的sse连接实现
abstract class HttpSseSession<T> extends SseSession<T> {
  final _logger = WrappedLogger();
  final SseRequest _request;
  final HttpClient _client;

  final StreamController<T> eventController = StreamController<T>.broadcast();
  StreamSubscription<dynamic>? _subscription;

  final StreamController<SseConnectionState> connectionController =
      StreamController<SseConnectionState>.broadcast();

  HttpSseSession({
    required SseRequest request,
    required HttpClient Function() builder,
  }) : _request = request,
       _client = builder();

  @override
  Stream<T> get event => eventController.stream;

  @override
  Stream<SseConnectionState> get connectionState => connectionController.stream;

  void _setSseHeader(HttpClientRequest request) {
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
    request.headers.set(HttpHeaders.connectionHeader, 'keep-alive');
    // 关闭gzip
    request.headers.removeAll(HttpHeaders.acceptEncodingHeader);
  }

  Future<HttpClientRequest> _createRequest() async {
    final future = switch (_request.method) {
      SseRequestMethod.get => _client.getUrl(_request.uri),
      SseRequestMethod.post => _client.postUrl(_request.uri),
    };
    final request = await future;
    _setSseHeader(request);
    if (_request.headers != null && _request.headers!.isNotEmpty) {
      _request.headers!.forEach(
        (key, value) => request.headers.set(key, value),
      );
    }
    if (_request.body != null) {
      request.write(_request.body);
    }
    return request;
  }

  void _sendConnecting() {
    connectionController.add(const SseConnectingState());
  }

  StreamSubscription<dynamic> subscribe(HttpClientResponse response);

  @override
  Future<void> connect([bool sendConnecting = true]) async {
    if (sendConnecting) {
      _sendConnecting();
    }
    _logger.i("do connect, uri=${_request.uri}");
    bool connectSuccess = false;
    try {
      final request = await _createRequest();
      final response = await request.close();
      if (response.statusCode != 200) {
        _handleError(
          SseSessionException(
            "status code error: ${response.statusCode}",
            _request.uri,
          ),
        );
      } else {
        connectSuccess = true;
        connectionController.add(const SseConnectedState());
        _subscription = subscribe(response);
        _subscription!.onDone(() {
          _handleError(SseSessionException('connection close', _request.uri));
        });
        _subscription!.onError((err) {
          _handleError(SseSessionException(err.toString(), _request.uri));
        });
      }
    } catch (e) {
      _handleError(SseSessionException(e.toString()));
    }
    if (!connectSuccess) {
      return;
    }
  }

  @override
  void disconnect([dynamic cause]) {
    _subscription?.cancel();
    _subscription = null;
    connectionController.add(SseDisconnectedState(cause: cause));
    _logger.w("disconnected, uri=${_request.uri}, cause=$cause");
  }

  void _handleError(Exception err) {
    disconnect(err);
  }

  @override
  void close() {
    _subscription?.cancel();
    _client.close(force: true);
    eventController.close();
    connectionController.close();
  }
}

/// sse 重试器
class SseRetrier {
  /// 尝试次数
  final int _retries;

  /// 退避指数
  final double _backoff;

  /// 重试延迟
  final Duration _delay;

  SseRetrier({
    required int retries,
    required double backoff,
    required Duration delay,
  }) : _delay = delay,
       _backoff = backoff,
       _retries = retries;
}

abstract class HttpRetrySseSession<T> extends HttpSseSession<T> {
  final SseRetrier _retrier;

  HttpRetrySseSession({
    required super.request,
    required super.builder,
    SseRetrier? retrier,
  }) : _retrier =
           retrier ??
           SseRetrier(
             retries: 3,
             backoff: 1,
             delay: const Duration(seconds: 1),
           );

  int _counter = 0;
  bool _closed = false;

  void _makeRetry() {
    if (_counter >= _retrier._retries || _closed) {
      return;
    }
    final shouldDelay =
        pow(_retrier._backoff, _counter) * _retrier._delay.inMilliseconds;
    Future.delayed(Duration(milliseconds: shouldDelay.toInt()), () {
      if (_counter < _retrier._retries && !_closed) {
        _counter++;
        connectionController.add(
          SseRetryState(time: _counter, maxRetries: _retrier._retries),
        );
        connect(false);
      }
    });
  }

  void _resetCounter() {
    _counter = 0;
  }

  @override
  Future<void> connect([bool sendConnecting = true]) async {
    if (sendConnecting) {
      _resetCounter();
    }
    await super.connect(sendConnecting);
    if (_subscription != null) {
      _resetCounter();
    }
  }

  @override
  void _handleError(Exception err) {
    super._handleError(err);
    if (err is SseSessionException) {
      _makeRetry();
    }
  }

  @override
  void close() {
    _closed = true;
    super.close();
  }
}

class JsonSseSession<T> extends HttpRetrySseSession<T> {
  final T Function(dynamic) _transformer;

  JsonSseSession({
    required super.request,
    required super.builder,
    super.retrier,
    required T Function(dynamic) transformer,
  }) : _transformer = transformer;

  @override
  StreamSubscription<dynamic> subscribe(HttpClientResponse response) => response
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen((dataLine) {
        final trim = dataLine.trim();
        if (trim.isEmpty) {
          return;
        }
        if (trim.startsWith('data:') && trim.length > 5) {
          try {
            eventController.add(_transformer(jsonDecode(trim.substring(5))));
          } catch (err) {
            _handleError(SseSessionException(e.toString()));
          }
        }
      });
}
