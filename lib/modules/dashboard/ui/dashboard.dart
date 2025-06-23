import 'package:flutter/material.dart';
import 'package:gadgets/modules/dashboard/l10n/dashboard_localizations.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:provider/provider.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<StatefulWidget> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppbarViewModel>().changeConfig(
        AppBarConfig(
          id: 'dashboard',
          title: DashboardLocalizations.of(context)!.title,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Center(child: Text('dashboard'));
}
