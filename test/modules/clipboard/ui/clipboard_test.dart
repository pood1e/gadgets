import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_localizations.dart';
import 'package:gadgets/modules/clipboard/main.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/services/api_client_service.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../../test_utils/test_constants.dart';
import '../repositories/clipboard_repository_remote_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiClientService>(),
  MockSpec<SseSession<ClipboardNotify>>(),
  MockSpec<http.Response>(),
])
void main() {
  group("Clipboard", () {
    late MockApiClientService apiClientService;
    late MockSseSession session;
    late StreamController<SseConnectionState> stateController;
    late StreamController<ClipboardNotify> controller;

    createTestWidget() => Provider(
      create: (_) => apiClientService as ApiClientService,
      child: createShellWrappedApp(
        RouteDefine(
          id: 'clipboard',
          icon: SvgPicture.asset('assets/svg/clipboard.svg'),
          localizationOf: ClipboardLocalizations.of,
          localizationDelegate: ClipboardLocalizations.delegate,
          route: GoRoute(
            path: '/clipboard',
            builder: (_, _) => const ClipboardApp(),
          ),
        ),
      ),
    );

    setUp(() {
      apiClientService = MockApiClientService();
      session = MockSseSession();
      stateController = StreamController.broadcast();
      controller = StreamController.broadcast();
      when(
        apiClientService.createSseSession(
          request: anyNamed('request'),
          transformer: anyNamed('transformer'),
          clientCustomer: anyNamed('clientCustomer'),
        ),
      ).thenAnswer((_) => session);
      when(session.connectionState).thenAnswer((_) => stateController.stream);
      when(session.event).thenAnswer((_) => controller.stream);
    });

    tearDown(() {
      stateController.close();
      controller.close();
    });

    setEmptyScanResult() {
      MockResponse response = MockResponse();
      when(
        apiClientService.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => response);
      when(response.statusCode).thenAnswer((_) => 200);
      when(response.body).thenAnswer((_) => '{"messages":[],"cursor":1}');
    }

    triggerAvailable() {
      stateController.add(const SseConnectedState());
      controller.add(
        const NotifyInit(
          cursor: 1,
          usage: ClipboardUsage(timestamp: 1, count: 5, bytes: 50),
          config: ClipboardConfig(maxBytes: 1024, maxCount: 50, expire: 0),
        ),
      );
    }

    testWidgets('show disconnected when enter', (tester) async {
      // initial : disconnected
      await tester.pumpWidget(createTestWidget());
      // on next frame
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.link_off), findsOneWidget);

      // auto connecting
      stateController.add(const SseConnectingState());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.settings_ethernet), findsOneWidget);

      // connected
      setEmptyScanResult();
      stateController.add(const SseConnectedState());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byIcon(Icons.link), findsOneWidget);
    });

    testWidgets('trigger reconnect by tap refresh btn', (tester) async {
      // initial : disconnected
      await tester.pumpWidget(createTestWidget());
      // on next frame
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump(const Duration(milliseconds: 100));

      verify(session.disconnect()).called(1);
      verify(session.connect()).called(2);
    });

    testWidgets('show status bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      setEmptyScanResult();
      triggerAvailable();
      await tester.pumpAndSettle();

      expect(find.textContaining("5/50"), findsOneWidget);
      expect(find.textContaining("50 B/1 KB"), findsOneWidget);
    });

    testWidgets('show data items', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      setEmptyScanResult();
      triggerAvailable();
      controller.add(
        const NotifyAdd(
          meta: ClipboardMessageMeta(
            id: "1x",
            preview: "abc",
            length: 3,
            bytes: 3,
            timestamp: 1,
          ),
          usage: ClipboardUsage(timestamp: 1, count: 1, bytes: 3),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("abc"), findsOneWidget);
    });

    testWidgets('trigger add message when tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      setEmptyScanResult();
      triggerAvailable();
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);

      await tester.tap(textField);
      await tester.pump();

      await tester.enterText(textField, 'test');
      await tester.pump();

      MockResponse response = MockResponse();
      when(response.statusCode).thenAnswer((_) => 200);
      when(
        apiClientService.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => response);

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      final captured = verify(
        apiClientService.post(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        ),
      ).captured;
      expect(captured.length, 1);
      expect(captured[0]['content'], 'test');
    });

    testWidgets('trigger clear message when tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      setEmptyScanResult();
      triggerAvailable();
      await tester.pumpAndSettle();

      MockResponse response = MockResponse();
      when(response.statusCode).thenAnswer((_) => 200);
      when(
        apiClientService.delete(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => response);

      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      verify(
        apiClientService.delete(
          any,
          headers: anyNamed('headers'),
          body: captureAnyNamed('body'),
        ),
      ).called(1);
    });

    testWidgets('trigger copy message when tap', (tester) async {
      // 确保 Flutter 测试环境已初始化
      TestWidgetsFlutterBinding.ensureInitialized();
      MockClipboard mockClipboard = MockClipboard();
      // 设置 SystemChannels.platform 的 mock handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            SystemChannels.platform,
            mockClipboard.handleMethodCall,
          );
      mockClipboard.clipboardData = <String, dynamic>{'text': null};
      await tester.pumpWidget(createTestWidget());
      setEmptyScanResult();
      triggerAvailable();
      controller.add(
        const NotifyAdd(
          meta: ClipboardMessageMeta(
            id: "1x",
            preview: "abc",
            length: 3,
            bytes: 3,
            timestamp: 1,
          ),
          usage: ClipboardUsage(timestamp: 1, count: 1, bytes: 3),
        ),
      );
      await tester.pumpAndSettle();

      MockResponse response = MockResponse();
      when(response.statusCode).thenAnswer((_) => 200);
      when(response.body).thenAnswer((_) => '{"content":"abc"}');
      when(
        apiClientService.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => response);

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      ClipboardData? data = await Clipboard.getData('text/plain');
      expect(data, isNotNull);
      expect(data!.text, 'abc');
    });

    testWidgets('trigger delete message when tap', (tester) async {
      await tester.pumpWidget(createTestWidget());
      setEmptyScanResult();
      triggerAvailable();
      controller.add(
        const NotifyAdd(
          meta: ClipboardMessageMeta(
            id: "1x",
            preview: "abc",
            length: 3,
            bytes: 3,
            timestamp: 1,
          ),
          usage: ClipboardUsage(timestamp: 1, count: 1, bytes: 3),
        ),
      );
      await tester.pumpAndSettle();

      MockResponse response = MockResponse();
      when(response.statusCode).thenAnswer((_) => 200);
      when(response.body).thenAnswer((_) => '{"content":"abc"}');
      when(
        apiClientService.delete(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => response);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      final captured = verify(apiClientService.delete(captureAny)).captured;
      expect(captured.length, 1);
      expect(captured[0].toString(), endsWith("1x"));
    });
  });
}

class MockClipboard {
  dynamic clipboardData = <String, dynamic>{'text': null};

  Future<Object?> handleMethodCall(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Clipboard.getData':
        return clipboardData;
      case 'Clipboard.setData':
        clipboardData = methodCall.arguments;
        return null;
      case 'Clipboard.hasStrings':
        final Map<String, dynamic>? clipboardDataMap =
            clipboardData as Map<String, dynamic>?;
        final String? text = clipboardDataMap?['text'] as String?;
        return <String, bool>{'value': text != null && text.isNotEmpty};
    }
    return null;
  }
}
