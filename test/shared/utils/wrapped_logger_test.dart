import 'package:flutter_test/flutter_test.dart';
import 'package:gadgets/shared/utils/wrapped_logger.dart';
import 'package:logger/logger.dart';

void main() {
  test('wrapped logger', () {
    final event = LogEvent(Level.info, 'Test-Message');
    final logger = CustomPrinter();

    List<String> logOut = logger.log(event);

    expect(logOut.length, 1);
    expect(logOut[0], contains('INFO'));
    expect(logOut[0], contains('Test-Message'));
  });
}
