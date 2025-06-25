import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/routing/routers.dart';

class NavigationViewModel {
  final List<RouteDefine> _navigations;
  final List<RouteDefine> _appRoutes;
  final String initialRoute;

  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      List.unmodifiable([
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ..._navigations.map((item) => item.localizationDelegate),
        ..._appRoutes.map((item) => item.localizationDelegate),
      ]);

  List<RouteDefine> get navigations => List.unmodifiable(_navigations);

  List<RouteDefine> get appRoutes =>
      List.unmodifiable(_appRoutes);

  List<RouteDefine> get allRoutes =>
      List.unmodifiable([..._navigations, ..._appRoutes]);

  NavigationViewModel({
    String? initialRoute,
    List<RouteDefine>? navigations,
    List<RouteDefine>? appRoutes,
  }) : _navigations = navigations ?? navigationRouteDefines,
       _appRoutes = appRoutes ?? appRouteDefines,
       initialRoute = initialRoute ?? '/';
}
