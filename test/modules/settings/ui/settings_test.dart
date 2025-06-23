import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/settings/ui/settings.dart';

void main() {
  group('Settings', () {
    testWidgets('should show default text', (tester) async {
      // Arrange
      // Act
      await tester.pumpWidget(const MaterialApp(home: SettingsView()));

      // Assert
      expect(find.text('settings'), findsOneWidget);
    });
  });
}
