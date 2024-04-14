import 'dart:convert';

import 'log_event.dart';
import 'logger.dart';

/// An abstract handler of log events.
///
/// A log printer creates and formats the output, which is then sent to
/// [LogOutput]. Every implementation has to use the [LogPrinter.log]
/// method to send the output.
///
/// You can implement a `LogPrinter` from scratch or extend [PrettyPrinter].
abstract class LogPrinter {
  late Logger logger;

  Future<void> init() async {}

  /// Is called every time a new [LogEvent] is sent and handles printing or
  /// storing the message.
  List<String> log(LogEvent event);

  Future<void> destroy() async {}

  String stringifyMessage(Object? message) {
    if (message is String) return message;

    if (message is Map || message is Iterable) {
      return encodeJson(message);
    } else {
      return message.toString();
    }
  }

  String encodeJson(Object? message) {
    var encoder = JsonEncoder.withIndent('  ', (object) => object.toString());
    return encoder.convert(message);
  }
}
