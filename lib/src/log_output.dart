import 'dart:async';

import 'output_event.dart';

/// Log output receives a [OutputEvent] from [LogPrinter] and sends it to the
/// desired destination.
///
/// This can be an output stream, a file or a network target. [LogOutput] may
/// cache multiple log messages.
abstract class LogOutput {
  Future<void> init() async {}

  void output(OutputEvent event);

  Future<void> destroy() async {}
}
