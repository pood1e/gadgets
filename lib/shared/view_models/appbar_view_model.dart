import 'package:flutter/widgets.dart';

class AppBarConfig {
  final String id;
  final List<Widget>? actions;

  const AppBarConfig({required this.id, this.actions});

  const AppBarConfig._preset() : id = 'default', actions = null;

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
