import 'package:flutter/material.dart';
import 'package:gadgets/shared/ui/desktop_scaffold.dart';
import 'package:gadgets/shared/ui/mobile_scaffold.dart';
import 'package:gadgets/shared/utils/support_layout.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:gadgets/shared/view_models/layout_view_model.dart';
import 'package:provider/provider.dart';

/// 响应式外壳
class ResponsiveScaffold extends StatelessWidget {
  final Widget _child;

  const ResponsiveScaffold({super.key, required Widget child}) : _child = child;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: AppbarViewModel(),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final layout = SupportLayout.judge(constraints.maxWidth);
        final vm = context.read<LayoutViewModel>();
        if (vm.currentLayout != layout) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            vm.updateLayout(layout);
          });
        }
        return layout == SupportLayout.mobile
            ? MobileScaffold(
                key: const ValueKey('mobile-scaffold'),
                child: _child,
              )
            : DesktopScaffold(
                key: const ValueKey('desktop-scaffold'),
                child: _child,
              );
      },
    ),
  );
}
