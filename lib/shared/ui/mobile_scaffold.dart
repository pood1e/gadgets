import 'package:flutter/material.dart';
import 'package:gadgets/shared/ui/logo_component.dart';
import 'package:gadgets/shared/ui/navigation_component.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:gadgets/shared/view_models/current_route_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:provider/provider.dart';

class MobileScaffold extends StatelessWidget {
  final Widget _child;

  const MobileScaffold({super.key, required Widget child}) : _child = child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const _MobileAppbar(),
    drawer: const _MobileDrawer(),
    body: SafeArea(child: _child),
  );
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer();

  void _closeDrawer(BuildContext context) {
    final state = Scaffold.of(context);
    if (state.isDrawerOpen) {
      state.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context) => Drawer(
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    width: NavigationRailWrapper.sidebarExpandWidth,
    child: Column(
      children: [
        Expanded(
          child: Consumer<CurrentRouteViewModel>(
            builder: (context, vm, child) => NavigationRailWrapper(
              leading: SafeArea(
                child: _ExpandedLogoHeader(
                  end: IconButton(
                    onPressed: () => _closeDrawer(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              define: vm.current,
              items: context.read<NavigationViewModel>().navigations,
              onPush: (_) => _closeDrawer(context),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ExpandedLogoHeader extends StatelessWidget {
  final Widget _end;

  const _ExpandedLogoHeader({required Widget end}) : _end = end;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: NavigationRailWrapper.sidebarExpandWidth,
    height: kToolbarHeight - 16,
    child: Padding(
      padding: const EdgeInsets.only(left: 28, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [const StaticLogo(), _end],
      ),
    ),
  );
}

class _MobileAppbar extends StatelessWidget implements PreferredSizeWidget {
  const _MobileAppbar();

  @override
  Widget build(BuildContext context) => Consumer<AppbarViewModel>(
    builder: (_, barVm, _) => Consumer<CurrentRouteViewModel>(
      builder: (_, routeVm, _) {
        final actions =
            barVm.currentConfig.actions ?? const [SizedBox.shrink()];
        return AppBar(
          leading:
              barVm.currentConfig.leading ??
              IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu),
              ),
          centerTitle: true,
          title:
              barVm.currentConfig.title ??
              Text(routeVm.current.localizationOf(context).title),
          actions: [...actions, const SizedBox(width: 8)],
        );
      },
    ),
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
