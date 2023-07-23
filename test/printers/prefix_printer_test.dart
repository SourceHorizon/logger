import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  var debugEvent = LogEvent(Level.debug, 'debug',
      error: 'blah', stackTrace: StackTrace.current);
  var infoEvent = LogEvent(Level.info, 'info',
      error: 'blah', stackTrace: StackTrace.current);
  var warningEvent = LogEvent(Level.warning, 'warning',
      error: 'blah', stackTrace: StackTrace.current);
  var errorEvent = LogEvent(Level.error, 'debug',
      error: 'blah', stackTrace: StackTrace.current);
  var traceEvent = LogEvent(Level.trace, 'debug',
      error: 'blah', stackTrace: StackTrace.current);
  var fatalEvent = LogEvent(Level.fatal, 'debug',
      error: 'blah', stackTrace: StackTrace.current);

  var allEvents = [
    debugEvent,
    warningEvent,
    errorEvent,
    traceEvent,
    fatalEvent
  ];

  test('prefixes logs', () {
    var printer = PrefixPrinter(PrettyPrinter());
    var actualLog = printer.log(infoEvent);
    for (var logString in actualLog) {
      expect(logString, contains('INFO'));
    }

    var debugLog = printer.log(debugEvent);
    for (var logString in debugLog) {
      expect(logString, contains('DEBUG'));
    }
  });

  test('can supply own prefixes', () {
    var printer = PrefixPrinter(PrettyPrinter(), debug: 'BLAH');
    var actualLog = printer.log(debugEvent);
    for (var logString in actualLog) {
      expect(logString, contains('BLAH'));
    }
  });

  test('pads to same length', () {
    const longPrefix = 'EXTRALONGPREFIX';
    const len = longPrefix.length;
    var printer = PrefixPrinter(SimplePrinter(), debug: longPrefix);
    for (var event in allEvents) {
      var l1 = printer.log(event);
      for (var logString in l1) {
        expect(logString.substring(0, len), isNot(contains('[')));
      }
    }
  });
}
