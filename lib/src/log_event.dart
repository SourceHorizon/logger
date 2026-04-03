import 'package:clock/clock.dart';

import 'log_level.dart';

class LogEvent {
  final Level level;
  final dynamic message;
  final Object? error;
  final StackTrace? stackTrace;

  /// Time when this log was created.
  ///
  /// If not provided, the current time will be used.
  final DateTime time;

  LogEvent(
    this.level,
    this.message, {
    DateTime? time,
    this.error,
    this.stackTrace,
  }) : time = time ?? clock.now();

  factory LogEvent.fromJson(Map<String, dynamic> json) {
    return LogEvent(
      Level.values.firstWhere((e) => e.name == json['level']),
      json['message'],
      time: DateTime.fromMillisecondsSinceEpoch(json['time']),
      error: json['error'],
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'time': time.millisecondsSinceEpoch,
      if (error != null) 'error': Error.safeToString(error),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
  }
}
