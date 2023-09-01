import '../log_event.dart';
import '../log_filter.dart';

/// Prints all logs with `level >= Logger.level` while in development mode (eg
/// when `assert`s are evaluated, Flutter calls this debug mode).
///
/// In release mode ALL logs are omitted.
class DevelopmentFilter extends LogFilter {
  @override
  FilterResult shouldLog(LogEvent event) {
    var shouldLog = false;
    assert(() {
      if (event.level.value >= level.value) {
        shouldLog = true;
      }
      return true;
    }());
    return shouldLog ? FilterResult.accept : FilterResult.deny;
  }
}
