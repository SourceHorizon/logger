import '../ansi_color.dart';
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

  static DateTime? startTime;

  /// Controls the length of the divider lines.
  final int lineLength;

  /// Whether ansi colors are used to color the output.
  final bool colors;

  /// Whether emojis are prefixed to the log line.
  final bool printEmojis;

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
    super.stackTraceBeginIndex,
    super.methodCount,
    super.errorMethodCount,
    this.lineLength = 120,
    this.colors = true,
    this.printEmojis = true,
    super.dateTimeFormat,
    this.excludeBox = const {},
    this.noBoxingByDefault = false,
    super.excludePaths,
    this.levelColors,
    this.levelEmojis,
  }) {
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
    String messageStr = stringifyMessage(event.message);
    String? stackTraceStr = getStackTrace(event);
    String? timeStr = getTime(event.time);
    String? errorStr = event.error?.toString();

    return _formatAndPrint(
      event.level,
      messageStr,
      timeStr,
      errorStr,
      stackTraceStr,
    );
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
