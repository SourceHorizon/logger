import 'dart:math';

import 'package:logger/logger.dart';
import 'package:test/test.dart';

typedef PrinterCallback = Object? Function(
  Level level,
  Object? message,
  Object? error,
  StackTrace? stackTrace,
);

class _AlwaysFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => true;
}

class _NeverFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

class _CallbackPrinter extends LogPrinter {
  final PrinterCallback callback;

  _CallbackPrinter(this.callback);

  @override
  Object? log(Object? message, LogEvent event) {
    return callback(
      event.level,
      message,
      event.error,
      event.stackTrace,
    );
  }
}

class _AsyncFilter extends LogFilter {
  final Duration delay;
  bool initialized = false;

  _AsyncFilter(this.delay);

  @override
  Future<void> init() async {
    await Future.delayed(delay);
    initialized = true;
  }

  @override
  bool shouldLog(LogEvent event) => false;
}

class _AsyncPrinter extends LogPrinter {
  final Duration delay;
  bool initialized = false;

  _AsyncPrinter(this.delay);

  @override
  Future<void> init() async {
    await Future.delayed(delay);
    initialized = true;
  }

  @override
  Object? log(Object? message, LogEvent event) => event.message.toString();
}

class _AsyncOutput extends LogOutput {
  final Duration delay;
  bool initialized = false;

  _AsyncOutput(this.delay);

  @override
  Future<void> init() async {
    await Future.delayed(delay);
    initialized = true;
  }

  @override
  void output(OutputEvent event) {
    // No-op.
  }
}

void main() {
  Level? printedLevel;
  Object? printedMessage;
  Object? printedError;
  StackTrace? printedStackTrace;
  var callbackPrinter = _CallbackPrinter((l, m, e, s) {
    printedLevel = l;
    printedMessage = m;
    printedError = e;
    printedStackTrace = s;
    return "";
  });

  setUp(() {
    printedLevel = null;
    printedMessage = null;
    printedError = null;
    printedStackTrace = null;
  });

  test('Logger.log', () {
    var logger = Logger(filter: _NeverFilter(), printers: [callbackPrinter]);
    logger.log(Level.debug, 'Some message');

    expect(printedMessage, null);

    logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);

    var levels = [
      Level.trace,
      Level.debug,
      Level.info,
      Level.warning,
      Level.error,
      Level.fatal,
    ];
    for (var level in levels) {
      var message = Random().nextInt(999999999).toString();
      logger.log(level, message);
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, null);
      expect(printedStackTrace, null);

      message = Random().nextInt(999999999).toString();
      logger.log(level, message, error: 'MyError');
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, 'MyError');
      expect(printedStackTrace, null);

      message = Random().nextInt(999999999).toString();
      var stackTrace = StackTrace.current;
      logger.log(level, message, error: 'MyError', stackTrace: stackTrace);
      expect(printedLevel, level);
      expect(printedMessage, message);
      expect(printedError, 'MyError');
      expect(printedStackTrace, stackTrace);
    }

    expect(() => logger.log(Level.trace, 'Test', error: StackTrace.current),
        throwsArgumentError);
    expect(() => logger.log(Level.off, 'Test'), throwsArgumentError);
    expect(() => logger.log(Level.all, 'Test'), throwsArgumentError);
  });

  test('Logger printer parameter', () {
    // ignore: deprecated_member_use_from_same_package
    var logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger.t('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.trace);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Multiple Loggers', () {
    var logger = Logger(level: Level.info, printers: [callbackPrinter]);
    var secondLogger = Logger(level: Level.debug, printers: [callbackPrinter]);

    logger.log(Level.debug, 'Test');
    expect(printedLevel, null);
    expect(printedMessage, null);
    expect(printedError, null);
    expect(printedStackTrace, null);

    secondLogger.log(Level.debug, 'Test');
    expect(printedLevel, Level.debug);
    expect(printedMessage, 'Test');
    expect(printedError, null);
    expect(printedStackTrace, null);
  });

  test('Logger.t', () {
    var logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);
    var stackTrace = StackTrace.current;
    logger.t('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.trace);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.d', () {
    var logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);
    var stackTrace = StackTrace.current;
    logger.d('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.debug);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.i', () {
    var logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);
    var stackTrace = StackTrace.current;
    logger.i('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.info);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.w', () {
    var logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);
    var stackTrace = StackTrace.current;
    logger.w('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.warning);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.e', () {
    var logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);
    var stackTrace = StackTrace.current;
    logger.e('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.error);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.f', () {
    var logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);
    var stackTrace = StackTrace.current;
    logger.f('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.fatal);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Deal with function messages', () {
    final heavyComputation = 'heavily computed very pretty Message';

    var logger = Logger(filter: _AlwaysFilter(), printers: [callbackPrinter]);
    logger.f(() => heavyComputation);
    expect(printedMessage, heavyComputation);
  });

  test('Setting log level above log level of message', () {
    printedMessage = null;
    var logger = Logger(
      filter: ProductionFilter(),
      printers: [callbackPrinter],
      level: Level.warning,
    );

    logger.d('This isn\'t logged');
    expect(printedMessage, isNull);

    logger.w('This is');
    expect(printedMessage, 'This is');
  });

  test('Setting log level', () {
    final initLevel = Level.warning;
    var logger = Logger(
      filter: ProductionFilter(),
      printers: [callbackPrinter],
      level: initLevel,
    );
    expect(logger.filter.level, initLevel);

    logger.level = Level.fatal;
    expect(logger.filter.level, Level.fatal);
  });

  test('Logger.close', () async {
    var logger = Logger();
    expect(logger.isClosed(), false);
    await logger.close();
    expect(logger.isClosed(), true);
  });

  test('Async Filter Initialization', () async {
    var comp = _AsyncFilter(const Duration(milliseconds: 100));
    var logger = Logger(
      filter: comp,
    );

    expect(comp.initialized, false);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(comp.initialized, false);
    await logger.init;
    expect(comp.initialized, true);
  });

  test('Async Printer Initialization', () async {
    var comp = _AsyncPrinter(const Duration(milliseconds: 100));
    var logger = Logger(
      printers: [comp],
    );

    expect(comp.initialized, false);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(comp.initialized, false);
    await logger.init;
    expect(comp.initialized, true);
  });

  test('Async Output Initialization', () async {
    var comp = _AsyncOutput(const Duration(milliseconds: 100));
    var logger = Logger(
      outputs: [comp],
    );

    expect(comp.initialized, false);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(comp.initialized, false);
    await logger.init;
    expect(comp.initialized, true);
  });

  test('Multi Printer', () {
    var logger = Logger(
      filter: _AlwaysFilter(),
      printers: [
        PrefixPrinter(globalPrefix: "GLOBAL"),
        PrettyPrinter(),
        callbackPrinter,
      ],
    );
    var stackTrace = StackTrace.current;
    logger.f('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.fatal);
    expect(printedMessage, contains('GLOBAL Test'));
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Multi Printer', () {
    var logger = Logger(
      filter: _AlwaysFilter(),
      printers: [
        PrefixPrinter(globalPrefix: "GLOBAL"),
        PrettyPrinter(),
        callbackPrinter,
      ],
    );
    var stackTrace = StackTrace.current;
    logger.f('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.fatal);
    expect(printedMessage, contains('GLOBAL Test'));
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Multi Outputs', () {
    final output1 = MemoryOutput(bufferSize: 2);
    final output2 = MemoryOutput(bufferSize: 2);

    var logger = Logger(
      filter: _AlwaysFilter(),
      printers: [SimplePrinter()],
      outputs: [
        output1,
        output2,
      ],
    );

    final String firstLog = "Test0";
    logger.log(Level.info, firstLog);

    expect(output1.buffer.length, 1);
    expect(output2.buffer.length, 1);
    expect(output1.buffer.elementAt(0), equals(output2.buffer.elementAt(0)));
    expect(output1.buffer.elementAt(0).output, contains(firstLog));

    final String secondLog = "Test1";
    logger.log(Level.info, secondLog);

    expect(output1.buffer.length, 2);
    expect(output2.buffer.length, 2);
    expect(output1.buffer.elementAt(0), equals(output2.buffer.elementAt(0)));
    expect(output1.buffer.elementAt(0).output, contains(firstLog));
    expect(output1.buffer.elementAt(1), equals(output2.buffer.elementAt(1)));
    expect(output1.buffer.elementAt(1).output, contains(secondLog));
  });

  test('Empty Printers is not allowed', () {
    expect(() => Logger(printers: []), throwsA(isA<AssertionError>()));
  });

  test('Empty Outputs is not allowed', () {
    expect(() => Logger(outputs: []), throwsA(isA<AssertionError>()));
  });
}
