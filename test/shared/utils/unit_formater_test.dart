import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';
import 'package:gadgets/shared/l10n/app_localizations_en.dart';
import 'package:gadgets/shared/utils/unit_formater.dart';

void main() {
  test('duration format', () {
    const duration = Duration(days: 1, hours: 2, minutes: 3, seconds: 4);
    AppLocalizations appLocalizations = AppLocalizationsEn();
    final result = formatDurationLocalized(duration, appLocalizations);
    expect(result, '1d,2h,3m,4s');
  });

  test('data size format', () {
    const bytes = 1024 * 1024;
    final result = formatDataSize(bytes);
    expect(result, '1 MB');
  });
}
