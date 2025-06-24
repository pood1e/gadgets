import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/routing/routers.dart';

class NavigationViewModel {
  final List<RouteDefine> _navigations;
  final String initialRoute;

  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      List.unmodifiable([
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ..._navigations.map((item) => item.localizationDelegate),
      ]);

  List<RouteDefine> get navigations => List.unmodifiable(_navigations);

  NavigationViewModel({String? initialRoute, List<RouteDefine>? navigations})
    : _navigations = navigations ?? navigationRouteDefines,
      initialRoute = initialRoute ?? '/';
}
