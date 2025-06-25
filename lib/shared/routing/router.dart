import 'package:flutter/widgets.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

GoRouter createRouter(BuildContext context, ShellRouteBuilder shellBuilder) {
  final navigation = context.read<NavigationViewModel>();
  return createRouterByNavigations(
    navigation.navigations,
    navigation.initialRoute,
    shellBuilder,
  );
}

GoRouter createRouterByNavigations(
  List<RouteDefine> navigations,
  String initialRoute,
  ShellRouteBuilder shellBuilder,
) => GoRouter(
  initialLocation: initialRoute,
  routes: [
    ShellRoute(
      builder: shellBuilder,
      routes: navigations.map((item) => item.route).toList(),
    ),
  ],
);
