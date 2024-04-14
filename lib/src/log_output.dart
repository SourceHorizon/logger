import 'dart:async';

import 'logger.dart';
import 'output_event.dart';

/// Log output receives a [OutputEvent] from [LogPrinter] and sends it to the
/// desired destination.
///
/// This can be an output stream, a file or a network target. [LogOutput] may
/// cache multiple log messages.
abstract class LogOutput {
  late Logger logger;

  Future<void> init() async {}

  void output(OutputEvent event);

  Future<void> destroy() async {}
}
