import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/settings/l10n/settings_localizations.dart';
import 'package:gadgets/modules/settings/ui/settings.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:go_router/go_router.dart';

import '../../../test_utils/test_constants.dart';

void main() {
  createTestWidget() => createSinglePageWidget(
    NavigationRouteDefine(
      id: 'settings',
      icon: const Icon(Icons.dashboard),
      localizationOf: SettingsLocalizations.of,
      localizationDelegate: SettingsLocalizations.delegate,
      goRoute: GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsView(),
      ),
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
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
