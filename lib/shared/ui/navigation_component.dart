import 'package:flutter/material.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:go_router/go_router.dart';

/// 标准导航栏
abstract class _MyNavigationRail extends StatelessWidget {
  final List<NavigationRouteDefine> _items;
  final bool _extended;

  bool get extended => _extended;

  List<NavigationRouteDefine> get items => List.unmodifiable(_items);

  const _MyNavigationRail({
    super.key,
    bool? extended,
    required List<NavigationRouteDefine> items,
  }) : _extended = extended ?? true,
       _items = items;

  int? currentSelected(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    return _items.indexWhere((item) {
      if (item.goRoute.path == '/') {
        return currentPath == '/';
      } else {
        return currentPath.startsWith(item.goRoute.path);
      }
    });
  }

  String translateText(BuildContext context, NavigationRouteDefine define) =>
      define.localizationOf(context).title;

  void onItemSelected(BuildContext context, NavigationRouteDefine item) {
    final currentPath = GoRouterState.of(context).uri.path;
    if (currentPath != item.goRoute.path) {
      context.push(item.goRoute.path);
    }
  }
}

/// 先使用固定的导航项，后续看看是否采用动态的导航项
class NavigationRailWrapper extends _MyNavigationRail {
  const NavigationRailWrapper({
    super.key,
    super.extended,
    required super.items,
    Widget? leading,
    Widget? trailing,
    void Function(NavigationRouteDefine)? onItemSelected,
  }) : _leading = leading,
       _trailing = trailing,
       _onItemSelected = onItemSelected;

  final Widget? _leading;
  final Widget? _trailing;
  final void Function(NavigationRouteDefine)? _onItemSelected;

  static const sidebarExpandWidth = 256.0;
  static const sidebarCollapseWidth = 72.0;

  List<NavigationRailDestination> navItems(BuildContext context) => items
      .map(
        (item) => NavigationRailDestination(
          icon: item.icon,
          label: Text(translateText(context, item)),
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) => NavigationRail(
    leading: _leading,
    trailing: _trailing,
    extended: extended,
    minWidth: sidebarCollapseWidth,
    minExtendedWidth: sidebarExpandWidth,
    destinations: navItems(context),
    selectedIndex: currentSelected(context),
    onDestinationSelected: (index) {
      onItemSelected(context, items[index]);
      if (_onItemSelected != null) {
        _onItemSelected(items[index]);
      }
    },
  );
}
