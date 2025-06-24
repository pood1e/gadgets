import 'package:flutter/widgets.dart';

class AppBarConfig {
  final String id;
  final String title;
  final List<Widget>? actions;

  const AppBarConfig({required this.id, required this.title, this.actions});

  const AppBarConfig._preset()
    : id = 'default',
      title = 'Gadgets',
      actions = null;

  const factory AppBarConfig.preset() = AppBarConfig._preset;
}

class AppbarViewModel extends ChangeNotifier {
  AppbarViewModel({AppBarConfig? config})
    : _current = config ?? const AppBarConfig.preset();

  AppBarConfig _current;

  AppBarConfig get currentConfig => _current;

  void changeConfig(AppBarConfig config) {
    if (config != _current) {
      _current = config;
      notifyListeners();
    }
  }
}
