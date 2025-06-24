import 'package:flutter/widgets.dart';
import 'package:gadgets/shared/routing/routers.dart';

class CurrentRouteViewModel extends ChangeNotifier {
  RouteDefine _current;

  RouteDefine get current => _current;

  CurrentRouteViewModel(this._current);

  void updateRoute(RouteDefine define) {
    if (_current != define) {
      _current = define;
      notifyListeners();
    }
  }

  bool isRoot() => _current.route.path == '/';
}
