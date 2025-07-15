import 'package:flutter/cupertino.dart';
import 'package:gadgets/shared/view_models/current_route_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ShellScaffold extends StatelessWidget {
  final GoRouterState _state;
  final Widget _child;

  const ShellScaffold({
    super.key,
    required GoRouterState state,
    required Widget child,
  }) : _state = state,
       _child = child;

  @override
  Widget build(BuildContext context) {
    final navigationViewModel = context.read<NavigationViewModel>();
    final define = navigationViewModel.allRoutes.firstWhere(
      (item) => _state.fullPath == item.route.path,
    );
    return ChangeNotifierProvider.value(
      value: CurrentRouteViewModel(define),
      child: _child,
    );
  }
}
