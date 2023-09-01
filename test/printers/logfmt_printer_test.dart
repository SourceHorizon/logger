import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  var printer = LogfmtPrinter();

  test('includes level', () {
    var logEvent = LogEvent(
      Level.debug,
      'some message',
      error: Exception('boom'),
      stackTrace: StackTrace.current,
    );
    expect(
      printer.log(logEvent.message, logEvent),
      contains('level=debug'),
    );
  });

  test('with a string message includes a msg key', () {
    var logEvent = LogEvent(
      Level.debug,
      'some message',
      error: Exception('boom'),
      stackTrace: StackTrace.current,
    );
    expect(
      printer.log(logEvent.message, logEvent),
      contains('msg="some message"'),
    );
  });

  test('includes random key=value pairs', () {
    var logEvent = LogEvent(
      Level.debug,
      {'a': 123, 'foo': 'bar baz'},
      error: Exception('boom'),
      stackTrace: StackTrace.current,
    );
    var output = printer.log(logEvent.message, logEvent);

    expect(output, contains('a=123'));
    expect(output, contains('foo="bar baz"'));
  });

  test('handles an error/exception', () {
    var logEvent = LogEvent(
      Level.debug,
      'some message',
      error: Exception('boom'),
      stackTrace: StackTrace.current,
    );
    var output = printer.log(logEvent.message, logEvent);
    expect(output, contains('error="Exception: boom"'));

    var logEvent2 = LogEvent(
      Level.debug,
      'some message',
    );
    output = printer.log(logEvent2.message, logEvent2);
    expect(output, isNot(contains('error=')));
  });

  test('handles a stacktrace', () {}, skip: 'TODO');
}
