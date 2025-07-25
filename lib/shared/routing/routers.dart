import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gadgets/modules/apps/l10n/apps_localizations.dart';
import 'package:gadgets/modules/apps/ui/apps.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_localizations.dart';
import 'package:gadgets/modules/clipboard/main.dart';
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
    id: 'apps',
    icon: const Icon(Icons.apps),
    localizationOf: (ctx) => AppsLocalizations.of(ctx)!,
    localizationDelegate: AppsLocalizations.delegate,
    route: GoRoute(
      path: '/',
      builder: (context, state) => const AppCenterView(),
    ),
  ),
  RouteDefine(
    id: 'dashboard',
    icon: const Icon(Icons.dashboard),
    localizationOf: (ctx) => DashboardLocalizations.of(ctx)!,
    localizationDelegate: DashboardLocalizations.delegate,
    route: GoRoute(
      path: '/dashboard',
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

final List<RouteDefine> appRouteDefines = [
  RouteDefine(
    id: 'clipboard',
    icon: SvgPicture.asset('assets/svg/clipboard.svg'),
    localizationOf: (ctx) => ClipboardLocalizations.of(ctx)!,
    localizationDelegate: ClipboardLocalizations.delegate,
    route: GoRoute(
      path: '/clipboard',
      builder: (context, state) => const ClipboardApp(),
    ),
  ),
];
