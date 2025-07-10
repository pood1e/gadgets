import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_usecase.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository.dart';
import 'package:gadgets/shared/services/sse_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'clipboard_usecase_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ClipboardNotifyRepository>(),
  MockSpec<ClipboardDataRepository>(),
  MockSpec<ClipboardConfigUseCase>(),
  MockSpec<ClipboardTipUseCase>(),
  MockSpec<ClipboardDataScannerUseCase>(),
])
void main() {
  group('ClipboardAutoDisconnect', () {
    late MockClipboardNotifyRepository repository;
    late ClipboardAutoDisconnect useCase;

    setUp(() {
      repository = MockClipboardNotifyRepository();
    });

    tearDown(() {
      useCase.dispose();
    });

    test('auto disconnect after idle 2 seconds', () async {
      // Arrange
      when(repository.notifyStream).thenAnswer((_) => const Stream.empty());
      when(
        repository.stateStream,
      ).thenAnswer((_) => Stream.fromIterable([const SseConnectedState()]));

      // Act
      useCase = ClipboardAutoDisconnect(repository, 0);
      // 等待触发timer
      await Future.delayed(const Duration(seconds: 1));

      // Assert
      final count = verify(repository.disconnect()).callCount;
      expect(count, 1);
    });
  });

  group('ClipboardConfigUseCase', () {
    late MockClipboardNotifyRepository repository;
    late ClipboardConfigUseCase useCase;
    late StreamController<ClipboardNotify> controller;
    late StreamController<SseConnectionState> stateController;

    setUp(() {
      repository = MockClipboardNotifyRepository();
      controller = StreamController.broadcast();
      stateController = StreamController.broadcast();
      when(repository.notifyStream).thenAnswer((_) => controller.stream);
      when(repository.stateStream).thenAnswer((_) => stateController.stream);
      useCase = ClipboardConfigUseCase(repository);
    });

    tearDown(() {
      useCase.dispose();
      controller.close();
    });

    test('update usage', () async {
      // Arrange
      Completer<void> initCompleter = Completer();
      late StreamSubscription<ClipboardConfigUpdate> subscription;
      subscription = useCase.stream.listen((config) {
        subscription.cancel();
        initCompleter.complete();
      });

      // Act
      controller.add(
        const NotifyInit(
          cursor: 1,
          usage: ClipboardUsage(timestamp: 1, count: 2, bytes: 3),
          config: ClipboardConfig(maxBytes: 2048, maxCount: 10, expire: 60),
        ),
      );
      // 等待触发
      await initCompleter.future;

      // Assert
      expect(useCase.usage, isNotNull);
      expect(useCase.usage!.count, 2);
      expect(useCase.config, isNotNull);

      // Arrange
      Completer<void> notifyCompleter = Completer();
      late StreamSubscription<ClipboardConfigUpdate> subscription2;
      subscription2 = useCase.stream.listen((config) {
        subscription2.cancel();
        notifyCompleter.complete();
      });

      // Act
      controller.add(
        const NotifyRemove(
          id: 'test',
          usage: ClipboardUsage(timestamp: 2, count: 1, bytes: 1),
        ),
      );
      await notifyCompleter.future;
      // Assert
      expect(useCase.usage, isNotNull);
      expect(useCase.usage!.count, 1);
    });

    test('update availability', () async {
      // Arrange
      Completer<void> initCompleter = Completer();
      late StreamSubscription<bool> subscription;
      subscription = useCase.availableStream.listen((config) {
        subscription.cancel();
        initCompleter.complete();
      });

      // Act
      controller.add(
        const NotifyInit(
          cursor: 1,
          usage: ClipboardUsage(timestamp: 1, count: 2, bytes: 3),
          config: ClipboardConfig(maxBytes: 2048, maxCount: 10, expire: 60),
        ),
      );
      stateController.add(const SseConnectedState());
      // 等待触发
      await initCompleter.future;

      // Assert
      expect(useCase.available, true);
    });
  });

  group('ClipboardTipUseCase', () {
    test('addOperationState success', () async {
      ClipboardTipUseCase useCase = ClipboardTipUseCase();
      Completer<ClipboardOperationState> completer = Completer();
      late StreamSubscription<ClipboardOperationState> subscription;
      subscription = useCase.stream.listen((data) {
        subscription.cancel();
        completer.complete(data);
      });
      useCase.addOperationState(
        ClipboardOperationState(
          operation: ClipboardOperation.scan,
          success: false,
          cause: const ErrorMessage(code: 3, message: 'no more data'),
        ),
      );
      final state = await completer.future;
      expect(state.success, false);
      expect(state.cause, isA<ErrorMessage>());
    });
  });

  group('ClipboardOperationUseCase', () {
    late MockClipboardConfigUseCase configUseCase;
    late MockClipboardDataRepository dataRepository;
    late ClipboardTipUseCase tipUseCase;
    late ClipboardOperationUseCase useCase;

    setUp(() {
      configUseCase = MockClipboardConfigUseCase();
      dataRepository = MockClipboardDataRepository();
      tipUseCase = ClipboardTipUseCase();
      useCase = ClipboardOperationUseCase(
        configUseCase: configUseCase,
        repository: dataRepository,
        tipUseCase: tipUseCase,
      );
    });

    tearDown(() {
      tipUseCase.dispose();
    });

    test('operate failed cause by not operable', () async {
      when(configUseCase.available).thenAnswer((_) => false);
      Completer<ClipboardOperationState> completer = Completer();
      late StreamSubscription<ClipboardOperationState> subscription;
      subscription = tipUseCase.stream.listen((data) {
        subscription.cancel();
        completer.complete(data);
      });
      useCase.addMessage(const ClipboardMessage(content: 'test'));
      final state = await completer.future;
      expect(state.success, false);
      expect(state.cause, isA<CannotOperationException>());
    });

    test('operate failed cause by validate failed', () async {
      when(configUseCase.available).thenAnswer((_) => true);
      when(configUseCase.config).thenAnswer(
        (_) => const ClipboardConfig(maxBytes: 2048, maxCount: 20, expire: 60),
      );
      when(configUseCase.usage).thenAnswer(
        (_) => const ClipboardUsage(timestamp: 1, count: 20, bytes: 60),
      );

      Completer<ClipboardOperationState> completer = Completer();
      late StreamSubscription<ClipboardOperationState> subscription;
      subscription = tipUseCase.stream.listen((data) {
        subscription.cancel();
        completer.complete(data);
      });
      useCase.addMessage(const ClipboardMessage(content: 'test'));
      final state = await completer.future;
      expect(state.success, false);
      expect(state.cause, isA<ValidationFailedException>());
    });

    group('check success', () {
      setUp(() {
        when(configUseCase.available).thenAnswer((_) => true);
        when(configUseCase.config).thenAnswer(
          (_) =>
              const ClipboardConfig(maxBytes: 2048, maxCount: 20, expire: 60),
        );
        when(configUseCase.usage).thenAnswer(
          (_) => const ClipboardUsage(timestamp: 1, count: 1, bytes: 60),
        );
      });

      test('operate failed cause by api error', () async {
        when(
          dataRepository.addMessage(any),
        ).thenThrow(ClipboardApiException(message: 'api error'));

        Completer<ClipboardOperationState> completer = Completer();
        late StreamSubscription<ClipboardOperationState> subscription;
        subscription = tipUseCase.stream.listen((data) {
          subscription.cancel();
          completer.complete(data);
        });
        useCase.addMessage(const ClipboardMessage(content: 'test'));
        final state = await completer.future;
        expect(state.success, false);
        expect(state.cause, isA<ClipboardApiException>());
      });

      test('addMessage success', () async {
        when(dataRepository.addMessage(any)).thenAnswer((_) => Future.value());

        Completer<ClipboardOperationState> completer = Completer();
        late StreamSubscription<ClipboardOperationState> subscription;
        subscription = tipUseCase.stream.listen((data) {
          subscription.cancel();
          completer.complete(data);
        });
        // Act
        useCase.addMessage(const ClipboardMessage(content: 'test'));
        final state = await completer.future;

        // Assert
        expect(state.success, true);
      });

      test('removeMessage success', () async {
        when(
          dataRepository.removeMessage(any),
        ).thenAnswer((_) => Future.value());

        Completer<ClipboardOperationState> completer = Completer();
        late StreamSubscription<ClipboardOperationState> subscription;
        subscription = tipUseCase.stream.listen((data) {
          subscription.cancel();
          completer.complete(data);
        });
        // Act
        useCase.removeMessage('test');
        final state = await completer.future;

        // Assert
        expect(state.success, true);
      });

      test('clear success', () async {
        when(dataRepository.clear()).thenAnswer((_) => Future.value());

        Completer<ClipboardOperationState> completer = Completer();
        late StreamSubscription<ClipboardOperationState> subscription;
        subscription = tipUseCase.stream.listen((data) {
          subscription.cancel();
          completer.complete(data);
        });
        // Act
        useCase.clear();
        final state = await completer.future;

        // Assert
        expect(state.success, true);
      });

      test('copy success', () async {
        when(dataRepository.copy(any)).thenAnswer(
          (_) => Future.value(const ClipboardMessage(content: 'test')),
        );

        Completer<ClipboardOperationState> completer = Completer();
        late StreamSubscription<ClipboardOperationState> subscription;
        subscription = tipUseCase.stream.listen((data) {
          subscription.cancel();
          completer.complete(data);
        });
        // Act
        useCase.copy('test');
        final state = await completer.future;

        // Assert
        expect(state.success, true);
        expect(state.data, isA<ClipboardMessage>());
        expect(state.data.content, 'test');
      });
    });
  });

  group('ClipboardDataScannerUseCase', () {
    late MockClipboardConfigUseCase configUseCase;
    late MockClipboardDataRepository dataRepository;
    late ClipboardTipUseCase tipUseCase;
    late ClipboardDataScannerUseCase useCase;

    setUp(() {
      configUseCase = MockClipboardConfigUseCase();
      dataRepository = MockClipboardDataRepository();
      tipUseCase = ClipboardTipUseCase();
    });

    tearDown(() {
      tipUseCase.dispose();
      useCase.dispose();
    });

    test('cannot scan when cursor not ready', () async {
      useCase = ClipboardDataScannerUseCase(
        configUseCase: configUseCase,
        repository: dataRepository,
        tipUseCase: tipUseCase,
      );
      await useCase.scan();

      verifyNever(
        dataRepository.scan(
          timestamp: anyNamed('timestamp'),
          limit: anyNamed('limit'),
        ),
      );
    });

    test('scan success', () async {
      StreamController<bool> controller = StreamController.broadcast();
      when(configUseCase.available).thenAnswer((_) => true);
      when(configUseCase.availableStream).thenAnswer((_) => controller.stream);
      when(configUseCase.cursor).thenAnswer((_) => 1);
      when(
        dataRepository.scan(
          timestamp: anyNamed('timestamp'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer(
        (_) async => const ClipboardScanResult(
          messages: [
            ClipboardMessageMeta(
              id: 'test',
              preview: "test",
              length: 4,
              bytes: 4,
              timestamp: 1,
            ),
          ],
          cursor: 1,
        ),
      );

      useCase = ClipboardDataScannerUseCase(
        configUseCase: configUseCase,
        repository: dataRepository,
        tipUseCase: tipUseCase,
      );
      Completer<ClipboardScanResult> completer = Completer();
      late StreamSubscription<ClipboardScanResult> subscription;
      subscription = useCase.stream.listen((data) {
        subscription.cancel();
        completer.complete(data);
      });

      // Act
      controller.add(true);
      final result = await completer.future;

      expect(result.messages, isNotNull);
      expect(result.messages!.length, 1);
    });

    test('scan failed cause by no more data', () async {
      StreamController<bool> controller = StreamController.broadcast();
      when(configUseCase.available).thenAnswer((_) => true);
      when(configUseCase.availableStream).thenAnswer((_) => controller.stream);
      when(configUseCase.cursor).thenAnswer((_) => 1);
      when(
        dataRepository.scan(
          timestamp: anyNamed('timestamp'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer(
        (_) async => const ClipboardScanResult(messages: [], cursor: null),
      );

      useCase = ClipboardDataScannerUseCase(
        configUseCase: configUseCase,
        repository: dataRepository,
        tipUseCase: tipUseCase,
      );
      Completer<ClipboardOperationState> completer = Completer();
      late StreamSubscription<ClipboardOperationState> subscription;
      subscription = tipUseCase.stream.listen((data) {
        subscription.cancel();
        completer.complete(data);
      });

      // Act
      controller.add(true);
      final result = await completer.future;

      expect(result.success, false);
    });
  });

  group('ClipboardDataUseCase', () {
    late MockClipboardNotifyRepository repository;
    late ClipboardDataUseCase useCase;
    late MockClipboardDataScannerUseCase scannerUseCase;
    late StreamController<ClipboardNotify> controller;
    late StreamController<ClipboardScanResult> scanController;

    setUp(() {
      repository = MockClipboardNotifyRepository();
      scannerUseCase = MockClipboardDataScannerUseCase();
      when(repository.notifyStream).thenAnswer((_) => controller.stream);
      when(scannerUseCase.stream).thenAnswer((_) => scanController.stream);
      controller = StreamController.broadcast();
      scanController = StreamController.broadcast();
      useCase = ClipboardDataUseCase(
        repository: repository,
        useCase: scannerUseCase,
      );
    });

    tearDown(() {
      controller.close();
      scanController.close();
      useCase.dispose();
    });

    test('add data success', () async {
      Completer<DataChangeState> completer = Completer();
      late StreamSubscription<DataChangeState> subscription;
      subscription = useCase.stream.listen((state) {
        subscription.cancel();
        completer.complete(state);
      });

      controller.add(
        const NotifyAdd(
          meta: ClipboardMessageMeta(
            id: "id",
            preview: "test",
            length: 4,
            bytes: 4,
            timestamp: 1,
          ),
          usage: ClipboardUsage(timestamp: 1, count: 1, bytes: 4),
        ),
      );
      final result = await completer.future;

      expect(result, isA<DataAddedState>());
    });
    test('remove data success', () async {
      Completer<DataChangeState> completer = Completer();
      late StreamSubscription<DataChangeState> subscription;
      int count = 1;
      subscription = useCase.stream.listen((state) {
        if (count == 2) {
          subscription.cancel();
          completer.complete(state);
        }
        count++;
      });

      controller.add(
        const NotifyAdd(
          meta: ClipboardMessageMeta(
            id: "id",
            preview: "test",
            length: 4,
            bytes: 4,
            timestamp: 1,
          ),
          usage: ClipboardUsage(timestamp: 1, count: 1, bytes: 4),
        ),
      );
      controller.add(
        const NotifyRemove(
          id: "id",
          usage: ClipboardUsage(timestamp: 1, count: 0, bytes: 0),
        ),
      );
      final result = await completer.future;

      expect(result, isA<DataRemovedState>());
    });

    test('clear data success', () async {
      Completer<DataChangeState> completer = Completer();
      late StreamSubscription<DataChangeState> subscription;
      int count = 1;
      subscription = useCase.stream.listen((state) {
        if (count == 2) {
          subscription.cancel();
          completer.complete(state);
        }
        count++;
      });

      controller.add(
        const NotifyAdd(
          meta: ClipboardMessageMeta(
            id: "id",
            preview: "test",
            length: 4,
            bytes: 4,
            timestamp: 1,
          ),
          usage: ClipboardUsage(timestamp: 1, count: 1, bytes: 4),
        ),
      );
      controller.add(
        const NotifyClear(
          usage: ClipboardUsage(timestamp: 1, count: 0, bytes: 0),
        ),
      );
      final result = await completer.future;

      expect(result, isA<DataAllRemovedState>());
    });

    test('scan data success', () async {
      Completer<DataChangeState> completer = Completer();
      late StreamSubscription<DataChangeState> subscription;
      subscription = useCase.stream.listen((state) {
        subscription.cancel();
        completer.complete(state);
      });

      scanController.add(
        const ClipboardScanResult(
          messages: [
            ClipboardMessageMeta(
              id: "id",
              preview: "test",
              length: 4,
              bytes: 4,
              timestamp: 1,
            ),
          ],
          cursor: 1,
        ),
      );
      final result = await completer.future;

      expect(result, isA<DataAddedState>());
    });

    test('expire data success', () async {
      Completer<DataChangeState> completer = Completer();
      late StreamSubscription<DataChangeState> subscription;
      int count = 1;
      subscription = useCase.stream.listen((state) {
        if (count == 2) {
          subscription.cancel();
          completer.complete(state);
        }
        count++;
      });

      controller.add(
        const NotifyInit(
          cursor: 1,
          usage: ClipboardUsage(timestamp: 1, count: 0, bytes: 0),
          config: ClipboardConfig(maxBytes: 2048, maxCount: 50, expire: 1),
        ),
      );
      controller.add(
        const NotifyAdd(
          meta: ClipboardMessageMeta(
            id: "id",
            preview: "test",
            length: 4,
            bytes: 4,
            timestamp: 1,
          ),
          usage: ClipboardUsage(timestamp: 1, count: 1, bytes: 4),
        ),
      );

      final result = await completer.future;

      expect(result, isA<DataRemovedState>());
    });
  });
}
