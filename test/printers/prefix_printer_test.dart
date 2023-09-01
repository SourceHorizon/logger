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
    var printer = PrefixPrinter();
    var actualLog = printer.log(infoEvent.message, infoEvent).toString();
    for (var logString in actualLog.split(printer.separator)) {
      expect(logString, contains('INFO'));
    }

    var debugLog = printer.log(debugEvent.message, debugEvent).toString();
    for (var logString in debugLog.split(printer.separator)) {
      expect(logString, contains('DEBUG'));
    }
  });

  test('can supply own prefixes', () {
    var printer = PrefixPrinter(debug: 'BLAH');
    var actualLog = printer.log(debugEvent.message, debugEvent).toString();
    for (var logString in actualLog.split(printer.separator)) {
      expect(logString, contains('BLAH'));
    }
  });

  test('pads to same length', () {
    const longPrefix = 'EXTRALONGPREFIX';
    const len = longPrefix.length;
    var printer = PrefixPrinter(debug: longPrefix);
    for (var event in allEvents) {
      var l1 = printer.log(event.message, event).toString();
      for (var logString in l1.split(printer.separator)) {
        expect(logString.substring(0, len), isNot(contains('[')));
      }
    }
  });

  test('uses global prefix', () {
    const prefix = 'GLOBAL PREFIX';
    var printer = PrefixPrinter(globalPrefix: prefix);
    for (var event in allEvents) {
      var l1 = printer.log(event.message, event).toString();
      for (var logString in l1.split(printer.separator)) {
        expect(logString, startsWith(prefix));
      }
    }
  });
}
