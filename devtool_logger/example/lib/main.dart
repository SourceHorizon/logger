import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const LoggerExampleApp());
}

/// Example app demonstrating the DevTools Logger extension.
///
/// Provides buttons to emit various log levels, including structured
/// JSON messages that showcase the detail panel's tree view.
class LoggerExampleApp extends StatelessWidget {
  const LoggerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Logger Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

/// Main page with log trigger buttons organized by category.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Logger _logger = Logger();
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Logger'), elevation: 2),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Testing Suite',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Trigger logs to see them in the DevTools extension tab.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Basic Logs'),
          _LogTile(
            label: 'Trace',
            icon: Icons.track_changes,
            color: Colors.blueGrey,
            onPressed: () => _logger.t(
              'Initializing FlutterDevTools '
              'Log Extension...',
            ),
          ),
          _LogTile(
            label: 'Debug',
            icon: Icons.bug_report,
            color: Colors.cyan,
            onPressed: () => _logger.d(
              'flutter: State update: '
              'CounterApp(count: ${_counter++}, loading: false)',
            ),
          ),
          _LogTile(
            label: 'Info',
            icon: Icons.info_outline,
            color: Colors.green,
            onPressed: () => _logger.i(
              'dart:io: Closing socket '
              'connection to localhost:8080',
            ),
          ),
          _LogTile(
            label: 'Warning',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            onPressed: () => _logger.w(
              'package:provider: Found '
              'potentially leaking ChangeNotifier in WidgetTree',
            ),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Error & Fatal'),
          _LogTile(
            label: 'Error with StackTrace',
            icon: Icons.error_outline,
            color: Colors.red,
            onPressed: _logErrorWithStack,
          ),
          _LogTile(
            label: 'RangeError',
            icon: Icons.error,
            color: Colors.red.shade700,
            onPressed: _logRangeError,
          ),
          _LogTile(
            label: 'Fatal',
            icon: Icons.dangerous_outlined,
            color: Colors.deepPurple,
            onPressed: () => _logger.f('Critical system failure! 💀'),
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Structured Data (JSON)'),
          _LogTile(
            label: 'Log JSON payload',
            icon: Icons.data_object,
            color: Colors.teal,
            onPressed: _logJsonPayload,
          ),
          _LogTile(
            label: 'Log nested JSON',
            icon: Icons.account_tree,
            color: Colors.indigo,
            onPressed: _logNestedJson,
          ),
          const SizedBox(height: 16),
          _SectionHeader(title: 'Bulk'),
          _LogTile(
            label: 'Fire 10 mixed logs',
            icon: Icons.flash_on,
            color: Colors.amber.shade800,
            onPressed: _logBulk,
          ),
        ],
      ),
    );
  }

  /// Logs an error with a real stack trace for the STACK TRACE section.
  void _logErrorWithStack() {
    try {
      throw Exception('Simulated Error');
    } catch (e, stack) {
      _logger.e('An error occurred! ❌', error: e, stackTrace: stack);
    }
  }

  /// Logs a RangeError matching the UI reference screenshot.
  void _logRangeError() {
    try {
      final list = [1, 2, 3];
      list[10]; // out of range
    } catch (e, stack) {
      _logger.e(
        'Exception: RangeError (index): Index out of range: '
        'index should be less than 3: 10',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Logs a JSON string so the STRUCTURE section renders a tree view.
  void _logJsonPayload() {
    final payload = jsonEncode({
      'type': 'CounterApp',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'payload': {
        'count': _counter,
        'loading': false,
        'history': [1, 2, 3, _counter],
      },
    });

    _logger.i(
      'flutter: State update: CounterApp(count: $_counter, '
      'loading: false)',
    );
    _logger.d(payload);
  }

  /// Logs deeply nested JSON to test recursive tree expansion.
  void _logNestedJson() {
    final payload = jsonEncode({
      'user': {
        'id': 42,
        'name': 'John Doe',
        'settings': {
          'theme': 'dark',
          'notifications': true,
          'preferences': {'language': 'en', 'timezone': 'UTC+7'},
        },
      },
    });

    _logger.d(payload);
  }

  /// Fires a burst of mixed-level logs to test filtering and scrolling.
  void _logBulk() {
    _logger.t('Bulk test: trace message');
    _logger.d('Bulk test: debug message');
    _logger.i('Bulk test: info message');
    _logger.w('Bulk test: warning message');
    _logger.d(jsonEncode({'bulk': true, 'index': 5}));
    _logger.i('Bulk test: another info');
    _logger.w('Bulk test: another warning');
    try {
      throw StateError('Bulk simulated error');
    } catch (e, stack) {
      _logger.e('Bulk test: error with stack', error: e, stackTrace: stack);
    }
    _logger.f('Bulk test: fatal message');
    _logger.t('Bulk test: final trace');
  }
}

/// A section header label in the log trigger list.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// A tappable card that triggers a log when pressed.
class _LogTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _LogTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onPressed,
      ),
    );
  }
}
