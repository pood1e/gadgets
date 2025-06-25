import 'package:flutter/material.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';
import 'package:gadgets/shared/ui/shell_scaffold.dart';
import 'package:gadgets/shared/view_models/l10n_view_model.dart';
import 'package:gadgets/shared/view_models/layout_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  // debugPrintRebuildDirtyWidgets = true;
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: NavigationViewModel()),
        Provider.value(value: L10nViewModel()),
        ChangeNotifierProvider.value(value: LayoutViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final GoRouter? _router;

  const MyApp({super.key, GoRouter? router}) : _router = router;

  @override
  Widget build(BuildContext context) {
    final l10n = context.read<L10nViewModel>();
    final navigation = context.read<NavigationViewModel>();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: navigation.localizationsDelegates,
      supportedLocales: l10n.supportedLocales,
      locale: l10n.locale,
      routerConfig:
          _router ??
          createRouter(
            context,
            (_, state, child) => ShellScaffold(
              state: state,
              child: ResponsiveScaffold(child: child),
            ),
          ),
    );
  }
}
