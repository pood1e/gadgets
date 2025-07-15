import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/ui/component/toast_component.dart';

void main() {
  testWidgets('toast component', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Tip(type: TipType.success, message: 'test'),
      ),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
