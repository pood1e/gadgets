import 'package:flutter/material.dart';
import 'package:gadgets/modules/dashboard/l10n/dashboard_localizations.dart';
import 'package:gadgets/modules/dashboard/ui/dashboard.dart';
import 'package:gadgets/modules/settings/l10n/settings_localizations.dart';
import 'package:gadgets/modules/settings/ui/settings.dart';
import 'package:go_router/go_router.dart';

class RouteDefine {
  final String id;
  final Widget icon;
  final dynamic Function(BuildContext) localizationOf;
  final LocalizationsDelegate<dynamic> localizationDelegate;
  final GoRoute route;

  const RouteDefine({
    required this.id,
    required this.icon,
    required this.localizationOf,
    required this.localizationDelegate,
    required this.route,
  });
}

final navigationRouteDefines = [
  RouteDefine(
    id: 'dashboard',
    icon: const Icon(Icons.dashboard),
    localizationOf: (ctx) => DashboardLocalizations.of(ctx)!,
    localizationDelegate: DashboardLocalizations.delegate,
    route: GoRoute(
      path: '/',
      builder: (context, state) => const DashboardView(),
    ),
  ),
  RouteDefine(
    id: 'settings',
    icon: const Icon(Icons.settings),
    localizationOf: (ctx) => SettingsLocalizations.of(ctx)!,
    localizationDelegate: SettingsLocalizations.delegate,
    route: GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsView(),
    ),
  ),
];
