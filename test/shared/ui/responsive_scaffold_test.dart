import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/ui/desktop_scaffold.dart';
import 'package:gadgets/shared/ui/mobile_scaffold.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';
import 'package:go_router/go_router.dart';

void main() {
  createTestWidget(Widget Function(Widget child) builder) => MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: const [Locale('en'), Locale('zh')],
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              builder(ResponsiveScaffold(child: child)),
          routes: navigationRouteDefines.map((item) => item.goRoute).toList(),
        ),
      ],
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
