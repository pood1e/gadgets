import 'package:flutter/widgets.dart';

class L10nViewModel {
  final Iterable<Locale> supportedLocales;
  final Locale? locale;

  L10nViewModel({Iterable<Locale>? supportedLocales, this.locale})
    : supportedLocales = supportedLocales ?? const [Locale('zh'), Locale('en')];
}
