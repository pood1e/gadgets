import 'package:flutter/widgets.dart';

class AppBarConfig {
  final String id;
  final String title;
  final List<Widget>? actions;

  const AppBarConfig({required this.id, required this.title, this.actions});

  factory AppBarConfig.preset() =>
      const AppBarConfig(id: 'default', title: 'Gadgets');
}

class AppbarViewModel extends ChangeNotifier {
  AppbarViewModel({AppBarConfig? config})
    : _current = config ?? AppBarConfig.preset();

  AppBarConfig _current;

  AppBarConfig get currentConfig => _current;

  void changeConfig(AppBarConfig config) {
    if (config != _current) {
      _current = config;
      notifyListeners();
    }
  }
}
