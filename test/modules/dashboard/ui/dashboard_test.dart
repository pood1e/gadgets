import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/dashboard/l10n/dashboard_localizations.dart';
import 'package:gadgets/modules/dashboard/ui/dashboard.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:go_router/go_router.dart';

import '../../../test_utils/test_constants.dart';

void main() {
  createTestWidget() => createSinglePageWidget(
    NavigationRouteDefine(
      id: 'dashboard',
      icon: const Icon(Icons.dashboard),
      localizationOf: DashboardLocalizations.of,
      localizationDelegate: DashboardLocalizations.delegate,
      goRoute: GoRoute(path: '/', builder: (_, _) => const DashboardView()),
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
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
