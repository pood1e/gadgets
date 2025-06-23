import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/ui/mobile_scaffold.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  group('MobileScaffold', () {
    late AppbarViewModel viewModel;

    setUp(() {
      const appbarConfig = AppBarConfig(id: 'app', title: 'app');
      viewModel = AppbarViewModel(config: appbarConfig);
    });

    Widget createTestWidget({
      AppbarViewModel? provider,
      GoRouter Function(Widget Function(Widget child) builder)? routerBuilder,
    }) {
      widgetBuilder(Widget child) => ChangeNotifierProvider<AppbarViewModel>(
        create: (_) => provider ?? viewModel,
        child: MobileScaffold(child: child),
      );
      final testRouterBuilder =
          routerBuilder ??
          (builder) => GoRouter(
            initialLocation: '/',
            routes: [
              ShellRoute(
                builder: (_, _, child) => builder(child),
                routes: [
                  GoRoute(path: '/', builder: (context, state) => Container()),
                ],
              ),
            ],
          );
      return MaterialApp.router(
        routerConfig: testRouterBuilder(widgetBuilder),
        localizationsDelegates: const [AppLocalizations.delegate],
      );
    }


    group('Drawer', () {
      ScaffoldState getScaffoldState(WidgetTester tester) =>
          tester.state<ScaffoldState>(find.byType(Scaffold));

      testWidgets('should show menu icon', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(getScaffoldState(tester).isDrawerOpen, false);
        expect(find.byIcon(Icons.menu), findsOneWidget);
      });

      testWidgets('should open drawer when tapped', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Assert
        expect(getScaffoldState(tester).isDrawerOpen, true);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should close drawer when tapped', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Assert
        expect(getScaffoldState(tester).isDrawerOpen, false);
        expect(find.byIcon(Icons.menu), findsOneWidget);
      });
    });

    group('Appbar', () {
      late GoRouter router;

      Finder findBackButton() => find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(BackButton),
      );

      createTestWidgetWithRouter() => createTestWidget(
        routerBuilder: (builder) {
          router = GoRouter(
            initialLocation: '/',
            routes: [
              ShellRoute(
                builder: (_, _, child) => builder(child),
                routes: [
                  GoRoute(path: '/', builder: (context, state) => Container()),
                  GoRoute(
                    path: '/test',
                    builder: (context, state) => Container(),
                  ),
                ],
              ),
            ],
          );
          return router;
        },
      );

      testWidgets('should have an appbar', (tester) async {
        // Arrange
        const appbarConfig = AppBarConfig(id: 'for-test', title: 'for-test');
        final appbarProvider = AppbarViewModel(config: appbarConfig);
        // Act
        await tester.pumpWidget(createTestWidget(provider: appbarProvider));

        // Assert
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text(appbarConfig.title),
          ),
          findsOneWidget,
        );
      });

      testWidgets('should not show back button on root route', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidgetWithRouter());

        // Assert
        expect(router.state.path, '/');
        expect(findBackButton(), findsNothing);
      });

      testWidgets('should show back button on non-root routes', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidgetWithRouter());

        // Act
        router.push('/test');
        await tester.pumpAndSettle();

        // Assert
        expect(router.state.path, '/test');
        expect(findBackButton(), findsOneWidget);
      });
      testWidgets('should navigate back when tapped back button', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidgetWithRouter());
        router.push('/test');
        await tester.pumpAndSettle();

        // Act
        await tester.tap(findBackButton());
        await tester.pumpAndSettle();

        // Assert
        expect(router.state.path, '/');
        expect(findBackButton(), findsNothing);
      });
    });
  });
}
