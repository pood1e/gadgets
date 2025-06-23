import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/l10n/app_localizations_zh.dart';
import 'package:gadgets/shared/routing/routers.dart';

void main() {
  group('RouteDefineEnhancer Extension', () {
    test('translate success', () {
      // Arrange
      AppLocalizations l10n = AppLocalizationsZh();

      // Act && Assert
      expect(
        navigationRouteDefines.map((item) => item.translate(l10n)).length,
        navigationRouteDefines.length,
      );
    });

    test('goRoute success', () {
      // Arrange ignore

      // Act && Assert
      expect(
        navigationRouteDefines.map((item) => item.goRoute).length,
        navigationRouteDefines.length,
      );
    });
  });
}
