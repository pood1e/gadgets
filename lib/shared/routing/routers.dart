import 'package:flutter/material.dart';
import 'package:gadgets/modules/dashboard/ui/dashboard.dart';
import 'package:gadgets/modules/settings/ui/settings.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class NavigationRouteDefine {
  final String id;
  final Widget icon;
  final String route;

  const NavigationRouteDefine({
    required this.id,
    required this.icon,
    required this.route,
  });
}

const navigationRouteDefines = [
  NavigationRouteDefine(
    id: 'dashboard',
    icon: Icon(Icons.dashboard),
    route: '/',
  ),
  NavigationRouteDefine(
    id: 'settings',
    icon: Icon(Icons.settings),
    route: '/settings',
  ),
];

extension RouteDefineEnhancer on NavigationRouteDefine {
  String translate(AppLocalizations l10n) => switch (id) {
    'dashboard' => l10n.dashboard,
    'settings' => l10n.settings,
    _ => throw Exception('have no localization defined'),
  };

  GoRoute get goRoute => switch (id) {
    'dashboard' => GoRoute(
      path: route,
      builder: (context, state) => const DashboardView(),
    ),
    'settings' => GoRoute(
      path: route,
      builder: (context, state) => const SettingsView(),
    ),
    _ => throw Exception('have no GoRoute defined'),
  };
}
