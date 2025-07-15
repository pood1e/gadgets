import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/ui/component/logo_component.dart';

void main() {
  testWidgets('logo rebuild success', (tester) async {
    await tester.pumpWidget(const StaticLogo());

    for (var i = 0; i < 50; i++) {
      await tester.pump();
    }

    final element = tester.element(find.byType(StaticLogo));
    expect(element, isNotNull);
  });
}
