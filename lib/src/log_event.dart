import 'log_level.dart';

class LogEvent {
  final Level level;
  final Object? message;
  final Object? error;
  final StackTrace? stackTrace;

  /// Time when this log was created.
  final DateTime time;

  LogEvent(
    this.level,
    this.message, {
    DateTime? time,
    this.error,
    this.stackTrace,
  }) : time = time ?? DateTime.now();

  LogEvent copyWith({
    Level? level,
    Object? message,
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return LogEvent(
      level ?? this.level,
      message ?? this.message,
      time: time ?? this.time,
      error: error ?? this.error,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}
