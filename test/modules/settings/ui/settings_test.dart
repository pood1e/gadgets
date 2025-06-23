import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/settings/l10n/settings_localizations.dart';
import 'package:gadgets/modules/settings/ui/settings.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';
import 'package:go_router/go_router.dart';

void main() {
  createTestWidget() => MaterialApp.router(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      SettingsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('zh')],
    locale: const Locale('zh'),
    routerConfig: GoRouter(
      initialLocation: '/settings',
      routes: [
        ShellRoute(
          builder: (context, state, child) => ResponsiveScaffold(child: child),
          routes: [
            GoRoute(path: '/settings', builder: (_, _) => const SettingsView()),
          ],
        ),
      ],
    ),
  );

  group('Settings', () {
    testWidgets('should show default text', (tester) async {
      // Arrange
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('settings'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });
  });
}
