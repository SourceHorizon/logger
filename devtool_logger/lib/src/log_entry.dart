import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'log_level_color.dart';

// ── Stack-frame parsing ────────────────────────────────────────────────────

/// Patterns used for parsing raw stack trace lines into typed [ParsedStackFrame]s.
abstract final class _StackRegex {
  /// Device (Android / iOS): `#1      Logger.log (package:logger/src/...)`
  static final device = RegExp(r'#[0-9]+\s+(.+) \((\S+)\)');

  /// Browser (V8/Chrome): `at Object.methodName (file:line:col)`
  static final v8 = RegExp(r'^\s*at\s+(.+)\s+\((.+)\)$');

  /// Fallback for Web: `location [spaces] symbol`
  static final webFallback = RegExp(r'^(\S+\s+\d+:\d+)\s+(.+)$');

  /// Used to split a location string into [prefix, path, lineCol].
  /// Matches standard "package:path:line:col" or web "path line:col".
  static final locationSplitter = RegExp(
    r'^((?:package:[^/]+/|dart:[^/]+/|packages/[^/]+/|dart-sdk/lib/\S+/))?(.*?)(?:[: ](\d+:\d+))?$',
  );

  // Prefix matching for discarding frames (same as PrettyPrinter)
  static final discardWeb = RegExp(r'^((?:packages|dart-sdk)/\S+/)');
  static final discardBrowser = RegExp(r'^((?:package:)?dart:\S+|\S+)');
}

/// A pre-parsed stack frame with location parts already separated for UI efficiency.
@immutable
class ParsedStackFrame {
  final int index;
  final String symbol;

  /// The prefix like 'package:flutter/', 'dart:core/' or empty.
  final String packagePrefix;

  /// The file path within the package, like 'src/material/ink_well.dart'.
  final String path;

  /// The line and column info, like '1222:21'.
  final String lineCol;

  const ParsedStackFrame({
    required this.index,
    required this.symbol,
    required this.packagePrefix,
    required this.path,
    required this.lineCol,
  });

  /// Reconstructs the full location string if needed.
  String get fullLocation =>
      '$packagePrefix$path${lineCol.isNotEmpty ? ' $lineCol' : ''}';
}

// ── Internal parsing helpers ───────────────────────────────────────────────

/// Splits a raw location string into its constituent parts.
(String, String, String) _splitLocation(String raw) {
  final match = _StackRegex.locationSplitter.firstMatch(raw);
  if (match == null) return ('', raw, '');

  final prefix = match.group(1) ?? '';
  final path = match.group(2) ?? '';
  final lineCol = match.group(3) ?? '';

  return (prefix, path, lineCol);
}

bool _shouldDiscard(String line) {
  final d = _StackRegex.device.matchAsPrefix(line);
  if (d != null) {
    final seg = d.group(2)!;
    return seg.startsWith('package:logger') || _isExcluded(seg);
  }
  final w = _StackRegex.discardWeb.matchAsPrefix(line);
  if (w != null) {
    final seg = w.group(1)!;
    return seg.startsWith('packages/logger') ||
        seg.startsWith('dart-sdk/lib') ||
        _isExcluded(seg);
  }
  final b = _StackRegex.discardBrowser.matchAsPrefix(line);
  if (b != null) {
    final seg = b.group(1)!;
    return seg.startsWith('package:logger') ||
        seg.startsWith('dart:') ||
        _isExcluded(seg);
  }
  return false;
}

bool _isExcluded(String _) => false;

List<ParsedStackFrame> _parseFrames(StackTrace stackTrace) {
  final raw = stackTrace.toString();
  final lines = raw.split('\n').where((l) => l.isNotEmpty).toList();

  final frames = <ParsedStackFrame>[];
  int displayIndex = 0;

  for (final line in lines) {
    if (_shouldDiscard(line)) continue;

    final cleanLine = line.replaceFirst(RegExp(r'#\d+\s+'), '').trim();

    // Helper to create a frame with parsed location
    ParsedStackFrame create(String sym, String loc) {
      final (pre, path, lc) = _splitLocation(loc);
      return ParsedStackFrame(
        index: displayIndex++,
        symbol: sym,
        packagePrefix: pre,
        path: path,
        lineCol: lc,
      );
    }

    // 1. Try Device format
    final d = _StackRegex.device.firstMatch(line);
    if (d != null) {
      frames.add(create(d.group(1)!.trim(), d.group(2)!));
      continue;
    }

    // 2. Try V8 format
    final v = _StackRegex.v8.firstMatch(cleanLine);
    if (v != null) {
      frames.add(create(v.group(1)!.trim(), v.group(2)!));
      continue;
    }

    // 3. Try Web Fallback
    final w = _StackRegex.webFallback.firstMatch(cleanLine);
    if (w != null) {
      frames.add(create(w.group(2)!.trim(), w.group(1)!.trim()));
      continue;
    }

    // 4. Final fallback
    frames.add(create('', cleanLine));
  }

  return List.unmodifiable(frames);
}

// ── LogEntry ──────────────────────────────────────────────────────────────

@immutable
class LogEntry {
  final LogEvent _event;

  final String messageString;
  final String messageLower;
  final String? errorString;
  final String? errorLower;
  final String? stackTraceString;
  final List<ParsedStackFrame> parsedStackFrames;
  final String colonTime;
  final Color levelColor;
  final String levelLabel;
  final bool isErrorOrFatal;
  final Object? parsedJson;
  final String deduplicationKey;

  LogEntry(LogEvent event) : this._(event);

  LogEntry._(this._event)
    : messageString = _event.message.toString(),
      errorString = _event.error?.toString(),
      stackTraceString = _event.stackTrace?.toString(),
      messageLower = _event.message.toString().toLowerCase(),
      errorLower = _event.error?.toString().toLowerCase(),
      parsedStackFrames = _event.stackTrace != null
          ? _parseFrames(_event.stackTrace!)
          : const [],
      colonTime = _event.time.colonTime,
      levelColor = _event.level.color,
      levelLabel = _event.level.label,
      isErrorOrFatal =
          _event.level == Level.error || _event.level == Level.fatal,
      parsedJson = _tryParseJson(_event.message.toString()),
      deduplicationKey = _buildKey(_event);

  Level get level => _event.level;
  DateTime get time => _event.time;

  static Object? _tryParseJson(String src) {
    try {
      final decoded = jsonDecode(src);
      if (decoded is Map || decoded is List) return decoded;
    } catch (_) {}
    return null;
  }

  static String _buildKey(LogEvent e) {
    final msgStr = e.message.toString();
    return '${e.time.millisecondsSinceEpoch}_${e.level.name}_${msgStr.hashCode}';
  }
}

extension on DateTime {
  String get colonTime {
    final local = toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
