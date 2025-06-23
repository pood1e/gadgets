import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/dashboard/ui/dashboard.dart';

void main() {
  group('Dashboard', () {
    testWidgets('should show default text', (tester) async {
      // Arrange
      // Act
      await tester.pumpWidget(const MaterialApp(home: DashboardView()));

      // Assert
      expect(find.text('dashboard'), findsOneWidget);
    });
  });
}
