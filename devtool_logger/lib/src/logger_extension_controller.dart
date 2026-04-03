import 'dart:async';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';

import 'models/log_entry.dart';

class LoggerExtensionController extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  StreamSubscription<Event>? _subscription;
  final Set<String> _processedIds = {};

  LoggerExtensionController() {
    _init();
  }

  void _init() {
    serviceManager.onServiceAvailable.then((_) {
      final service = serviceManager.service;
      if (service == null) return;

      // Ensure the Extension stream is active to receive postEvent notifications
      service.streamListen('Extension').catchError((e) {
        debugPrint('Error listening to Extension stream: $e');
        return Success();
      });

      _subscription = service.onExtensionEvent.listen((event) {
        if (event.extensionKind == 'ext.devtool_logger.log') {
          final data = event.extensionData?.data;
          if (data != null) {
            final entry = LogEntry.fromJson(Map<String, dynamic>.from(data));

            // Deduplicate base on unique ID
            if (_processedIds.contains(entry.id)) return;

            // Limit the size of processed IDs set
            if (_processedIds.length > 1000) {
              _processedIds.remove(_processedIds.first);
            }
            _processedIds.add(entry.id);

            _logs.add(entry);
            notifyListeners();
          }
        }
      });
    });
  }

  void clearLogs() {
    _logs.clear();
    _processedIds.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
