import 'package:flutter/widgets.dart';
import 'package:gadgets/modules/settings/l10n/settings_localizations.dart';
import 'package:gadgets/shared/view_models/appbar_view_model.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<StatefulWidget> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppbarViewModel>().changeConfig(
        AppBarConfig(
          id: 'settings',
          title: SettingsLocalizations.of(context)!.title,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Center(child: Text('settings'));
}
