import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_message.freezed.dart';
part 'common_message.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class PageResult<T> with _$PageResult<T> {
  const factory PageResult({
    required int total,
    required int size,
    required int page,
    required List<T> items,
  }) = _PageResult;

  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$PageResultFromJson(json, fromJsonT);
}
