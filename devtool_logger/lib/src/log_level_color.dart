import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// Provides a consistent [Color] mapping for each [Level].
///
/// Centralizes level-to-color logic so every widget uses the same
/// palette without duplicating switch expressions.
extension LevelColorExtension on Level {
  /// The display color associated with this log level.
  Color get color {
    return switch (this) {
      Level.trace => Colors.blueGrey,
      Level.debug => Colors.cyan,
      Level.info => Colors.green,
      Level.warning => Colors.orange,
      Level.error => Colors.red,
      Level.fatal => Colors.deepPurple,
      _ => Colors.grey,
    };
  }
}

/// Provides a user-facing label for each [Level].
///
/// Uses the names shown in the UI reference (e.g. "Verbose" for [Level.trace],
/// "WTF" for [Level.fatal]) to match the DevTools-style toolbar chips.
extension LevelLabelExtension on Level {
  /// The human-readable label for this log level.
  String get label {
    return switch (this) {
      Level.all => 'ALL',
      Level.trace => 'Trace',
      Level.debug => 'Debug',
      Level.info => 'Info',
      Level.warning => 'Warning',
      Level.error => 'Error',
      Level.fatal => 'Fatal',
      Level.off => 'OFF',
      _ => name.toUpperCase(),
    };
  }
}
