import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/dashboard/l10n/dashboard_localizations.dart';
import 'package:gadgets/modules/dashboard/ui/dashboard.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';
import 'package:go_router/go_router.dart';

void main() {
  createTestWidget() => MaterialApp.router(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      DashboardLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('zh')],
    locale: const Locale('zh'),
    routerConfig: GoRouter(
      initialLocation: '/',
      routes: [
        ShellRoute(
          builder: (context, state, child) => ResponsiveScaffold(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, _) => const DashboardView()),
          ],
        ),
      ],
    ),
  );

  group('Dashboard', () {
    testWidgets('should show default text', (tester) async {
      // Arrange
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('dashboard'), findsOneWidget);
      expect(find.text('仪表盘'), findsOneWidget);
    });
  });
}
