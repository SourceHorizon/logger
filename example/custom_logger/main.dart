import 'dart:math';
import 'package:logger/logger.dart';

/// Custom logger implementation that supports tags and randomly masked messages to demo
/// tightened custom subtype messages and event transformers when paired with custom
/// printer or output extended implementations
var logger = CustomLogger(
  printer: _ExtendedPrinter(),
  eventTransformer: (event) {
    final e = event.message as CustomMessage;
    return _ExtendedLogEvent.fromLogEvent(
      event: event,
      tag: e.tag,
      shouldMask: Random().nextBool(),
    );
  },
);

void main() {
  logger.d(CustomMessage(
      tag: "CustomTag", message: "custom log message implementation"));
}

/// [CustomLogger] enforces [d] to have a [CustomMessage] type
class CustomLogger extends Logger {
  CustomLogger({
    LogFilter? filter,
    LogPrinter? printer,
    LogOutput? output,
    Level? level,
    EventTransformerCallback? eventTransformer,
  }) : super(
          filter: filter,
          printer: printer,
          output: output,
          level: level,
          eventTransformer: eventTransformer,
        );

  @override
  void d(covariant CustomMessage message,
      {DateTime? time, Object? error, StackTrace? stackTrace}) {
    super.d(message, time: time, error: error, stackTrace: stackTrace);
  }
}

/// [CustomMessage] to enforce a consistent message type in your [CustomLogger] calls
class CustomMessage {
  final String tag;
  final String message;

  CustomMessage({required this.tag, required this.message});
}

/// Custom [LogEvent]
class _ExtendedLogEvent extends LogEvent {
  final String tag;
  final bool shouldMask;

  String _message;

  @override
  String get message => _message;

  _ExtendedLogEvent(
    Level level,
    String message, {
    super.error,
    super.stackTrace,
    super.time,
    required this.tag,
    required this.shouldMask,
  })  : _message = message,
        super(level, message);

  factory _ExtendedLogEvent.fromLogEvent({
    required LogEvent event,
    required String tag,
    required bool shouldMask,
  }) {
    final m = event.message as CustomMessage;
    return _ExtendedLogEvent(
      event.level,
      m.message,
      error: event.error,
      stackTrace: event.stackTrace,
      time: event.time,
      tag: tag,
      shouldMask: shouldMask,
    );
  }
}

/// Custom [LogPrinter]
class _ExtendedPrinter extends LogPrinter {
  String? lastTagField;
  bool? lastShouldMaskField;

  @override
  List<String> log(LogEvent event) {
    final _ExtendedLogEvent e = event as _ExtendedLogEvent;
    lastTagField = e.tag;
    lastShouldMaskField = e.shouldMask;
    return [
      "TAG: [${e.tag.toString()}]",
      e.shouldMask
          ? "*** MESSAGE IS MASKED RANDOMLY ***"
          : e.message.toString(),
    ];
  }
}
