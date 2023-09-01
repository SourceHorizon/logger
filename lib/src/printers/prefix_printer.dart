import '../log_event.dart';
import '../log_level.dart';
import '../log_printer.dart';

/// A decorator for a [LogPrinter] that allows for the prepending of every
/// line in the log output with a string for the level of that log. For
/// example:
///
/// ```
/// PrefixPrinter(PrettyPrinter());
/// ```
///
/// Would prepend "DEBUG" to every line in a debug log. You can supply
/// parameters for a custom message for a specific log level.
class PrefixPrinter extends LogPrinter {
  final String separator;
  final String? globalPrefix;
  late Map<Level, String> _prefixMap;

  PrefixPrinter({
    this.separator = "\n",
    this.globalPrefix,
    String? debug,
    String? trace,
    @Deprecated('[verbose] is being deprecated in favor of [trace].') verbose,
    String? fatal,
    @Deprecated('[wtf] is being deprecated in favor of [fatal].') wtf,
    String? info,
    String? warning,
    String? error,
  }) {
    _prefixMap = {
      Level.debug: debug ?? 'DEBUG',
      Level.trace: trace ?? verbose ?? 'TRACE',
      Level.fatal: fatal ?? wtf ?? 'FATAL',
      Level.info: info ?? 'INFO',
      Level.warning: warning ?? 'WARNING',
      Level.error: error ?? 'ERROR',
    };

    var len = _longestPrefixLength();
    _prefixMap.forEach((k, v) => _prefixMap[k] = v.padLeft(len));
  }

  @override
  Object? log(Object? message, LogEvent event) {
    return message
        .toString()
        .split(separator)
        .map((s) => '${globalPrefix ?? _prefixMap[event.level]} $s')
        .join(separator);
  }

  int _longestPrefixLength() {
    compFunc(String a, String b) => a.length > b.length ? a : b;
    return _prefixMap.values.reduce(compFunc).length;
  }
}
