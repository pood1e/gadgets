import 'package:flutter/material.dart';
import 'package:gadgets/shared/ui/navigation_component.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:gadgets/shared/view_models/navigation_view_model.dart';
import 'package:gadgets/shared/view_models/show_menu_view_model.dart';
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

class _DesktopSidebarState extends State<_DesktopSidebar> {
  bool _extended = false;
  late ShowMenuViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ShowMenuViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _setExtended(bool value) {
    if (_extended != value) {
      setState(() {
        _extended = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _setExtended(true),
    child: MouseRegion(
      onEnter: (_) {
        _viewModel.updateHover(true);
      },
      onExit: (_) {
        _viewModel.updateHover(false);
      },
      child: NavigationRailWrapper(
        extended: _extended,
        leading: ChangeNotifierProvider.value(
          value: _viewModel,
          child: _LogoSection(onSetExtended: _setExtended),
        ),
        items: context.read<NavigationViewModel>().navigations,
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
  final ValueSetter<bool> onSetExtended;

  const _LogoSection({required this.onSetExtended});

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = NavigationRail.extendedAnimation(
      context,
    );
    final viewModel = context.read<ShowMenuViewModel>();
    animation.addStatusListener((status) {
      if (status.isDismissed) {
        viewModel.updateCollapse(true);
      } else {
        viewModel.updateCollapse(false);
      }
    });

    final noChangeArea = SizedBox(
      height: kToolbarHeight - 16,
      width: NavigationRailWrapper.sidebarCollapseWidth,
      child: Center(
        child: Consumer<ShowMenuViewModel>(
          builder: (context, vm, child) => vm.showMenu
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
