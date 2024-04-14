import 'dart:convert';
import 'dart:math';

import '../ansi_color.dart';
import '../date_time_format.dart';
import '../log_event.dart';
import '../log_level.dart';
import '../log_printer.dart';

/// Default implementation of [LogPrinter].
///
/// Output looks like this:
/// ```
/// ┌──────────────────────────
/// │ Error info
/// ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
/// │ Method stack history
/// ├┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
/// │ Log message
/// └──────────────────────────
/// ```
class PrettyPrinter extends LogPrinter {
  static const topLeftCorner = '┌';
  static const bottomLeftCorner = '└';
  static const middleCorner = '├';
  static const verticalLine = '│';
  static const doubleDivider = '─';
  static const singleDivider = '┄';

  static final Map<Level, AnsiColor> defaultLevelColors = {
    Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
    Level.debug: const AnsiColor.none(),
    Level.info: const AnsiColor.fg(12),
    Level.warning: const AnsiColor.fg(208),
    Level.error: const AnsiColor.fg(196),
    Level.fatal: const AnsiColor.fg(199),
  };

  static final Map<Level, String> defaultLevelEmojis = {
    Level.trace: '',
    Level.debug: '🐛',
    Level.info: '💡',
    Level.warning: '⚠️',
    Level.error: '⛔',
    Level.fatal: '👾',
  };

  /// Matches a stacktrace line as generated on Android/iOS devices.
  ///
  /// For example:
  /// * #1      Logger.log (package:logger/src/logger.dart:115:29)
  static final _deviceStackTraceRegex = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)');

  /// Matches a stacktrace line as generated by Flutter web.
  ///
  /// For example:
  /// * packages/logger/src/printers/pretty_printer.dart 91:37
  static final _webStackTraceRegex = RegExp(r'^((packages|dart-sdk)/\S+/)');

  /// Matches a stacktrace line as generated by browser Dart.
  ///
  /// For example:
  /// * dart:sdk_internal
  /// * package:logger/src/logger.dart
  static final _browserStackTraceRegex =
      RegExp(r'^(?:package:)?(dart:\S+|\S+)');

  static DateTime? startTime;

  /// The index at which the stack trace should start.
  ///
  /// This can be useful if, for instance, Logger is wrapped in another class and
  /// you wish to remove these wrapped calls from stack trace
  ///
  /// See also:
  /// * [excludePaths]
  final int stackTraceBeginIndex;

  /// Controls the method count in stack traces
  /// when no [LogEvent.error] was provided.
  ///
  /// In case no [LogEvent.stackTrace] was provided,
  /// [StackTrace.current] will be used to create one.
  ///
  /// * Set to `0` in order to disable printing a stack trace
  /// without an error parameter.
  /// * Set to `null` to remove the method count limit all together.
  ///
  /// See also:
  /// * [errorMethodCount]
  final int? methodCount;

  /// Controls the method count in stack traces
  /// when [LogEvent.error] was provided.
  ///
  /// In case no [LogEvent.stackTrace] was provided,
  /// [StackTrace.current] will be used to create one.
  ///
  /// * Set to `0` in order to disable printing a stack trace
  /// in case of an error parameter.
  /// * Set to `null` to remove the method count limit all together.
  ///
  /// See also:
  /// * [methodCount]
  final int? errorMethodCount;

  /// Controls the length of the divider lines.
  final int lineLength;

  /// Whether ansi colors are used to color the output.
  final bool colors;

  /// Whether emojis are prefixed to the log line.
  final bool printEmojis;

  /// Whether [LogEvent.time] is printed.
  @Deprecated("Use `dateTimeFormat` instead.")
  bool get printTime => dateTimeFormat != DateTimeFormat.none;

  /// Controls the format of [LogEvent.time].
  final DateTimeFormatter dateTimeFormat;

  /// Controls the ascii 'boxing' of different [Level]s.
  ///
  /// By default all levels are 'boxed',
  /// to prevent 'boxing' of a specific level,
  /// include it with `true` in the map.
  ///
  /// Example to prevent boxing of [Level.trace] and [Level.info]:
  /// ```dart
  /// excludeBox: {
  ///   Level.trace: true,
  ///   Level.info: true,
  /// },
  /// ```
  ///
  /// See also:
  /// * [noBoxingByDefault]
  final Map<Level, bool> excludeBox;

  /// Whether the implicit `bool`s in [excludeBox] are `true` or `false` by default.
  ///
  /// By default all levels are 'boxed',
  /// this flips the default to no boxing for all levels.
  /// Individual boxing can still be turned on for specific
  /// levels by setting them manually to `false` in [excludeBox].
  ///
  /// Example to specifically activate 'boxing' of [Level.error]:
  /// ```dart
  /// noBoxingByDefault: true,
  /// excludeBox: {
  ///   Level.error: false,
  /// },
  /// ```
  ///
  /// See also:
  /// * [excludeBox]
  final bool noBoxingByDefault;

  /// A list of custom paths that are excluded from the stack trace.
  ///
  /// For example, to exclude your `MyLog` util that redirects to this logger:
  /// ```dart
  /// excludePaths: [
  ///   // To exclude a whole package
  ///   "package:test",
  ///   // To exclude a single file
  ///   "package:test/util/my_log.dart",
  /// ],
  /// ```
  ///
  /// See also:
  /// * [stackTraceBeginIndex]
  final List<String> excludePaths;

  /// Contains the parsed rules resulting from [excludeBox] and [noBoxingByDefault].
  late final Map<Level, bool> _includeBox;
  String _topBorder = '';
  String _middleBorder = '';
  String _bottomBorder = '';

  /// Controls the colors used for the different log levels.
  ///
  /// Default fallbacks are modifiable via [defaultLevelColors].
  final Map<Level, AnsiColor>? levelColors;

  /// Controls the emojis used for the different log levels.
  ///
  /// Default fallbacks are modifiable via [defaultLevelEmojis].
  final Map<Level, String>? levelEmojis;

  PrettyPrinter({
    this.stackTraceBeginIndex = 0,
    this.methodCount = 2,
    this.errorMethodCount = 8,
    this.lineLength = 120,
    this.colors = true,
    this.printEmojis = true,
    @Deprecated(
        "Use `dateTimeFormat` with `DateTimeFormat.onlyTimeAndSinceStart` or `DateTimeFormat.none` instead.")
    bool? printTime,
    DateTimeFormatter dateTimeFormat = DateTimeFormat.none,
    this.excludeBox = const {},
    this.noBoxingByDefault = false,
    this.excludePaths = const [],
    this.levelColors,
    this.levelEmojis,
  })  : assert(
            (printTime != null && dateTimeFormat == DateTimeFormat.none) ||
                printTime == null,
            "Don't set printTime when using dateTimeFormat"),
        dateTimeFormat = printTime == null
            ? dateTimeFormat
            : (printTime
                ? DateTimeFormat.onlyTimeAndSinceStart
                : DateTimeFormat.none) {
    startTime ??= DateTime.now();

    var doubleDividerLine = StringBuffer();
    var singleDividerLine = StringBuffer();
    for (var i = 0; i < lineLength - 1; i++) {
      doubleDividerLine.write(doubleDivider);
      singleDividerLine.write(singleDivider);
    }

    _topBorder = '$topLeftCorner$doubleDividerLine';
    _middleBorder = '$middleCorner$singleDividerLine';
    _bottomBorder = '$bottomLeftCorner$doubleDividerLine';

    // Translate excludeBox map (constant if default) to includeBox map with all Level enum possibilities
    _includeBox = {};
    for (var l in Level.values) {
      _includeBox[l] = !noBoxingByDefault;
    }
    excludeBox.forEach((k, v) => _includeBox[k] = !v);
  }

  @override
  List<String> log(LogEvent event) {
    var messageStr = stringifyMessage(event.message);

    String? stackTraceStr;
    if (event.error != null) {
      if ((errorMethodCount == null || errorMethodCount! > 0)) {
        stackTraceStr = formatStackTrace(
          event.stackTrace ?? StackTrace.current,
          errorMethodCount,
        );
      }
    } else if (methodCount == null || methodCount! > 0) {
      stackTraceStr = formatStackTrace(
        event.stackTrace ?? StackTrace.current,
        methodCount,
      );
    }

    var errorStr = event.error?.toString();

    String? timeStr;
    // Keep backwards-compatibility to `printTime` check
    // ignore: deprecated_member_use_from_same_package
    if (printTime) {
      timeStr = getTime(event.time);
    }

    return _formatAndPrint(
      event.level,
      messageStr,
      timeStr,
      errorStr,
      stackTraceStr,
    );
  }

  String? formatStackTrace(StackTrace? stackTrace, int? methodCount) {
    List<String> lines = stackTrace
        .toString()
        .split('\n')
        .where(
          (line) =>
              !_discardDeviceStacktraceLine(line) &&
              !_discardWebStacktraceLine(line) &&
              !_discardBrowserStacktraceLine(line) &&
              line.isNotEmpty,
        )
        .toList();
    List<String> formatted = [];

    int stackTraceLength =
        (methodCount != null ? min(lines.length, methodCount) : lines.length);
    for (int count = 0; count < stackTraceLength; count++) {
      var line = lines[count];
      if (count < stackTraceBeginIndex) {
        continue;
      }
      formatted.add('#$count   ${line.replaceFirst(RegExp(r'#\d+\s+'), '')}');
    }

    if (formatted.isEmpty) {
      return null;
    } else {
      return formatted.join('\n');
    }
  }

  bool _isInExcludePaths(String segment) {
    for (var element in excludePaths) {
      if (segment.startsWith(element)) {
        return true;
      }
    }
    return false;
  }

  bool _discardDeviceStacktraceLine(String line) {
    var match = _deviceStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(2)!;
    if (segment.startsWith('package:logger')) {
      return true;
    }
    return _isInExcludePaths(segment);
  }

  bool _discardWebStacktraceLine(String line) {
    var match = _webStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(1)!;
    if (segment.startsWith('packages/logger') ||
        segment.startsWith('dart-sdk/lib')) {
      return true;
    }
    return _isInExcludePaths(segment);
  }

  bool _discardBrowserStacktraceLine(String line) {
    var match = _browserStackTraceRegex.matchAsPrefix(line);
    if (match == null) {
      return false;
    }
    final segment = match.group(1)!;
    if (segment.startsWith('package:logger') || segment.startsWith('dart:')) {
      return true;
    }
    return _isInExcludePaths(segment);
  }

  String getTime(DateTime time) {
    return dateTimeFormat(time);
  }

  // Handles any object that is causing JsonEncoder() problems
  Object toEncodableFallback(dynamic object) {
    return object.toString();
  }

  String stringifyMessage(Object? message) {
    if (message is Map || message is Iterable) {
      var encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
      return encoder.convert(message);
    } else {
      return message.toString();
    }
  }

  AnsiColor _getLevelColor(Level level) {
    AnsiColor? color;
    if (colors) {
      color = levelColors?[level] ?? defaultLevelColors[level];
    }
    return color ?? const AnsiColor.none();
  }

  String _getEmoji(Level level) {
    if (printEmojis) {
      final String? emoji = levelEmojis?[level] ?? defaultLevelEmojis[level];
      if (emoji != null) {
        return '$emoji ';
      }
    }
    return '';
  }

  List<String> _formatAndPrint(
    Level level,
    String message,
    String? time,
    String? error,
    String? stacktrace,
  ) {
    List<String> buffer = [];
    var verticalLineAtLevel = (_includeBox[level]!) ? ('$verticalLine ') : '';
    var color = _getLevelColor(level);
    if (_includeBox[level]!) buffer.add(color(_topBorder));

    if (error != null) {
      for (var line in error.split('\n')) {
        buffer.add(color('$verticalLineAtLevel$line'));
      }
      if (_includeBox[level]!) buffer.add(color(_middleBorder));
    }

    if (stacktrace != null) {
      for (var line in stacktrace.split('\n')) {
        buffer.add(color('$verticalLineAtLevel$line'));
      }
      if (_includeBox[level]!) buffer.add(color(_middleBorder));
    }

    if (time != null) {
      buffer.add(color('$verticalLineAtLevel$time'));
      if (_includeBox[level]!) buffer.add(color(_middleBorder));
    }

    var emoji = _getEmoji(level);
    for (var line in message.split('\n')) {
      buffer.add(color('$verticalLineAtLevel$emoji$line'));
    }
    if (_includeBox[level]!) buffer.add(color(_bottomBorder));

    return buffer;
  }
}
