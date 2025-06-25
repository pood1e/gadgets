import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';
import 'package:gadgets/shared/view_models/l10n_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:provider/provider.dart';

import 'test_utils/test_constants.dart';

void main() {
  testWidgets('start my app successfully', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: NavigationViewModel()),
          Provider.value(value: L10nViewModel()),
          ChangeNotifierProvider.value(value: presetLayoutViewModel),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.byType(ResponsiveScaffold), findsOneWidget);
  });
}
