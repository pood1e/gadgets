import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gadgets/modules/dashboard/l10n/dashboard_localizations.dart';
import 'package:gadgets/modules/settings/l10n/settings_localizations.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/ui/responsive_scaffold.dart';
import 'package:go_router/go_router.dart';

GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ResponsiveScaffold(child: child),
      routes: navigationRouteDefines.map((item) => item.goRoute).toList(),
    ),
  ],
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      DashboardLocalizations.delegate,
      SettingsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('zh'), Locale('en')],
    routerConfig: _router,
  );
}
