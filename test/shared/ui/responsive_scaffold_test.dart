import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/ui/desktop_scaffold.dart';
import 'package:gadgets/shared/ui/mobile_scaffold.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';
import 'package:provider/provider.dart';

import '../../test_utils/test_constants.dart';

void main() {
  Widget createTestWidget(Widget Function(Widget child) builder) =>
      MultiProvider(
        providers: [...presetProviders],
        child: MyApp(
          router: createRouterByNavigations(
            presetSinglePageNavigation.navigations,
            presetSinglePageNavigation.initialRoute,
            (_, _, child) => builder(ResponsiveScaffold(child: child)),
          ),
        ),
      );

  testWidgets('show mobile scaffold when width < 800 (mobile)', (tester) async {
    // Arrange
    await tester.pumpWidget(
      createTestWidget(
        (child) => ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: child,
        ),
      ),
    );
    // Act
    await tester.pumpAndSettle();

    expect(find.byType(MobileScaffold), findsOneWidget);
  });

  testWidgets(
    'show desktop scaffold when width > 800 and screenWidth > 1024 (desktop)',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestWidget(
          (child) => MediaQuery(
            data: const MediaQueryData(size: Size(1920, 1080)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: child,
            ),
          ),
        ),
      );
      // Act
      await tester.pumpAndSettle();

      expect(find.byType(DesktopScaffold), findsOneWidget);
    },
  );
}
