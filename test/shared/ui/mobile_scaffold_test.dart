import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/ui/mobile_scaffold.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../test_utils/test_constants.dart';

void main() {
  group('MobileScaffold', () {
    Widget createTestWidget({
      AppbarViewModel? provider,
      NavigationViewModel? navProvider,
    }) {
      final nav = navProvider ?? presetTwoPageNavigation;
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: provider ?? presetAppbarViewModel,
          ),
          Provider.value(value: nav),
          Provider.value(value: presetL10ViewModel),
        ],
        child: MyApp(
          router: createRouterByNavigations(
            nav.navigations,
            nav.initialRoute,
            (_, _, child) => MobileScaffold(child: child),
          ),
        ),
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
      Finder findBackButton() => find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(BackButton),
      );

      GoRouter getRouter(WidgetTester tester) =>
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig
              as GoRouter;

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
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(getRouter(tester).state.path, '/');
        expect(findBackButton(), findsNothing);
      });

      testWidgets('should show back button on non-root routes', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        // Act
        getRouter(tester).push('/test');
        await tester.pumpAndSettle();

        // Assert
        expect(getRouter(tester).state.path, '/test');
        expect(findBackButton(), findsOneWidget);
      });
      testWidgets('should navigate back when tapped back button', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        getRouter(tester).push('/test');
        await tester.pumpAndSettle();

        // Act
        await tester.tap(findBackButton());
        await tester.pumpAndSettle();

        // Assert
        expect(getRouter(tester).state.path, '/');
        expect(findBackButton(), findsNothing);
      });
    });
  });
}
