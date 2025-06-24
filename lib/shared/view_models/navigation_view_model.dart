import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/routing/routers.dart';

class NavigationViewModel {
  final List<NavigationRouteDefine> _navigations;
  final String initialRoute;

  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      List.unmodifiable([
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ..._navigations.map((item) => item.localizationDelegate),
      ]);

  List<NavigationRouteDefine> get navigations =>
      List.unmodifiable(_navigations);

  NavigationViewModel({
    String? initialRoute,
    List<NavigationRouteDefine>? navigations,
  }) : _navigations = navigations ?? navigationRouteDefines,
       initialRoute = initialRoute ?? '/';
}
