import 'package:gadgets/modules/clipboard/domain/clipboard_message.dart';
import 'package:gadgets/modules/clipboard/domain/clipboard_usecase.dart';
import 'package:gadgets/modules/clipboard/l10n/clipboard_localizations.dart';
import 'package:gadgets/modules/clipboard/repositories/clipboard_repository.dart';

class ClipboardTipL10n {
  static String? getByCause(
    ClipboardLocalizations localization,
    dynamic cause,
  ) {
    if (cause is ValidationFailedException) {
      return localization.validationFailed;
    }
    if (cause is CannotOperationException) {
      return localization.cannotOperate;
    }
    if (cause is ErrorMessage) {
      return getByCode(localization, cause.code);
    }
    if (cause is ClipboardApiException) {
      if (cause.detail is ErrorMessage) {
        return getByCode(localization, (cause.detail as ErrorMessage).code);
      }
      return cause.message;
    }
    if (cause != null) {
      return cause.toString();
    }
    return null;
  }

  static String? getByCode(ClipboardLocalizations localization, int code) =>
      switch (code) {
        1 => localization.error1,
        2 => localization.error2,
        3 => localization.error3,
        _ => null,
      };

  static String getByOperation(
    ClipboardLocalizations localization,
    ClipboardOperation op,
  ) => switch (op) {
    ClipboardOperation.copy => localization.copy,
    ClipboardOperation.clear => localization.clear,
    ClipboardOperation.scan => localization.scan,
    ClipboardOperation.add => localization.add,
    ClipboardOperation.remove => localization.remove,
  };
}
