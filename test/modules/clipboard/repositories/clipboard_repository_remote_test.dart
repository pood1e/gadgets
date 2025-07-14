import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository_remote.dart';
import 'package:gadgets/shared/services/api_client_service.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'clipboard_repository_remote_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiClientService>(),
  MockSpec<http.Response>(),
  MockSpec<SseSession<ClipboardNotify>>(),
])
void main() {
  group('RemoteClipboardDataRepository', () {
    late RemoteClipboardDataRepository repository;
    late MockApiClientService service;

    setUp(() {
      service = MockApiClientService();
      repository = RemoteClipboardDataRepository(service: service);
    });

    test('failed cause by api error', () async {
      // Arrange
      MockResponse response = MockResponse();
      when(
        service.post(any, headers: anyNamed('headers'), body: anyNamed('body')),
      ).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 400);
      when(
        response.body,
      ).thenAnswer((_) => '{"code":1,"message":"exceed limit"}');

      // Act
      Object? err;
      try {
        await repository.addMessage(const ClipboardMessage(content: 'test'));
      } catch (e) {
        err = e;
      }

      expect(err, isNotNull);
      expect(err, isA<ClipboardApiException>());
      expect((err as ClipboardApiException).detail, isA<ErrorMessage>());
    });

    test('failed cause by network error', () async {
      // Arrange
      when(
        service.post(any, headers: anyNamed('headers'), body: anyNamed('body')),
      ).thenThrow(
        ApiClientException(
          uri: Uri.parse('/test'),
          code: 1,
          message: 'network error',
        ),
      );

      // Act
      Object? err;
      try {
        await repository.addMessage(const ClipboardMessage(content: 'test'));
      } catch (e) {
        err = e;
      }

      expect(err, isNotNull);
      expect(err, isA<ClipboardApiException>());
      expect((err as ClipboardApiException).detail, isA<ApiClientException>());
    });

    test('addMessage', () async {
      // Arrange
      MockResponse response = MockResponse();
      when(
        service.post(any, headers: anyNamed('headers'), body: anyNamed('body')),
      ).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);

      // Act
      await repository.addMessage(const ClipboardMessage(content: 'test'));

      // Assert
      final captured = verify(
        service.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        ),
      ).captured;
      expect(captured.length, 1);
      expect(ClipboardMessage.fromJson(captured[0]).content, 'test');
    });

    test('scan', () async {
      // Arrange
      MockResponse response = MockResponse();
      when(service.get(any)).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);
      when(response.body).thenAnswer(
        (_) =>
            '{"cursor":2,"earliest":1,"messages":[{"id":"id","preview":"xx", "length":2,"bytes":2, "timestamp":2}]}',
      );

      // Act
      final result = await repository.scan(timestamp: 1, limit: 20);

      // Assert
      expect(result.cursor, 2);
      expect(result.messages!.length, 1);
    });

    test('removeMessage', () async {
      // Arrange
      MockResponse response = MockResponse();
      when(service.delete(any)).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);

      // Act
      await repository.removeMessage("test");

      // Assert
      final captured = verify(service.delete(captureAny)).captured;
      expect(captured.length, 1);
      expect(captured[0].toString(), endsWith('test'));
    });

    test('copy', () async {
      // Arrange
      MockResponse response = MockResponse();
      when(service.get(any)).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);
      when(response.body).thenAnswer((_) => '{"content":"test"}');

      // Act
      final result = await repository.copy("test-id");

      // Assert
      expect(result.content, "test");
    });

    test('clear', () async {
      // Arrange
      MockResponse response = MockResponse();
      when(service.delete(any)).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);

      // Act & Assert
      Object? err;
      try {
        await repository.clear();
      } catch (e) {
        err = e;
      }
      expect(err, isNull);
    });
  });

  group('RemoteClipboardNotifyRepository', () {
    late RemoteClipboardNotifyRepository repository;
    late MockApiClientService service;
    late MockSseSession session;

    setUp(() {
      service = MockApiClientService();
      session = MockSseSession();
      when(
        service.createSseSession(
          request: anyNamed('request'),
          clientCustomer: anyNamed('clientCustomer'),
          transformer: anyNamed('transformer'),
        ),
      ).thenAnswer((_) => session);
      repository = RemoteClipboardNotifyRepository(service: service);
    });

    tearDown(() {
      repository.close();
    });

    test('disconnected when initial', () {
      expect(repository.status, SseConnectionStatus.disconnected);
    });

    test('receive connecting after connect', () async {
      expect(repository.status, SseConnectionStatus.disconnected);
      when(
        session.connectionState,
      ).thenAnswer((_) => Stream.fromIterable([const SseConnectingState()]));
      SseConnectionState? state;
      Completer<void> completer = Completer();
      late StreamSubscription<SseConnectionState> subscription;
      subscription = repository.stateStream.listen((data) {
        state = data;
        subscription.cancel();
        completer.complete();
      });

      // Act
      repository.connect();
      await completer.future;

      expect(state, isA<SseConnectingState>());
      expect(repository.status, SseConnectionStatus.connecting);
    });

    test('receive disconnected after connect failed', () async {
      expect(repository.status, SseConnectionStatus.disconnected);
      when(session.connectionState).thenAnswer(
        (_) => Stream.fromIterable([
          const SseConnectingState(),
          const SseDisconnectedState(),
        ]),
      );
      List<SseConnectionState> state = [];
      Completer<void> completer = Completer();
      late StreamSubscription<SseConnectionState> subscription;
      subscription = repository.stateStream.listen((data) {
        state.add(data);
        if (state.length == 2) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      repository.connect();
      await completer.future;

      // Assert
      expect(state.last, isA<SseDisconnectedState>());
      expect(repository.status, SseConnectionStatus.disconnected);
    });

    test('receive disconnected and connecting after reconnect', () async {
      expect(repository.status, SseConnectionStatus.disconnected);
      when(session.connectionState).thenAnswer(
        (_) => Stream.fromIterable([
          const SseDisconnectedState(),
          const SseConnectingState(),
        ]),
      );
      List<SseConnectionState> state = [];
      Completer<void> completer = Completer();
      late StreamSubscription<SseConnectionState> subscription;
      subscription = repository.stateStream.listen((data) {
        state.add(data);
        if (state.length == 2) {
          subscription.cancel();
          completer.complete();
        }
      });

      // Act
      repository.reconnect();
      await completer.future;

      // Assert
      expect(state.last, isA<SseConnectingState>());
      expect(repository.status, SseConnectionStatus.connecting);
    });

    test('receive disconnected after disconnect', () async {
      expect(repository.status, SseConnectionStatus.disconnected);
      when(
        session.connectionState,
      ).thenAnswer((_) => Stream.fromIterable([const SseDisconnectedState()]));
      SseConnectionState? state;
      Completer<void> completer = Completer();
      late StreamSubscription<SseConnectionState> subscription;
      subscription = repository.stateStream.listen((data) {
        state = data;
        subscription.cancel();
        completer.complete();
      });

      // Act
      repository.disconnect();
      await completer.future;

      // Assert
      expect(state, isA<SseDisconnectedState>());
      expect(repository.status, SseConnectionStatus.disconnected);
    });

    test('get notifyStream successfully', () async {
      expect(repository.status, SseConnectionStatus.disconnected);
      when(session.event).thenAnswer(
        (_) => Stream.fromIterable([const ClipboardNotify.ping(ts: 1)]),
      );
      ClipboardNotify? state;
      Completer<void> completer = Completer();
      late StreamSubscription<ClipboardNotify> subscription;
      subscription = repository.notifyStream.listen((data) {
        state = data;
        subscription.cancel();
        completer.complete();
      });

      // Act
      await completer.future;

      // Assert
      expect(state, isA<Ping>());
    });
  });
}
