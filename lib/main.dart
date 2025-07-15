import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gadgets/shared/routing/router.dart';
import 'package:gadgets/shared/services/api_client_service.dart';
import 'package:gadgets/shared/ui/scaffold/responsive_scaffold.dart';
import 'package:gadgets/shared/ui/scaffold/shell_scaffold.dart';
import 'package:gadgets/shared/view_models/l10n_view_model.dart';
import 'package:gadgets/shared/view_models/layout_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Widget configuredApp() => MultiProvider(
  providers: [
    Provider.value(value: NavigationViewModel()),
    Provider.value(value: L10nViewModel()),
    ChangeNotifierProvider.value(value: LayoutViewModel()),
    Provider(
      create: (_) =>
          // ApiClientService(baseUrl: 'https://gadgets.pood1e.site:8443'),
          ApiClientService(baseUrl: 'http://localhost:8080'),
      dispose: (_, service) => service.dispose(),
    ),
  ],
  child: const MyApp(),
);

void main() {
  // debugPrintRebuildDirtyWidgets = true;
  runApp(configuredApp());
}

class MyApp extends StatelessWidget {
  final GoRouter? _router;

  const MyApp({super.key, GoRouter? router}) : _router = router;

  @override
  Widget build(BuildContext context) {
    final l10n = context.read<L10nViewModel>();
    final navigation = context.read<NavigationViewModel>();
    return MaterialApp.router(
      builder: FToastBuilder(),
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
