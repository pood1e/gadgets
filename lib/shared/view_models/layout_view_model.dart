import 'package:flutter/widgets.dart';
import 'package:gadgets/shared/utils/support_layout.dart';

class LayoutViewModel extends ChangeNotifier {
  SupportLayout _currentLayout;

  SupportLayout get currentLayout => _currentLayout;

  void updateLayout(SupportLayout layout) {
    if (_currentLayout != layout) {
      _currentLayout = layout;
      notifyListeners();
    }
  }

  LayoutViewModel({SupportLayout? layout})
    : _currentLayout = layout ?? SupportLayout.getDefaultLayoutByPlatform();
}
