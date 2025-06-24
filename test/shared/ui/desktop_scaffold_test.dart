import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/ui/desktop_scaffold.dart';
import 'package:gadgets/shared/ui/shell_scaffold.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:provider/provider.dart';

import '../../test_utils/test_constants.dart';

void main() {
  group('DesktopScaffold', () {
    Widget createTestWidget({NavigationViewModel? navProvider}) {
      final nav = navProvider ?? presetSinglePageNavigation;
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
              child: DesktopScaffold(child: child),
            ),
          ),
        ),
      );
    }

    group('Sidebar', () {
      NavigationRail getRail(WidgetTester tester) =>
          tester.widget(find.byType(NavigationRail));

      testWidgets('should not expand default', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(getRail(tester).extended, false);
      });

      testWidgets('should show logo default', (tester) async {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget());

        // Assert
        expect(find.byKey(const ValueKey('logo')), findsOneWidget);
      });

      testWidgets('should show menu when hovered', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        // Act
        final position = tester.getCenter(find.byType(NavigationRail));
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: position);
        await tester.pump();

        // Assert
        expect(find.byKey(const ValueKey('logo')), findsNothing);
        expect(find.byIcon(Icons.menu), findsOneWidget);

        await gesture.removePointer();
      });

      testWidgets('should show logo when mouse exit', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        final position = tester.getCenter(find.byType(NavigationRail));
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: position);
        await tester.pump();

        // Act
        await gesture.removePointer();
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.menu), findsNothing);
        expect(find.byKey(const ValueKey('logo')), findsOneWidget);
      });

      testWidgets('should expand when tapped menu', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());

        final rail = find.byType(NavigationRail);
        final position = tester.getCenter(rail);
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: position);
        await tester.pump();

        // Act
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(const ValueKey('logo')), findsOneWidget);
        expect(getRail(tester).extended, true);

        await gesture.removePointer();
      });

      testWidgets('should expand when tapped rail', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        final rail = find.byType(NavigationRail);
        // Act
        await tester.tap(rail);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(const ValueKey('logo')), findsOneWidget);
        expect(getRail(tester).extended, true);
      });

      testWidgets('should collapse when tapped close', (tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        final rail = find.byType(NavigationRail);

        await tester.tap(rail);
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byIcon(Icons.menu_open));
        await tester.pumpAndSettle();

        // Assert
        expect(getRail(tester).extended, false);
      });
    });

    group('Appbar', () {
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
    });
  });
}
