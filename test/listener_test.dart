import 'package:logger/logger.dart';
import 'package:test/test.dart';

import 'logger_test.dart';

class NoOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // No-op.
  }
}

void main() {
  group("Local", () {
    LogEvent? loggedLogEvent;
    logCallback(LogEvent event) {
      loggedLogEvent = event;
    }

    OutputEvent? loggedOutputEvent;
    outputCallback(OutputEvent event) {
      loggedOutputEvent = event;
    }

    test('LogListener', () {
      var stackTrace = StackTrace.current;

      var logger = Logger(filter: NeverFilter(), output: NoOutput());
      logger.addLogListener(logCallback);
      logger.i('Test', error: 'Error', stackTrace: stackTrace);

      expect(loggedLogEvent?.level, Level.info);
      expect(loggedLogEvent?.message, 'Test');
      expect(loggedLogEvent?.error, 'Error');
      expect(loggedLogEvent?.stackTrace, stackTrace);

      logger.removeLogListener(logCallback);
      logger.i('Test2');

      // event stays the same
      expect(loggedLogEvent?.level, Level.info);
      expect(loggedLogEvent?.message, 'Test');
      expect(loggedLogEvent?.error, 'Error');
      expect(loggedLogEvent?.stackTrace, stackTrace);
    });

    test('OutputListener', () {
      var stackTrace = StackTrace.current;

      var logger = Logger(filter: AlwaysFilter(), output: NoOutput());
      logger.addOutputListener(outputCallback);
      logger.i('Test', error: 'Error', stackTrace: stackTrace);

      expect(loggedOutputEvent?.origin.level, Level.info);
      expect(loggedOutputEvent?.origin.message, 'Test');
      expect(loggedOutputEvent?.origin.error, 'Error');
      expect(loggedOutputEvent?.origin.stackTrace, stackTrace);

      logger.removeOutputListener(outputCallback);
      logger.i('Test2');

      // event stays the same
      expect(loggedOutputEvent?.origin.level, Level.info);
      expect(loggedOutputEvent?.origin.message, 'Test');
      expect(loggedOutputEvent?.origin.error, 'Error');
      expect(loggedOutputEvent?.origin.stackTrace, stackTrace);
    });

    test('OutputListener Filter', () {
      var stackTrace = StackTrace.current;
      OutputEvent? loggedEvent;
      callback(OutputEvent event) {
        loggedEvent = event;
      }

      var logger = Logger(filter: NeverFilter(), output: NoOutput());
      logger.addOutputListener(callback);
      logger.i('Test', error: 'Error', stackTrace: stackTrace);

      expect(loggedEvent, isNull);

      logger.close();
      logger = Logger(filter: AlwaysFilter(), output: NoOutput());
      logger.addOutputListener(callback);

      logger.i('Test', error: 'Error', stackTrace: stackTrace);

      expect(loggedEvent?.origin.level, Level.info);
      expect(loggedEvent?.origin.message, 'Test');
      expect(loggedEvent?.origin.error, 'Error');
      expect(loggedEvent?.origin.stackTrace, stackTrace);

      logger.removeOutputListener(callback);
      logger.i('Test2');

      // event stays the same
      expect(loggedEvent?.origin.level, Level.info);
      expect(loggedEvent?.origin.message, 'Test');
      expect(loggedEvent?.origin.error, 'Error');
      expect(loggedEvent?.origin.stackTrace, stackTrace);
    });
  });

  group("Global", () {
    LogEvent? localEvent;
    localCallback(LogEvent event) {
      localEvent = event;
    }

    LogEvent? globalEvent;
    globalCallback(LogEvent event) {
      globalEvent = event;
    }

    OutputEvent? localOutputEvent;
    localOutputCallback(OutputEvent event) {
      localOutputEvent = event;
    }

    OutputEvent? globalOutputEvent;
    globalOutputCallback(OutputEvent event) {
      globalOutputEvent = event;
    }

    setUp(() {
      Logger.addGlobalLogListener(globalCallback);
      Logger.addGlobalOutputListener(globalOutputCallback);
    });

    tearDown(() {
      Logger.removeGlobalLogListener(globalCallback);
      localEvent = null;
      globalEvent = null;

      Logger.removeGlobalOutputListener(globalOutputCallback);
      localOutputEvent = null;
      globalOutputEvent = null;
    });

    test(' LogListener', () {
      var logger = Logger(filter: NeverFilter(), output: NoOutput());
      var secondLogger = Logger(filter: NeverFilter(), output: NoOutput());

      secondLogger.addLogListener(localCallback);

      logger.i('Test');
      expect(globalEvent, isNotNull);
      expect(localEvent, isNull);

      secondLogger.i('Test2');
      expect(globalEvent?.message, 'Test2');
      expect(localEvent?.message, 'Test2');

      Logger.removeGlobalLogListener(globalCallback);
      logger.i('Test3');

      // event stays the same
      expect(globalEvent?.message, 'Test2');
    });

    test(' OutputListener', () {
      var logger = Logger(filter: AlwaysFilter(), output: NoOutput());
      var secondLogger = Logger(filter: AlwaysFilter(), output: NoOutput());

      secondLogger.addOutputListener(localOutputCallback);

      logger.i('Test');
      expect(globalOutputEvent, isNotNull);
      expect(localOutputEvent, isNull);

      secondLogger.i('Test2');
      expect(globalOutputEvent?.origin.message, 'Test2');
      expect(localOutputEvent?.origin.message, 'Test2');

      Logger.removeGlobalOutputListener(globalOutputCallback);
      logger.i('Test3');

      // event stays the same
      expect(globalOutputEvent?.origin.message, 'Test2');
    });
  });
}
