import 'log_event.dart';
import 'log_level.dart';

class OutputEvent {
  final String output;
  final LogEvent origin;

  Level get level => origin.level;

  OutputEvent(this.origin, this.output);
}
