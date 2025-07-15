import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/ui/scaffold/mobile_scaffold.dart';
import 'package:gadgets/shared/ui/scaffold/shell_scaffold.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:provider/provider.dart';

import '../../test_utils/test_constants.dart';

void main() {
  group('MobileScaffold', () {
    Widget createTestWidget({NavigationViewModel? navProvider}) {
      final nav = navProvider ?? presetTwoPageNavigation;
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: presetAppbarViewModel),
          Provider.value(value: nav),
          Provider.value(value: presetL10ViewModel),
        ],
        child: MyApp(
          router: createRouterByNavigations(
            nav.navigations,
            nav.initialRoute,
            (_, state, child) => ShellScaffold(
              state: state,
              child: MobileScaffold(child: child),
            ),
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

      testWidgets('should have an appbar', (tester) async {
        // Arrange
        // Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Gadgets'),
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
    });
  });
}
