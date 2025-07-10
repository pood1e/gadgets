import 'dart:async';

import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/shared/services/sse_service.dart';

class ClipboardApiException implements Exception {
  final String message;
  final int? status;
  final Uri? uri;
  final dynamic detail;

  ClipboardApiException({
    required this.message,
    this.status,
    this.uri,
    this.detail,
  });

  @override
  String toString() {
    final uriPart = uri == null ? '' : ',uri=$uri';
    final statusPart = status == null ? '' : ',status=$status';
    return "ClipboardApiException: $message$uriPart$statusPart";
  }
}

/// 无状态接口
abstract class ClipboardDataRepository {
  Future<void> addMessage(ClipboardMessage message);

  Future<void> removeMessage(String id);

  Future<ClipboardMessage> copy(String id);

  Future<void> clear();

  Future<ClipboardScanResult> scan({
    required int timestamp,
    required int limit,
  });
}

/// 具备单一sse连接
abstract class ClipboardNotifyRepository {
  /// 连接
  void connect();

  /// 重连，应当清除旧连接
  void reconnect();

  /// 主动断开
  void disconnect();

  /// 关闭
  void close();

  /// 获取连接状态
  SseConnectionStatus get status;

  /// 状态流
  Stream<SseConnectionState> get stateStream;

  /// 数据流
  Stream<ClipboardNotify> get notifyStream;
}
