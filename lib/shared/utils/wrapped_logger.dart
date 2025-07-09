import 'package:logger/logger.dart';

class CustomPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final level = event.level.name.toUpperCase();
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level] ?? '';
    final time = DateTimeFormat.dateAndTime(DateTime.now());
    final message = event.message;
    final location = _getCallerLocation();

    final color =
        PrettyPrinter.defaultLevelColors[event.level] ?? const AnsiColor.none();

    final plain = '[$emoji$level][$time][$location]: $message';

    final logLine = color(plain);
    return [logLine];
  }

  String _getCallerLocation() {
    final stackTrace = StackTrace.current;
    final frames = stackTrace.toString().split('\n');

    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      if (!frame.contains('package:logger') &&
          !frame.contains('CustomPrinter') &&
          !frame.contains('LogPrinter')) {
        final match = RegExp(r'\((\S+\.dart):(\d+):(\d+)').firstMatch(frame);
        if (match != null) {
          final fullPath = match.group(1)!;
          final lineNumber = match.group(2)!;
          final columnNumber = match.group(3)!;
          return '$fullPath:$lineNumber:$columnNumber';
        }
      }
    }
    return 'Unknown';
  }
}

class WrappedLogger extends Logger {
  WrappedLogger() : super(printer: CustomPrinter());
}
