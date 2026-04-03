import 'dart:async';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:vm_service/vm_service.dart';

class LoggerExtensionController extends ChangeNotifier {
  static const int _maxLogs = 1000;
  static const int _maxProcessedIds = 1000;

  final List<LogEvent> _allLogs = [];
  final Set<String> _processedIds = {};

  List<LogEvent> _filteredLogsCache = [];
  String _searchQuery = '';
  Level _selectedLevel = Level.all;

  String get searchQuery => _searchQuery;
  set searchQuery(String value) {
    if (_searchQuery != value) {
      _searchQuery = value;
      _refreshFilter();
    }
  }

  Level get selectedLevel => _selectedLevel;
  set selectedLevel(Level level) {
    if (_selectedLevel != level) {
      _selectedLevel = level;
      _refreshFilter();
    }
  }

  /// Returns logs filtered by [searchQuery] and [selectedLevel], in reverse order (newest first).
  List<LogEvent> get filteredLogs => _filteredLogsCache;

  StreamSubscription<Event>? _subscription;

  LoggerExtensionController() {
    _init();
  }

  Future<void> _init() async {
    await serviceManager.onServiceAvailable;
    final service = serviceManager.service;
    if (service == null) return;

    // Ensure the Extension stream is active to receive postEvent notifications
    try {
      await service.streamListen('Extension');
    } catch (e) {
      debugPrint('Error listening to Extension stream: $e');
    }

    _subscription = service.onExtensionEvent.listen(_handleExtensionEvent);
  }

  void _handleExtensionEvent(Event event) {
    if (event.extensionKind != Logger.extensionEventName) return;

    final data = event.extensionData?.data;
    if (data == null) return;

    try {
      final entry = LogEvent.fromJson(Map<String, dynamic>.from(data));

      // Create a unique key for deduplication since LogEvent doesn't have an 'id'
      final entryId =
          '${entry.time.millisecondsSinceEpoch}_${entry.level.name}_${entry.message}';

      if (_processedIds.contains(entryId)) return;

      // Maintain deduplication window size
      if (_processedIds.length >= _maxProcessedIds) {
        _processedIds.remove(_processedIds.first);
      }
      _processedIds.add(entryId);

      // Insert newest logs at the beginning
      _allLogs.insert(0, entry);

      // Limit memory growth
      if (_allLogs.length > _maxLogs) {
        _allLogs.removeLast();
      }

      _refreshFilter();
    } catch (e) {
      debugPrint('Error parsing log event: $e');
    }
  }

  void _refreshFilter() {
    final query = _searchQuery.toLowerCase();

    _filteredLogsCache = _allLogs.where((log) {
      final message = log.message.toString().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          message.contains(query) ||
          (log.error?.toString().toLowerCase().contains(query) ?? false);
      final matchesLevel =
          _selectedLevel == Level.all || log.level == _selectedLevel;
      return matchesSearch && matchesLevel;
    }).toList();

    notifyListeners();
  }

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
}
