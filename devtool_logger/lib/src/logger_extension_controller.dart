import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vm_service/vm_service.dart';

import 'log_entry.dart';

/// Controls the logger extension state: receiving, filtering, and managing logs.
///
/// Listens to the VM Service `Extension` stream for log events posted
/// by the `logger` package, deduplicates them, and maintains a filtered
/// cache that the UI binds to via [ChangeNotifier].
///
/// All log data is stored as [LogEntry] instances, which pre-parse every
/// computed property (strings, colors, JSON, time formatting) at ingestion
/// time. Widgets therefore read plain fields and perform no repeated work.
class LoggerExtensionController extends ChangeNotifier {
  /// Maximum number of log entries kept in memory.
  static const int _maxLogs = 1000;

  /// Maximum size of the deduplication ID window.
  static const int _maxProcessedIds = 1000;

  final List<LogEntry> _allLogs = [];
  final Set<String> _processedIds = {};

  List<LogEntry> _filteredLogsCache = [];
  String _searchQuery = '';
  Level _selectedLevel = Level.all;
  bool _useRegex = false;
  bool _preserveLogs = true;

  /// Cached compiled [RegExp] for the current [_searchQuery].
  ///
  /// Invalidated (set to null) whenever [_searchQuery] changes.
  /// This avoids re-compiling the pattern for every log entry during a scan.
  RegExp? _cachedPattern;

  /// Lowercase version of [_searchQuery], cached to avoid repeated allocation
  /// on every entry check during a plain-text filter scan.
  String _cachedLowerQuery = '';

  StreamSubscription<Event>? _subscription;

  /// Creates a controller and begins listening for log events.
  LoggerExtensionController() {
    _init();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// The current search query used to filter logs.
  String get searchQuery => _searchQuery;
  set searchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    _cachedPattern = null;           // Invalidate the compiled regex cache.
    _cachedLowerQuery = value.toLowerCase(); // Pre-lowercase for plain-text filter.
    _rebuildFilteredCache();
  }

  /// The currently selected log level filter.
  ///
  /// Set to [Level.all] to show every level.
  Level get selectedLevel => _selectedLevel;
  set selectedLevel(Level level) {
    if (_selectedLevel == level) return;
    _selectedLevel = level;
    _rebuildFilteredCache();
  }

  /// Whether the search query should be interpreted as a regular expression.
  bool get useRegex => _useRegex;
  set useRegex(bool value) {
    if (_useRegex == value) return;
    _useRegex = value;
    _cachedPattern = null; // Mode changed — cached pattern is no longer valid.
    _rebuildFilteredCache();
  }

  /// Whether to preserve logs across hot reloads / reconnects.
  ///
  /// When true, [clearLogs] is skipped during automatic lifecycle events.
  bool get preserveLogs => _preserveLogs;
  set preserveLogs(bool value) {
    if (_preserveLogs == value) return;
    _preserveLogs = value;
    notifyListeners();
  }

  /// Returns logs filtered by [searchQuery] and [selectedLevel].
  ///
  /// Ordered newest-first (index 0 = most recent).
  List<LogEntry> get filteredLogs =>
      List<LogEntry>.unmodifiable(_filteredLogsCache);

  /// The total number of unfiltered logs currently held in memory.
  int get totalLogCount => _allLogs.length;

  /// Whether any filter is currently active.
  bool get hasActiveFilter =>
      _searchQuery.isNotEmpty || _selectedLevel != Level.all;

  /// Clears all stored logs and resets the deduplication window.
  void clearLogs() {
    _allLogs.clear();
    _processedIds.clear();
    _filteredLogsCache = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private implementation
  // ---------------------------------------------------------------------------

  /// Connects to the VM Service and subscribes to extension events.
  Future<void> _init() async {
    await serviceManager.onServiceAvailable;
    final service = serviceManager.service;
    if (service == null) return;

    try {
      await service.streamListen('Extension');
    } catch (e) {
      debugPrint('Error listening to Extension stream: $e');
    }

    _subscription = service.onExtensionEvent.listen(_handleExtensionEvent);
  }

  /// Processes a single VM Service extension event.
  ///
  /// Ignores events that don't match the logger's extension event name,
  /// deduplicates by a composite key, then wraps the parsed event in a
  /// [LogEntry] so all computed properties are resolved immediately.
  ///
  /// Instead of rebuilding the entire filtered cache on each insert,
  /// only the new entry is checked against the current filters — O(1)
  /// rather than O(n).
  void _handleExtensionEvent(Event event) {
    if (event.extensionKind != Logger.extensionEventName) return;

    final data = event.extensionData?.data;
    if (data == null) return;

    try {
      final logEvent = LogEvent.fromJson(Map<String, dynamic>.from(data));
      final entry = LogEntry(logEvent);

      if (_processedIds.contains(entry.deduplicationKey)) return;

      _trackDeduplicationId(entry.deduplicationKey);
      _insertLog(entry);
      _insertIntoFilteredCacheIfMatches(entry);
    } catch (e) {
      debugPrint('Error parsing log event: $e');
    }
  }

  /// Adds the [id] to the deduplication set, evicting the oldest if full.
  void _trackDeduplicationId(String id) {
    if (_processedIds.length >= _maxProcessedIds) {
      _processedIds.remove(_processedIds.first);
    }
    _processedIds.add(id);
  }

  /// Inserts a new [entry] at the front of [_allLogs] and trims if over capacity.
  void _insertLog(LogEntry entry) {
    _allLogs.insert(0, entry);
    if (_allLogs.length > _maxLogs) {
      _allLogs.removeLast();
    }
  }

  /// Checks [entry] against the active filters and, if it matches,
  /// inserts it at the front of [_filteredLogsCache] — O(1) per new log.
  ///
  /// Trims the cache to [_maxLogs] to mirror [_allLogs] capacity.
  void _insertIntoFilteredCacheIfMatches(LogEntry entry) {
    if (_matchesFilters(entry)) {
      _filteredLogsCache.insert(0, entry);
      if (_filteredLogsCache.length > _maxLogs) {
        _filteredLogsCache.removeLast();
      }
    }
    notifyListeners();
  }

  /// Full O(n) rebuild of [_filteredLogsCache] from [_allLogs].
  ///
  /// Called only when a filter setting changes (level, query, regex mode),
  /// not on every incoming log event.
  void _rebuildFilteredCache() {
    _filteredLogsCache = _allLogs.where(_matchesFilters).toList();
    notifyListeners();
  }

  /// Returns whether a single [entry] passes both level and search filters.
  bool _matchesFilters(LogEntry entry) {
    final matchesLevel =
        _selectedLevel == Level.all || entry.level == _selectedLevel;
    if (!matchesLevel) return false;

    if (_searchQuery.isEmpty) return true;

    return _useRegex ? _matchesRegex(entry) : _matchesPlainText(entry);
  }

  /// Plain-text (case-insensitive) search against [LogEntry.messageString]
  /// and [LogEntry.errorString].
  ///
  /// Uses [_cachedLowerQuery] to avoid allocating a new lowercase string
  /// on every entry check during a scan.
  bool _matchesPlainText(LogEntry entry) {
    return entry.messageLower.contains(_cachedLowerQuery) ||
        (entry.errorLower?.contains(_cachedLowerQuery) ?? false);
  }

  /// Regex search against [LogEntry.messageString] and [LogEntry.errorString].
  ///
  /// The [RegExp] is compiled once and cached in [_cachedPattern].
  /// It is recompiled only when [_searchQuery] changes.
  /// Falls back to matching nothing if the regex pattern is invalid.
  bool _matchesRegex(LogEntry entry) {
    try {
      _cachedPattern ??= RegExp(_searchQuery, caseSensitive: false);
      return _cachedPattern!.hasMatch(entry.messageString) ||
          (entry.errorString != null &&
              _cachedPattern!.hasMatch(entry.errorString!));
    } catch (_) {
      // Invalid regex — treat as no match.
      return false;
    }
  }
}
