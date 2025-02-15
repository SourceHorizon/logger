import 'dart:convert';

import '../ansi_color.dart';
import '../date_time_format.dart';
import '../log_event.dart';
import '../log_level.dart';
import '../log_printer.dart';

/// Outputs simple log messages:
/// ```
/// [E] Log message  ERROR: Error info
/// ```
class SimplePrinter extends LogPrinter {
  static final levelPrefixes = {
    Level.trace: '[T]',
    Level.debug: '[D]',
    Level.info: '[I]',
    Level.warning: '[W]',
    Level.error: '[E]',
    Level.fatal: '[FATAL]',
  };

  static final levelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  final bool colors;

  SimplePrinter({
    super.dateTimeFormat = DateTimeFormat.iso8601,
    this.colors = true,
  });

  @override
  List<String> log(LogEvent event) {
    var messageStr = stringifyMessage(event.message);
    var errorStr = event.error != null ? '  ERROR: ${event.error}' : '';
    var timeStr = printTimestamp ? 'TIME: ${getTime(event.time)}' : '';
    return ['${_labelFor(event.level)} $timeStr $messageStr$errorStr'];
  }

  String _labelFor(Level level) {
    var prefix = levelPrefixes[level]!;
    var color = levelColors[level]!;

    return colors ? color(prefix) : prefix;
  }

  @override
  String encodeJson(Object? message) {
    var encoder = const JsonEncoder.withIndent(null);
    return encoder.convert(message);
  }
}
