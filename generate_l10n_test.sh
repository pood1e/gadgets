#!/usr/bin/env bash
echo "start generating l10n ..."

flutter gen-l10n --arb-dir test/l10n \
  --template-arb-file intl_zh.arb \
  --output-localization-file test_localizations.dart \
  --output-class TestLocalizations

echo "generate l10n successfully!"