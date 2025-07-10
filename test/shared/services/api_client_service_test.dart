import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/services/api_client_service.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'api_client_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<http.Response>()])
void main() {
  group('ApiClientService', () {
    late MockClient client;
    MockResponse response = MockResponse();
    late ApiClientService service;

    setUp(() {
      client = MockClient();
      service = ApiClientService(baseUrl: '/test', client: client);
    });

    tearDown(() {
      service.dispose();
    });

    test('request error cause by network', () async {
      when(client.get(any)).thenThrow(http.ClientException('network error'));

      Object? err;
      try {
        await service.get(Uri.parse('/test'));
      } catch (e) {
        err = e;
      }

      expect(err, isA<ApiClientException>());
      expect((err as ApiClientException).message, contains('network error'));
    });

    test('get', () async {
      when(client.get(any)).thenAnswer((_) async => response);

      final result = await service.get(Uri.parse('/test'));
      final captured = verify(client.get(captureAny)).captured;

      expect(captured.length, 1);
      expect(captured[0], Uri.parse('/test/test'));
      expect(result, response);
    });

    test('post', () async {
      when(
        client.post(any, body: anyNamed('body')),
      ).thenAnswer((_) async => response);

      final result = await service.post(
        Uri.parse('/test'),
        body: _TestObject(content: 'test'),
      );
      final captured = verify(
        client.post(any, body: captureAnyNamed('body')),
      ).captured;

      expect(captured.length, 1);
      final obj = _TestObject.fromJson(jsonDecode(captured[0]));
      expect(obj.content, 'test');
      expect(result, response);
    });

    test('put', () async {
      when(
        client.put(any, body: anyNamed('body')),
      ).thenAnswer((_) async => response);

      final result = await service.put(
        Uri.parse('/test'),
        body: _TestObject(content: 'test'),
      );
      final captured = verify(
        client.put(any, body: captureAnyNamed('body')),
      ).captured;

      expect(captured.length, 1);
      final obj = _TestObject.fromJson(jsonDecode(captured[0]));
      expect(obj.content, 'test');
      expect(result, response);
    });

    test('delete', () async {
      when(client.delete(any)).thenAnswer((_) async => response);

      final result = await service.delete(Uri.parse('/test'));
      final captured = verify(client.delete(captureAny)).captured;

      expect(captured.length, 1);
      expect(captured[0], Uri.parse('/test/test'));
      expect(result, response);
    });

    test('create sse session', () async {
      final session = service.createSseSession(
        request: SseRequest(
          uri: Uri.parse('/test'),
          method: SseRequestMethod.get,
        ),
        transformer: _TestObject.fromJson,
      );
      expect(session, isNotNull);
    });
  });
}

class _TestObject {
  final String content;

  _TestObject({required this.content});

  factory _TestObject.fromJson(dynamic json) =>
      _TestObject(content: json['content']);

  Map<String, dynamic> toJson() => {'content': content};
}
