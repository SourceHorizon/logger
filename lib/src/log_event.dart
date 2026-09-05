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
  }) : time = time ?? clock.now() {
    if (error != null && error is StackTrace) {
      throw ArgumentError('Error parameter cannot take a StackTrace!');
    } else if (level == Level.all) {
      throw ArgumentError('Log events cannot have Level.all');
      // ignore: deprecated_member_use_from_same_package
    } else if (level == Level.off || level == Level.nothing) {
      throw ArgumentError('Log events cannot have Level.off');
    }
  }
}
