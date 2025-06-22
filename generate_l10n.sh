#!/usr/bin/env bash
echo "start generating l10n ..."

flutter gen-l10n --arb-dir lib/shared/l10n \
  --template-arb-file intl_zh.arb \
  --output-localization-file app_localizations.dart \
  --output-class AppLocalizations

echo "generate l10n successfully!"