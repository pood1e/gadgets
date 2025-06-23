import 'package:flutter/material.dart';
import 'package:gadgets/shared/ui/desktop_scaffold.dart';
import 'package:gadgets/shared/ui/mobile_scaffold.dart';
import 'package:gadgets/shared/utils/support_layout.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:provider/provider.dart';

/// 响应式外壳
class ResponsiveScaffold extends StatefulWidget {
  final Widget child;

  const ResponsiveScaffold({super.key, required this.child});

  @override
  State<StatefulWidget> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  final ValueNotifier<SupportLayout> _layoutNotifier = ValueNotifier(
    SupportLayout.getDefaultLayoutByPlatform(),
  );

  @override
  void dispose() {
    _layoutNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final width = constraints.maxWidth;
      SupportLayout shouldUseLayout = SupportLayout.judge(screenWidth, width);
      if (shouldUseLayout != _layoutNotifier.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _layoutNotifier.value = shouldUseLayout;
        });
      }

      return ChangeNotifierProvider(
        create: (_) => AppbarViewModel(),
        child: ValueListenableBuilder(
          valueListenable: _layoutNotifier,
          builder: (_, value, _) => value == SupportLayout.mobile
              ? MobileScaffold(child: widget.child)
              : DesktopScaffold(child: widget.child),
        ),
      );
    },
  );
}
