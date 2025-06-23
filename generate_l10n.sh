#!/usr/bin/env bash
echo "start generating l10n ..."

flutter gen-l10n --arb-dir lib/shared/l10n \
  --template-arb-file intl_zh.arb \
  --output-localization-file app_localizations.dart \
  --output-class AppLocalizations

flutter gen-l10n --arb-dir lib/modules/dashboard/l10n \
  --template-arb-file intl_zh.arb \
  --output-localization-file dashboard_localizations.dart \
  --output-class DashboardLocalizations

flutter gen-l10n --arb-dir lib/modules/settings/l10n \
  --template-arb-file intl_zh.arb \
  --output-localization-file settings_localizations.dart \
  --output-class SettingsLocalizations

echo "generate l10n successfully!"