import 'log_event.dart';
import 'log_level.dart';
import 'logger.dart';

/// An abstract filter of log messages.
///
/// You can implement your own `LogFilter` or use [DevelopmentFilter].
/// Every implementation should consider [Logger.level].
abstract class LogFilter {
  late Logger logger;

  /// Shortcut getter for [Logger.level].
  Level get level => logger.level;

  Future<void> init() async {}

  /// Is called every time a new log message is sent and decides if
  /// it will be printed or canceled.
  ///
  /// Returns `true` if the message should be logged.
  FilterResult shouldLog(LogEvent event);

  Future<void> destroy() async {}
}

/// Describes the filter result of a log request.
enum FilterResult {
  accept,
  neutral,
  deny,
  ;
}
