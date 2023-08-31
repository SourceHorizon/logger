import 'log_event.dart';

/// An abstract handler of log events.
///
/// A log printer creates and formats the output, which is then sent to
/// [LogOutput]. Every implementation has to use the [LogPrinter.log]
/// method to send the output.
///
/// You can implement a `LogPrinter` from scratch or extend [PrettyPrinter].
abstract class LogPrinter {
  Future<void> init() async {}

  /// Is called every time a new [LogEvent] is sent and handles printing or
  /// storing the message.
  List<String> log(LogEvent event);

  Future<void> destroy() async {}
}
