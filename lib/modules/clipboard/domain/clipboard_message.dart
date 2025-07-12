import 'package:freezed_annotation/freezed_annotation.dart';

part 'clipboard_message.freezed.dart';
part 'clipboard_message.g.dart';

@freezed
abstract class ClipboardMessage with _$ClipboardMessage {
  const factory ClipboardMessage({required String content}) = _ClipboardMessage;

  factory ClipboardMessage.fromJson(Map<String, dynamic> json) =>
      _$ClipboardMessageFromJson(json);
}

@freezed
abstract class ErrorMessage with _$ErrorMessage {
  const factory ErrorMessage({required int code, required String message}) =
      _ErrorMessage;

  factory ErrorMessage.fromJson(Map<String, dynamic> json) =>
      _$ErrorMessageFromJson(json);
}

@freezed
abstract class ClipboardConfig with _$ClipboardConfig {
  const factory ClipboardConfig({
    required int maxBytes,
    required int maxCount,
    required int expire,
  }) = _ClipboardConfig;

  factory ClipboardConfig.fromJson(Map<String, dynamic> json) =>
      _$ClipboardConfigFromJson(json);
}

@freezed
abstract class ClipboardMessageMeta with _$ClipboardMessageMeta {
  const factory ClipboardMessageMeta({
    required String id,
    required String preview,
    required int length,
    required int bytes,
    required int timestamp,
  }) = _ClipboardMessageMeta;

  factory ClipboardMessageMeta.fromJson(Map<String, dynamic> json) =>
      _$ClipboardMessageMetaFromJson(json);
}

@freezed
abstract class ClipboardUsage with _$ClipboardUsage {
  const factory ClipboardUsage({
    required int timestamp,
    required int count,
    required int bytes,
  }) = _ClipboardUsage;

  factory ClipboardUsage.fromJson(Map<String, dynamic> json) =>
      _$ClipboardUsageFromJson(json);
}

@freezed
abstract class ClipboardScanResult with _$ClipboardScanResult {
  const factory ClipboardScanResult({
    List<ClipboardMessageMeta>? messages,
    int? cursor,
  }) = _ClipboardScanResult;

  factory ClipboardScanResult.fromJson(Map<String, dynamic> json) =>
      _$ClipboardScanResultFromJson(json);
}

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.screamingSnake)
sealed class ClipboardNotify with _$ClipboardNotify {
  const ClipboardNotify._();

  @FreezedUnionValue('PING')
  const factory ClipboardNotify.ping({required int ts}) = Ping;

  @FreezedUnionValue('NOTIFY_ADD')
  const factory ClipboardNotify.notifyAdd({
    required ClipboardMessageMeta meta,
    required ClipboardUsage usage,
  }) = NotifyAdd;

  @FreezedUnionValue('NOTIFY_INIT')
  const factory ClipboardNotify.notifyInit({
    required int cursor,
    required ClipboardUsage usage,
    required ClipboardConfig config,
  }) = NotifyInit;

  @FreezedUnionValue('NOTIFY_REMOVE')
  const factory ClipboardNotify.notifyRemove({
    required String id,
    required ClipboardUsage usage,
  }) = NotifyRemove;

  @FreezedUnionValue('NOTIFY_CLEAR')
  const factory ClipboardNotify.notifyClear({required ClipboardUsage usage}) =
      NotifyClear;

  factory ClipboardNotify.fromJson(Map<String, dynamic> json) =>
      _$ClipboardNotifyFromJson(json);

  static ClipboardUsage? getUsage(ClipboardNotify notify) => switch (notify) {
    NotifyAdd(:final usage) => usage,
    NotifyInit(:final usage) => usage,
    NotifyRemove(:final usage) => usage,
    NotifyClear(:final usage) => usage,
    Ping() => null,
  };
}
