import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sse_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<HttpClient>(),
  MockSpec<HttpClientRequest>(),
  MockSpec<HttpClientResponse>(),
  MockSpec<HttpHeaders>(),
])
void main() {
  group('HttpSseSession', () {
    late HttpSseSession<String> session;
    HttpClient client = MockHttpClient();

    setUp(() {
      session = _TestHttpSseSession(
        request: SseRequest(
          uri: Uri.parse('/test'),
          method: SseRequestMethod.post,
          headers: {'Auth': 'test'},
          body: 'test',
        ),
        builder: () => client,
      );
    });

    tearDown(() {
      session.close();
    });

    test('connect success', () async {
      // Arrange
      HttpClientRequest request = MockHttpClientRequest();
      HttpHeaders headers = MockHttpHeaders();
      MockHttpClientResponse response = MockHttpClientResponse();
      when(client.postUrl(Uri.parse('/test'))).thenAnswer((_) async => request);
      when(request.headers).thenAnswer((_) => headers);
      when(request.close()).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);
      when(
        response.transform(any),
      ).thenAnswer((_) => Stream<String>.fromIterable(['data: test']));

      List<SseConnectionState> list = [];
      final completer = Completer<void>();
      late StreamSubscription<SseConnectionState> subscription;

      subscription = session.connectionState.listen((state) {
        list.add(state);
        if (list.length == 2) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      session.connect();
      await completer.future;

      // Assert
      expect(list.length, 2);
      expect(list.first, isA<SseConnectingState>());
      expect(list.last, isA<SseConnectedState>());
    });

    test('connect failed cause by network', () async {
      // Arrange
      when(
        client.postUrl(Uri.parse('/test')),
      ).thenThrow((_) => SseSessionException('network error'));

      List<SseConnectionState> list = [];
      final completer = Completer<void>();
      late StreamSubscription<SseConnectionState> subscription;

      subscription = session.connectionState.listen((state) {
        list.add(state);
        if (list.length == 2) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      session.connect();
      await completer.future;

      // Assert
      expect(list.length, 2);
      expect(list.first, isA<SseConnectingState>());
      final element = list.last;
      expect(element, isA<SseDisconnectedState>());
      expect(
        (element as SseDisconnectedState).cause,
        isA<SseSessionException>(),
      );
    });

    test('connect failed cause by api error', () async {
      // Arrange
      HttpClientRequest request = MockHttpClientRequest();
      HttpHeaders headers = MockHttpHeaders();
      MockHttpClientResponse response = MockHttpClientResponse();
      when(client.postUrl(Uri.parse('/test'))).thenAnswer((_) async => request);
      when(request.headers).thenAnswer((_) => headers);
      when(request.close()).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 400);

      List<SseConnectionState> list = [];
      final completer = Completer<void>();
      late StreamSubscription<SseConnectionState> subscription;

      subscription = session.connectionState.listen((state) {
        list.add(state);
        if (list.length == 2) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      session.connect();
      await completer.future;

      // Assert
      expect(list.length, 2);
      expect(list.first, isA<SseConnectingState>());
      final element = list.last;
      expect(element, isA<SseDisconnectedState>());
      expect(
        (element as SseDisconnectedState).cause,
        isA<SseSessionException>(),
      );
    });
  });

  group('HttpRetrySseSession', () {
    late HttpRetrySseSession<String> session;
    HttpClient client = MockHttpClient();

    setUp(() {
      session = _TestHttpRetrySession(
        request: SseRequest(
          uri: Uri.parse('/test'),
          method: SseRequestMethod.get,
        ),
        builder: () => client,
        retrier: SseRetrier(retries: 2, backoff: 1, delay: Duration.zero),
      );
    });

    tearDown(() {
      session.close();
    });

    test('connect success without retry', () async {
      // Arrange
      HttpClientRequest request = MockHttpClientRequest();
      HttpHeaders headers = MockHttpHeaders();
      MockHttpClientResponse response = MockHttpClientResponse();
      when(client.getUrl(Uri.parse('/test'))).thenAnswer((_) async => request);
      when(request.headers).thenAnswer((_) => headers);
      when(request.close()).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);
      when(
        response.transform(any),
      ).thenAnswer((_) => Stream<String>.fromIterable(['data: test']));

      List<SseConnectionState> list = [];
      final completer = Completer<void>();
      late StreamSubscription<SseConnectionState> subscription;

      subscription = session.connectionState.listen((state) {
        list.add(state);
        if (list.length == 2) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      session.connect();
      await completer.future;

      // Assert
      expect(list.length, 2);
      expect(list.first, isA<SseConnectingState>());
      expect(list.last, isA<SseConnectedState>());
    });

    test('retry when throw SseSessionException', () async {
      // Arrange
      when(
        client.getUrl(Uri.parse('/test')),
      ).thenThrow((_) => SseSessionException('network error'));

      List<SseConnectionState> list = [];
      final expectedTypes = [
        isA<SseConnectingState>(),
        isA<SseDisconnectedState>(),
        isA<SseRetryState>(),
        isA<SseDisconnectedState>(),
        isA<SseRetryState>(),
        isA<SseDisconnectedState>(),
      ];
      final completer = Completer<void>();
      late StreamSubscription<SseConnectionState> subscription;

      subscription = session.connectionState.listen((state) {
        list.add(state);
        if (list.length == 6) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      session.connect();
      await completer.future;

      // Assert
      expect(list.length, 6);
      for (int i = 0; i < list.length; i++) {
        expect(list[i], expectedTypes[i]);
      }
    });
  });

  group('JsonSseSession', () {
    late JsonSseSession<_TestObject> session;
    HttpClient client = MockHttpClient();

    setUp(() {
      session = JsonSseSession<_TestObject>(
        request: SseRequest(
          uri: Uri.parse('/test'),
          method: SseRequestMethod.get,
        ),
        builder: () => client,
        retrier: SseRetrier(retries: 0, backoff: 1, delay: Duration.zero),
        transformer: _TestObject.fromJson,
      );
    });

    tearDown(() {
      session.close();
    });

    test('produce object success', () async {
      // Arrange
      HttpClientRequest request = MockHttpClientRequest();
      HttpHeaders headers = MockHttpHeaders();
      MockHttpClientResponse response = MockHttpClientResponse();
      when(client.getUrl(Uri.parse('/test'))).thenAnswer((_) async => request);
      when(request.headers).thenAnswer((_) => headers);
      when(request.close()).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);
      when(response.transform(any)).thenAnswer(
        (_) => Stream<String>.fromIterable(['data:{"content":"test"}']),
      );

      _TestObject? object;
      final completer = Completer<void>();
      late StreamSubscription<_TestObject> subscription;
      subscription = session.event.listen((state) {
        object = state;
        subscription.cancel();
        completer.complete();
      });

      // Act
      session.connect();
      await completer.future;

      // Assert
      expect(object, isNotNull);
      expect(object!.content, 'test');
    });

    test('produce object failed when message parse error', () async {
      // Arrange
      HttpClientRequest request = MockHttpClientRequest();
      HttpHeaders headers = MockHttpHeaders();
      MockHttpClientResponse response = MockHttpClientResponse();
      when(client.getUrl(Uri.parse('/test'))).thenAnswer((_) async => request);
      when(request.headers).thenAnswer((_) => headers);
      when(request.close()).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);
      when(response.transform(any)).thenAnswer(
        (_) => Stream<String>.fromIterable(['data:{"content":"test}']),
      );

      late StreamSubscription<SseConnectionState> subscription;
      List<SseConnectionState> list = [];
      final expectedTypes = [
        isA<SseConnectingState>(),
        isA<SseConnectedState>(),
        isA<SseDisconnectedState>(),
      ];
      final completer = Completer<void>();
      subscription = session.connectionState.listen((state) {
        list.add(state);
        if (list.length == 3) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      session.connect();
      await completer.future;

      // Assert
      expect(list.length, 3);
      for (int i = 0; i < list.length; i++) {
        expect(list[i], expectedTypes[i]);
      }
    });
  });
}

class _TestHttpSseSession extends HttpSseSession<String> {
  _TestHttpSseSession({required super.request, required super.builder});

  @override
  StreamSubscription<dynamic> subscribe(HttpClientResponse response) => response
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen(eventController.add);
}

class _TestHttpRetrySession extends HttpRetrySseSession<String> {
  _TestHttpRetrySession({
    required super.request,
    required super.builder,
    super.retrier,
  });

  @override
  StreamSubscription<dynamic> subscribe(HttpClientResponse response) => response
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .listen(eventController.add);
}

class _TestObject {
  final String content;

  _TestObject({required this.content});

  factory _TestObject.fromJson(dynamic json) =>
      _TestObject(content: json['content']);
}
