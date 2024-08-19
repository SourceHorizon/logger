import '../date_time_format.dart';
import '../log_event.dart';
import '../log_level.dart';
import '../log_printer.dart';

/// Outputs a logfmt message:
/// ```
/// level=debug msg="hi there" time="2015-03-26T01:27:38-04:00" animal=walrus number=8 tag=usum
/// ```
class LogfmtPrinter extends LogPrinter {
  static final levelPrefixes = {
    Level.trace: 'trace',
    Level.debug: 'debug',
    Level.info: 'info',
    Level.warning: 'warning',
    Level.error: 'error',
    Level.fatal: 'fatal',
  };

  LogfmtPrinter({
    super.dateTimeFormat = DateTimeFormat.iso8601,
  });

  @override
  List<String> log(LogEvent event) {
    var output = StringBuffer('level=${levelPrefixes[event.level]}');
    var message = event.message;

    if (message is String) {
      output.write(' msg="$message"');
    } else if (message is Map) {
      for (var entry in message.entries) {
        if (entry.value is num) {
          output.write(' ${entry.key}=${entry.value}');
        } else {
          output.write(' ${entry.key}="${entry.value}"');
        }
      }
    }

    if (printTimestamp) {
      output.write(' time="${getTime(event.time)}"');
    }

    if (event.error != null) {
      output.write(' error="${event.error}"');
    }

    return [output.toString()];
  }
}
