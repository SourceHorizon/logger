import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

typedef PrinterCallback = List<String> Function(
  Level level,
  dynamic message,
  Object? error,
  StackTrace? stackTrace,
);

/// Filter that logs all events and also preserves the last event.
class _EventPreservingFilter extends LogFilter {
  LogEvent? lastEvent;
  DateTime? lastEventTime;

  @override
  bool shouldLog(LogEvent event) {
    lastEventTime = clock.now();
    lastEvent = event;
    return true;
  }
}

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
  List<String> log(LogEvent event) {
    return callback(
      event.level,
      event.message,
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
  List<String> log(LogEvent event) => [event.message.toString()];
}

/// Printer that captures the time of the last event it printed.
class _TimedLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    // time is formatted via toString to avoid adding a dependency
    // on intl
    return ['${event.time.toString()} | ${event.message}'];
  }
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

/// Test class for the lazy-initialization of variables.
class LazyLogger {
  static bool? printed;
  static final filter = ProductionFilter();
  static final printer = _CallbackPrinter((l, m, e, s) {
    printed = true;
    return [];
  });
  static final logger = Logger(filter: filter, printer: printer);
}

void main() {
  Level? printedLevel;
  dynamic printedMessage;
  dynamic printedError;
  StackTrace? printedStackTrace;
  var callbackPrinter = _CallbackPrinter((l, m, e, s) {
    printedLevel = l;
    printedMessage = m;
    printedError = e;
    printedStackTrace = s;
    return [];
  });

  setUp(() {
    printedLevel = null;
    printedMessage = null;
    printedError = null;
    printedStackTrace = null;
  });

  test('Logger.log', () {
    var logger = Logger(filter: _NeverFilter(), printer: callbackPrinter);
    logger.log(Level.debug, 'Some message');

    expect(printedMessage, null);

    logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);

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

  test('Multiple Loggers', () {
    var logger = Logger(level: Level.info, printer: callbackPrinter);
    var secondLogger = Logger(level: Level.debug, printer: callbackPrinter);

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
    var logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger.t('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.trace);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.d', () {
    var logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger.d('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.debug);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.i', () {
    var logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger.i('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.info);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.w', () {
    var logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger.w('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.warning);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.e', () {
    var logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger.e('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.error);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('Logger.f', () {
    var logger = Logger(filter: _AlwaysFilter(), printer: callbackPrinter);
    var stackTrace = StackTrace.current;
    logger.f('Test', error: 'Error', stackTrace: stackTrace);
    expect(printedLevel, Level.fatal);
    expect(printedMessage, 'Test');
    expect(printedError, 'Error');
    expect(printedStackTrace, stackTrace);
  });

  test('setting log level above log level of message', () {
    printedMessage = null;
    var logger = Logger(
      filter: ProductionFilter(),
      printer: callbackPrinter,
      level: Level.warning,
    );

    logger.d('This isn\'t logged');
    expect(printedMessage, isNull);

    logger.w('This is');
    expect(printedMessage, 'This is');
  });

  test('Setting filter Levels', () {
    var filter = ProductionFilter();
    expect(filter.level, Logger.level);

    final initLevel = Level.warning;
    // ignore: unused_local_variable
    var logger = Logger(
      filter: filter,
      printer: callbackPrinter,
      level: initLevel,
    );
    expect(filter.level, initLevel);

    filter.level = Level.fatal;
    expect(filter.level, Level.fatal);
  });

  test('Logger.close', () async {
    var logger = Logger();
    expect(logger.isClosed(), false);
    await logger.close();
    expect(logger.isClosed(), true);
  });

  test('Lazy Logger Initialization', () {
    expect(LazyLogger.printed, isNull);
    LazyLogger.filter.level = Level.warning;
    LazyLogger.logger.i("This is an info message and should not show");
    expect(LazyLogger.printed, isNull);
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
      printer: comp,
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
      output: comp,
    );

    expect(comp.initialized, false);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(comp.initialized, false);
    await logger.init;
    expect(comp.initialized, true);
  });

  test(
    'Events logged inside of different zones report its clock time by default',
    () async {
      const elapseDuration = Duration(milliseconds: 25);

      final filter = _EventPreservingFilter();
      final printer = _TimedLogPrinter();
      final logger = Logger(filter: filter, printer: printer);

      var eventIndex = 1;

      logger.d("Logging with a default fake_async zone clock:");
      // regular fake_async invocation where clock is automatically injected
      // into the zone with the current real time
      fakeAsync((async) {
        for (eventIndex = 1; eventIndex <= 5; eventIndex++) {
          async.elapse(elapseDuration);
          logger.i('\tEvent $eventIndex, now: ${clock.now()}');
          expect(filter.lastEvent?.time, clock.now());
        }
      });

      logger.d("Logging with a regular zone clock:");
      for (eventIndex = 1; eventIndex <= 5; eventIndex++) {
        await Future.delayed(elapseDuration);
        final timestamp = DateTime.now();

        // do not pass `time: timestamp` here since we want to verify
        // default event time behavior
        logger.i('\tEvent $eventIndex, now: ${DateTime.now()}');

        // there is no way to capture the exact time of created event, but we
        // can be sure that it is after the time right before logging and
        // before the time of printer work
        expect(timestamp.isBefore(filter.lastEvent!.time), isTrue);
        expect(filter.lastEventTime?.isAfter(timestamp), isTrue);
      }

      logger.d("Logging with a fixed initial time zone clock:");
      // now provide initialTime manually so that the clock starts at a fixed
      // point in the pasts
      fakeAsync(
        (async) {
          for (eventIndex = 1; eventIndex <= 5; eventIndex++) {
            async.elapse(elapseDuration);
            logger.i('\tEvent $eventIndex, now: ${clock.now()}');
            expect(filter.lastEvent?.time, clock.now());
          }
        },
        initialTime: DateTime.fromMicrosecondsSinceEpoch(0),
      );
    },
  );
}
