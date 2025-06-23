import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/ui/navigation_component.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('NavigationRailWrapper', () {
    late GoRouter goRouter;

    setUp(() {
      goRouter = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            routes: navigationRouteDefines.map((item) => item.goRoute).toList(),
            builder: (_, _, child) => Scaffold(
              body: Row(children: [const NavigationRailWrapper(), child]),
            ),
          ),
        ],
      );
    });

    createTestWidget() => MaterialApp.router(
      routerConfig: goRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('zh')],
    );

    findNavigationRail(WidgetTester tester) =>
        tester.widget<NavigationRail>(find.byType(NavigationRail));

    testWidgets('selected the default navigation item', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(goRouter.state.path, '/');
      final navRail = findNavigationRail(tester);
      expect(navRail.selectedIndex, 0);
    });

    testWidgets('selected and navigated', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(goRouter.state.path, '/settings');
      final navRail = findNavigationRail(tester);
      expect(navRail.selectedIndex, 1);
    });
  });
}
