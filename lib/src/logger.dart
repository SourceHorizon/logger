import 'filters/development_filter.dart';
import 'log_event.dart';
import 'log_filter.dart';
import 'log_level.dart';
import 'log_output.dart';
import 'log_printer.dart';
import 'output_event.dart';
import 'outputs/console_output.dart';
import 'printers/pretty_printer.dart';

typedef LogCallback = void Function(LogEvent event);

typedef OutputCallback = void Function(OutputEvent event);

/// Use instances of logger to send log messages to the [LogPrinter].
class Logger {
  /// The default logging level of new loggers.
  static Level defaultLevel = Level.trace;

  /// The current default implementation of log filter.
  static LogFilter Function() defaultFilter = () => DevelopmentFilter();

  /// The current default implementation of log printer.
  static List<LogPrinter> Function() defaultPrinters = () => [PrettyPrinter()];

  /// The current default implementation of log output.
  static List<LogOutput> Function() defaultOutputs = () => [ConsoleOutput()];

  static final Set<LogCallback> _globalLogCallbacks = {};

  static final Set<OutputCallback> _globalOutputCallbacks = {};

  final Set<LogCallback> _logCallbacks = {};

  final Set<OutputCallback> _outputCallbacks = {};

  late final Future<void> _initialization;

  /// All logs with levels below this level will be omitted.
  Level level;

  final LogFilter _filter;
  final List<LogPrinter> _printers;
  final List<LogOutput> _outputs;
  bool _active = true;

  /// Create a new instance of Logger.
  ///
  /// You can provide a custom [filter], [printers] and [outputs]. Otherwise the
  /// defaults: [PrettyPrinter], [DevelopmentFilter] and [ConsoleOutput] will be
  /// used.
  Logger({
    Level? level,
    LogFilter? filter,
    @Deprecated("Use [printers] instead.") LogPrinter? printer,
    List<LogPrinter>? printers,
    @Deprecated("Use [outputs] instead.") LogOutput? output,
    List<LogOutput>? outputs,
  })  : level = level ?? defaultLevel,
        _filter = filter ?? defaultFilter(),
        _printers =
            printer != null ? [printer] : (printers ?? defaultPrinters()),
        _outputs = output != null ? [output] : (outputs ?? defaultOutputs()) {
    assert(_printers.isNotEmpty, "Printers cannot be empty");
    assert(_outputs.isNotEmpty, "Outputs cannot be empty");

    List<Future> initFutures = [];
    initFutures.add(_filter.init());
    _filter.logger = this;
    for (var e in _printers) {
      e.logger = this;
      initFutures.add(e.init());
    }
    for (var e in _outputs) {
      e.logger = this;
      initFutures.add(e.init());
    }
    _initialization = Future.wait(initFutures);
  }

  /// Future indicating if the initialization of the
  /// logger components (filter, printer and output) has been finished.
  ///
  /// This is only necessary if your [LogFilter]/[LogPrinter]/[LogOutput]
  /// uses `async` in their `init` method.
  Future<void> get init => _initialization;

  LogFilter get filter => _filter;

  List<LogPrinter> get printer => List.unmodifiable(_printers);

  List<LogOutput> get output => List.unmodifiable(_outputs);

  /// Logs a message at level [Level.trace].
  ///
  /// {@macro log.parameters}
  void t(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(Level.trace, message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Logs a message at level [Level.debug].
  ///
  /// {@macro log.parameters}
  void d(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(Level.debug, message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Logs a message at level [Level.info].
  ///
  /// {@macro log.parameters}
  void i(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(Level.info, message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Logs a message at level [Level.warning].
  ///
  /// {@macro log.parameters}
  void w(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(Level.warning, message,
        time: time, error: error, stackTrace: stackTrace);
  }

  /// Logs a message at level [Level.error].
  ///
  /// {@macro log.parameters}
  void e(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(Level.error, message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Logs a message at level [Level.fatal].
  ///
  /// {@macro log.parameters}
  void f(
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(Level.fatal, message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Logs a message with [level].
  ///
  /// {@template log.parameters}
  /// [message] can be a [String], [Iterable], [Map] or even a [Function]
  /// to lazily evaluate the log statement.
  ///
  /// In case no [time] is provided, it defaults to [DateTime.now()].
  /// {@endtemplate}
  void log(
    Level level,
    Object? message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_active) {
      throw ArgumentError('Logger has already been closed.');
    } else if (error != null && error is StackTrace) {
      throw ArgumentError('Error parameter cannot take a StackTrace!');
    } else if (level == Level.all) {
      throw ArgumentError('Log events cannot have Level.all');
    } else if (level == Level.off) {
      throw ArgumentError('Log events cannot have Level.off');
    }

    var logEvent = LogEvent(
      level,
      message,
      time: time,
      error: error,
      stackTrace: stackTrace,
    );

    var collectedLogCallbacks = [..._logCallbacks, ..._globalLogCallbacks];
    for (var callback in collectedLogCallbacks) {
      callback(logEvent);
    }

    if (_filter.shouldLog(logEvent)) {
      if (message is Function) {
        logEvent = logEvent.copyWith(message: message());
      }

      Object? output = logEvent.message;
      for (var p in _printers) {
        output = p.log(output, logEvent);
      }
      String finalOutput = output.toString();

      if (finalOutput.isNotEmpty) {
        var outputEvent = OutputEvent(logEvent, finalOutput);
        // Issues with log output should NOT influence
        // the main software behavior.
        try {
          var collectedOutputCallbacks = [
            ..._outputCallbacks,
            ..._globalOutputCallbacks,
          ];
          for (var callback in collectedOutputCallbacks) {
            callback(outputEvent);
          }

          for (var output in _outputs) {
            output.output(outputEvent);
          }
        } catch (e, s) {
          print(e);
          print(s);
        }
      }
    }
  }

  bool isClosed() {
    return !_active;
  }

  /// Closes the logger and releases all resources.
  Future<void> close() async {
    _active = false;
    await _filter.destroy();
    await Future.wait(_printers.map((e) => e.destroy()));
    await Future.wait(_outputs.map((e) => e.destroy()));
  }

  /// Register a [LogCallback] which is called for each new [LogEvent].
  void addLogListener(LogCallback callback) {
    _logCallbacks.add(callback);
  }

  /// Removes a [LogCallback] which was previously registered.
  ///
  /// Returns whether the callback was successfully removed.
  bool removeLogListener(LogCallback callback) {
    return _logCallbacks.remove(callback);
  }

  /// Register an [OutputCallback] which is called for each new [OutputEvent].
  void addOutputListener(OutputCallback callback) {
    _outputCallbacks.add(callback);
  }

  /// Removes a [OutputCallback] which was previously registered.
  ///
  /// Returns whether the callback was successfully removed.
  bool removeOutputListener(OutputCallback callback) {
    return _outputCallbacks.remove(callback);
  }

  /// Register a global [LogCallback] which is called for each new [LogEvent] on each logger.
  static void addGlobalLogListener(LogCallback callback) {
    _globalLogCallbacks.add(callback);
  }

  /// Removes a global [LogCallback] which was previously registered.
  ///
  /// Returns whether the callback was successfully removed.
  static bool removeGlobalLogListener(LogCallback callback) {
    return _globalLogCallbacks.remove(callback);
  }

  /// Register a global [OutputCallback] which is called for each new [OutputEvent] on each logger.
  static void addGlobalOutputListener(OutputCallback callback) {
    _globalOutputCallbacks.add(callback);
  }

  /// Removes a global [OutputCallback] which was previously registered.
  ///
  /// Returns whether the callback was successfully removed.
  static bool removeGlobalOutputListener(OutputCallback callback) {
    return _globalOutputCallbacks.remove(callback);
  }
}
