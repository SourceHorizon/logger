import 'log_event.dart';
import 'log_level.dart';
import 'logger.dart';

/// An abstract filter of log messages.
///
/// You can implement your own `LogFilter` or use [DevelopmentFilter].
/// Every implementation should consider [Logger.level].
abstract class LogFilter {
  Level? _level;

  // Still nullable for backwards compatibility.
  Level? get level => _level ?? Logger.level;

  set level(Level? value) => _level = value;

  Future<void> init() async {}

  /// Is called every time a new log message is sent and decides if
  /// it will be printed or canceled.
  ///
  /// Returns `true` if the message should be logged.
  bool shouldLog(LogEvent event);

  Future<void> destroy() async {}
}
