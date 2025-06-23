import 'package:flutter/material.dart';
import 'package:gadgets/shared/ui/navigation_component.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:provider/provider.dart';

import 'logo_component.dart';

class DesktopScaffold extends StatelessWidget {
  final Widget _child;

  Widget _buildAppbar() => const _DesktopAppbar();

  const DesktopScaffold({super.key, required Widget child}) : _child = child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        const _DesktopSidebar(),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(
          child: Column(
            children: [
              _buildAppbar(),
              Expanded(child: _child),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DesktopSidebar extends StatefulWidget {
  const _DesktopSidebar();

  @override
  State<StatefulWidget> createState() => _DesktopSidebarState();
}

class _NavigationRailWithLeading extends NavigationRailWrapper {
  final Widget? _leading;

  const _NavigationRailWithLeading({super.extended, required Widget? leading})
    : _leading = leading;

  @override
  Widget build(BuildContext context) => NavigationRail(
    leading: _leading,
    extended: extended,
    minWidth: NavigationRailWrapper.sidebarCollapseWidth,
    minExtendedWidth: NavigationRailWrapper.sidebarExpandWidth,
    destinations: navItems(context),
    selectedIndex: currentSelected(context),
    onDestinationSelected: (index) => onItemSelected(context, items[index]),
  );
}

class _DesktopSidebarState extends State<_DesktopSidebar> {
  bool _extended = false;
  bool _hovered = false;

  final ValueNotifier<bool> _showMenuNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _showMenuNotifier.dispose();
    super.dispose();
  }

  void _setExtended(bool value) {
    if (_extended != value) {
      setState(() {
        _extended = value;
        _updateShowMenu();
      });
    }
  }

  void _updateShowMenu() {
    _showMenuNotifier.value = !_extended && _hovered;
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _setExtended(true),
    child: MouseRegion(
      onEnter: (_) {
        _hovered = true;
        _updateShowMenu();
      },
      onExit: (_) {
        _hovered = false;
        _updateShowMenu();
      },
      child: _NavigationRailWithLeading(
        extended: _extended,
        leading: _LogoSection(
          showMenuNotifier: _showMenuNotifier,
          onSetExtended: _setExtended,
        ),
      ),
    ),
  );
}

class _DesktopAppbar extends StatelessWidget implements PreferredSizeWidget {
  const _DesktopAppbar();

  @override
  Widget build(BuildContext context) => Selector<AppbarViewModel, AppBarConfig>(
    selector: (_, vm) => vm.currentConfig,
    builder: (_, config, _) =>
        AppBar(title: Text(config.title), actions: config.actions),
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// 独立的 Logo 组件，减少重建范围
class _LogoSection extends StatelessWidget {
  final ValueNotifier<bool> showMenuNotifier;
  final ValueSetter<bool> onSetExtended;

  const _LogoSection({
    required this.showMenuNotifier,
    required this.onSetExtended,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = NavigationRail.extendedAnimation(
      context,
    );

    final noChangeArea = SizedBox(
      height: kToolbarHeight - 16,
      width: NavigationRailWrapper.sidebarCollapseWidth,
      child: Center(
        child: ValueListenableBuilder<bool>(
          valueListenable: showMenuNotifier,
          builder: (context, hovered, child) => hovered
              ? IconButton(
                  onPressed: () => onSetExtended(true),
                  icon: const Icon(Icons.menu),
                )
              : const StaticLogo(key: ValueKey('logo')),
        ),
      ),
    );

    return Row(
      children: [
        noChangeArea,
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) => SizedBox(
            width:
                animation.value *
                (NavigationRailWrapper.sidebarExpandWidth -
                    NavigationRailWrapper.sidebarCollapseWidth),
            height: kToolbarHeight - 16,
            child: Align(
              alignment: Alignment.centerRight,
              child: Opacity(
                opacity: animation.value, // 根据动画值控制透明度
                child: Transform.scale(
                  scale: animation.value,
                  child: Wrap(
                    children: [
                      IconButton(
                        onPressed: () => onSetExtended(false),
                        icon: const Icon(Icons.menu_open),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
