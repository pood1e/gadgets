import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';

void main() {
  testWidgets('start my app successfully', (tester) async {
    await tester.pumpWidget(configuredApp());

    expect(find.byType(ResponsiveScaffold), findsOneWidget);
  });
}
