import 'package:flutter/material.dart';

class ShowMenuViewModel extends ChangeNotifier {
  bool _hovered = false;

  // animation.value == 0
  bool _collapsed = true;
  bool _showMenu = false;

  bool get showMenu => _showMenu;

  void updateHover(bool hovered) {
    _hovered = hovered;
    _notify();
  }

  void updateCollapse(bool collapsed) {
    _collapsed = collapsed;
    _notify();
  }

  void _notify() {
    final newValue = _hovered && _collapsed;
    if (_showMenu != newValue) {
      _showMenu = newValue;
      notifyListeners();
    }
  }
}
