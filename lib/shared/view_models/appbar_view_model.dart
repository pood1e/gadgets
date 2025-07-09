import 'package:flutter/widgets.dart';

class AppBarConfig {
  final String id;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? title;

  const AppBarConfig({
    required this.id,
    this.actions,
    this.leading,
    this.title,
  });

  factory AppBarConfig.preset() => const AppBarConfig(id: 'default');
}

class AppbarViewModel extends ChangeNotifier {
  AppbarViewModel({AppBarConfig? config})
    : _current = config ?? AppBarConfig.preset();

  AppBarConfig _current;

  AppBarConfig get currentConfig => _current;

  void changeConfig(AppBarConfig config) {
    if (_current != config) {
      _current = config;
      notifyListeners();
    }
  }
}
