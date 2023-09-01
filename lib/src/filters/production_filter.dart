import '../log_event.dart';
import '../log_filter.dart';

/// Prints all logs with `level >= Logger.level` even in production.
class ProductionFilter extends LogFilter {
  @override
  FilterResult shouldLog(LogEvent event) {
    return event.level.value >= level.value
        ? FilterResult.accept
        : FilterResult.deny;
  }
}
