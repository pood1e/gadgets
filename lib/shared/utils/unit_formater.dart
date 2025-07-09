import 'package:filesize/filesize.dart';
import 'package:gadgets/shared/l10n/app_localizations.dart';

String formatDurationLocalized(Duration duration, AppLocalizations l10n) {
  List<String> parts = [];

  int days = duration.inDays;
  int hours = duration.inHours % 24;
  int minutes = duration.inMinutes % 60;
  int seconds = duration.inSeconds % 60;

  if (days > 0) parts.add('$days${l10n.timeunit_day}');
  if (hours > 0) parts.add('$hours${l10n.timeunit_hour}');
  if (minutes > 0) parts.add('$minutes${l10n.timeunit_minute}');
  if (seconds > 0) parts.add('$seconds${l10n.timeunit_second}');

  return parts.join(l10n.timeunit_splitter);
}

String formatDataSize(int bytes) => filesize(bytes);