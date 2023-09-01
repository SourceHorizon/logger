import 'package:logger/logger.dart';
import 'package:test/test.dart';

const ansiEscapeLiteral = '\x1B';

void main() {
  var event = LogEvent(
    Level.trace,
    'some message',
    error: 'some error',
    stackTrace: StackTrace.current,
  );

  var plainPrinter = SimplePrinter(colors: false, printTime: false);

  test('represent event on a single line (ignoring stacktrace)', () {
    var outputs = plainPrinter.log(event.message, event);

    expect(outputs, isNot(contains("\n")));
    expect(outputs, '[T]  some message  ERROR: some error');
  });

  group('color', () {
    test('print color', () {
      // `useColor` is detected but here we override it because we want to print
      // the ANSI control characters regardless for the test.
      var printer = SimplePrinter(colors: true);

      expect(printer.log(event.message, event), contains(ansiEscapeLiteral));
    });

    test('toggle color', () {
      var printer = SimplePrinter(colors: false);

      expect(printer.log(event.message, event),
          isNot(contains(ansiEscapeLiteral)));
    });
  });

  test('print time', () {
    var printer = SimplePrinter(printTime: true);

    expect(printer.log(event.message, event), contains('TIME'));
  });

  test('does not print time', () {
    var printer = SimplePrinter(printTime: false);

    expect(printer.log(event.message, event), isNot(contains('TIME')));
  });

  test('omits error when null', () {
    var withoutError = LogEvent(
      Level.debug,
      'some message',
      error: null,
      stackTrace: StackTrace.current,
    );
    var outputs = SimplePrinter().log(withoutError.message, withoutError);

    expect(outputs, isNot(contains('ERROR')));
  });

  test('deal with Map type message', () {
    var withMap = LogEvent(
      Level.debug,
      plainPrinter.stringifyMessage({'foo': 123}),
      error: 'some error',
      stackTrace: StackTrace.current,
    );

    expect(
      plainPrinter.log(withMap.message, withMap),
      '[D]  {"foo":123}  ERROR: some error',
    );
  });

  test('deal with Iterable type message', () {
    var withIterable = LogEvent(
      Level.debug,
      plainPrinter.stringifyMessage([1, 2, 3, 4]),
      error: 'some error',
      stackTrace: StackTrace.current,
    );

    expect(
      plainPrinter.log(withIterable.message, withIterable),
      '[D]  [1,2,3,4]  ERROR: some error',
    );
  });
}
