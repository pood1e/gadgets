import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_usecase.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_localizations.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_localizations_en.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_tip_l10n.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository.dart';

void main() {
  group('ClipboardTipL10n', () {
    final ClipboardLocalizations localizations = ClipboardLocalizationsEn();

    test('ValidationFailedException', () {
      expect(
        ClipboardTipL10n.getByCause(localizations, ValidationFailedException()),
        localizations.validationFailed,
      );
    });

    test('CannotOperationException', () {
      expect(
        ClipboardTipL10n.getByCause(localizations, CannotOperationException()),
        localizations.cannotOperate,
      );
    });

    test('ErrorMessage', () {
      expect(
        ClipboardTipL10n.getByCause(
          localizations,
          const ErrorMessage(code: 1, message: 'exceed limit'),
        ),
        localizations.error1,
      );
    });

    test('ClipboardApiException message', () {
      expect(
        ClipboardTipL10n.getByCause(
          localizations,
          ClipboardApiException(message: 'error'),
        ),
        'error',
      );
    });

    test('ClipboardApiException wrap ErrorMessage', () {
      expect(
        ClipboardTipL10n.getByCause(
          localizations,
          ClipboardApiException(
            message: 'error',
            detail: const ErrorMessage(code: 1, message: 'exceed limit'),
          ),
        ),
        localizations.error1,
      );
    });

    test('not null', () {
      expect(ClipboardTipL10n.getByCause(localizations, 'error'), 'error');
    });

    test('getByOperation', () {
      expect(
        ClipboardTipL10n.getByOperation(localizations, ClipboardOperation.copy),
        localizations.copy,
      );
      expect(
        ClipboardTipL10n.getByOperation(
          localizations,
          ClipboardOperation.clear,
        ),
        localizations.clear,
      );
      expect(
        ClipboardTipL10n.getByOperation(localizations, ClipboardOperation.scan),
        localizations.scan,
      );
      expect(
        ClipboardTipL10n.getByOperation(localizations, ClipboardOperation.add),
        localizations.add,
      );
      expect(
        ClipboardTipL10n.getByOperation(
          localizations,
          ClipboardOperation.remove,
        ),
        localizations.remove,
      );
    });
  });
}
