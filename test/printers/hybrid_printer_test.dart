import 'package:logger/logger.dart';
import 'package:test/test.dart';

final realPrinter = SimplePrinter();

class TestLogPrinter extends LogPrinter {
  LogEvent? latestEvent;

  @override
  Object? log(Object? message, LogEvent event) {
    latestEvent = event;
    return realPrinter.log(message, event);
  }
}

void main() {
  var printerA = TestLogPrinter();
  var printerB = TestLogPrinter();
  var printerC = TestLogPrinter();

  var debugEvent = LogEvent(Level.debug, 'debug',
      error: 'blah', stackTrace: StackTrace.current);
  var infoEvent = LogEvent(Level.info, 'info',
      error: 'blah', stackTrace: StackTrace.current);
  var warningEvent = LogEvent(Level.warning, 'warning',
      error: 'blah', stackTrace: StackTrace.current);
  var errorEvent = LogEvent(Level.error, 'error',
      error: 'blah', stackTrace: StackTrace.current);

  var hybridPrinter = HybridPrinter(printerA, debug: printerB, error: printerC);
  test('uses wrapped printer by default', () {
    hybridPrinter.log(infoEvent.message, infoEvent);
    expect(printerA.latestEvent, equals(infoEvent));
  });

  test('forwards logs to correct logger', () {
    hybridPrinter.log(debugEvent.message, debugEvent);
    hybridPrinter.log(errorEvent.message, errorEvent);
    hybridPrinter.log(warningEvent.message, warningEvent);
    expect(printerA.latestEvent, equals(warningEvent));
    expect(printerB.latestEvent, equals(debugEvent));
    expect(printerC.latestEvent, equals(errorEvent));
  });
}
