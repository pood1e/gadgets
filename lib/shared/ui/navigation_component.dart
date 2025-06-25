import 'package:flutter/material.dart';
import 'package:gadgets/shared/routing/routers.dart';
import 'package:go_router/go_router.dart';

/// 标准导航栏
abstract class _MyNavigationRail extends StatelessWidget {
  final List<RouteDefine> _items;
  final bool _extended;
  final RouteDefine _define;
  final Function(RouteDefine)? _onPush;

  const _MyNavigationRail({
    super.key,
    bool? extended,
    required List<RouteDefine> items,
    required RouteDefine define,
    void Function(RouteDefine)? onPush,
  }) : _extended = extended ?? true,
       _items = items,
       _define = define,
       _onPush = onPush;

  int? _currentSelected() {
    int index = _items.indexWhere((item) => item == _define);
    return index == -1 ? null : index;
  }

  String translateText(BuildContext context, RouteDefine define) =>
      define.localizationOf(context).title;

  void _onItemSelected(BuildContext context, RouteDefine item) {
    if (item != _define) {
      context.go(item.route.path);
      if (_onPush != null) {
        _onPush(item);
      }
    }
  }
}

/// 先使用固定的导航项，后续看看是否采用动态的导航项
class NavigationRailWrapper extends _MyNavigationRail {
  const NavigationRailWrapper({
    super.key,
    super.extended,
    super.onPush,
    required super.define,
    required super.items,
    Widget? leading,
    Widget? trailing,
  }) : _leading = leading,
       _trailing = trailing;

  final Widget? _leading;
  final Widget? _trailing;

  static const sidebarExpandWidth = 256.0;
  static const sidebarCollapseWidth = 72.0;

  List<NavigationRailDestination> _navItems(BuildContext context) => _items
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
    extended: _extended,
    minWidth: sidebarCollapseWidth,
    minExtendedWidth: sidebarExpandWidth,
    destinations: _navItems(context),
    selectedIndex: _currentSelected(),
    onDestinationSelected: (index) {
      _onItemSelected(context, _items[index]);
    },
  );
}
