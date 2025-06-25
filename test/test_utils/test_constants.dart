import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/main.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:gadgets/shared/view_models/l10n_view_model.dart';
import 'package:gadgets/shared/view_models/layout_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/test_localizations.dart';

const presetAppbarConfig = AppBarConfig(id: 'app');
final presetAppbarViewModel = AppbarViewModel(config: presetAppbarConfig);
final presetSinglePageNavigation = NavigationViewModel(
  initialRoute: '/',
  navigations: [
    RouteDefine(
      id: 'root',
      icon: const Icon(Icons.home),
      localizationOf: TestLocalizations.of,
      localizationDelegate: TestLocalizations.delegate,
      route: GoRoute(path: '/', builder: (_, _) => Container()),
    ),
  ],
);

final presetTwoPageNavigation = NavigationViewModel(
  initialRoute: '/',
  navigations: [
    RouteDefine(
      id: 'root',
      icon: const Icon(Icons.home),
      localizationOf: TestLocalizations.of,
      localizationDelegate: TestLocalizations.delegate,
      route: GoRoute(path: '/', builder: (_, _) => Container()),
    ),
    RouteDefine(
      id: 'test',
      icon: const Icon(Icons.cabin),
      localizationOf: TestLocalizations.of,
      localizationDelegate: TestLocalizations.delegate,
      route: GoRoute(path: '/test', builder: (_, _) => Container()),
    ),
  ],
);

final presetLayoutViewModel = LayoutViewModel();

final presetL10ViewModel = L10nViewModel();

final presetProviders = List.unmodifiable([
  Provider.value(value: presetSinglePageNavigation),
  Provider.value(value: presetL10ViewModel),
  ChangeNotifierProvider.value(value: presetLayoutViewModel),
]);

Widget createSinglePageWidget(RouteDefine define) => MultiProvider(
  providers: [
    Provider.value(value: L10nViewModel(locale: const Locale('en'))),
    Provider.value(
      value: NavigationViewModel(
        initialRoute: define.route.path,
        navigations: [define],
      ),
    ),
    ChangeNotifierProvider.value(value: presetLayoutViewModel),
  ],
  child: const MyApp(),
);

GoRouter getRouter(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig
    as GoRouter;