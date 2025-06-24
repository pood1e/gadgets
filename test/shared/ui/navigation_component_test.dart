import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/ui/navigation_component.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../test_utils/test_constants.dart';

void main() {
  group('NavigationRailWrapper', () {
    Widget createTestWidget() => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: presetAppbarViewModel),
        Provider.value(value: presetTwoPageNavigation),
        Provider.value(value: presetL10ViewModel),
      ],
      child: MyApp(
        router: createRouterByNavigations(
          presetTwoPageNavigation.navigations,
          presetTwoPageNavigation.initialRoute,
          (_, _, child) => Scaffold(
            body: Row(
              children: [
                NavigationRailWrapper(
                  items: presetTwoPageNavigation.navigations,
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );

    findNavigationRail(WidgetTester tester) =>
        tester.widget<NavigationRail>(find.byType(NavigationRail));

    GoRouter getRouter(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig
            as GoRouter;

    testWidgets('selected the default navigation item', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(getRouter(tester).state.path, '/');
      final navRail = findNavigationRail(tester);
      expect(navRail.selectedIndex, 0);
    });

    testWidgets('selected and navigated', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.cabin));
      await tester.pumpAndSettle();

      expect(getRouter(tester).state.path, '/test');
      final navRail = findNavigationRail(tester);
      expect(navRail.selectedIndex, 1);
    });
  });
}
