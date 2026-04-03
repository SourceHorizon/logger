import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const LoggerExampleApp());
}

class LoggerExampleApp extends StatelessWidget {
  const LoggerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Logger Demo',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Logger _logger = Logger();

  void _logDebug() => _logger.d('This is a debug message 🐛');
  void _logInfo() => _logger.i('This is an info message ℹ️');
  void _logWarning() => _logger.w('This is a warning message ⚠️');
  void _logError() {
    try {
      throw Exception('Simulated Error');
    } catch (e, stack) {
      _logger.e('An error occurred! ❌', error: e, stackTrace: stack);
    }
  }

  void _logFatal() => _logger.f('Critical system failure! 💀');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Logger'), elevation: 2),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Testing Suite',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Trigger logs to see them in the DevTools extension tab.'),
          const SizedBox(height: 24),
          _LogTile(
            label: 'Debug',
            icon: Icons.bug_report,
            color: Colors.blue,
            onPressed: _logDebug,
          ),
          _LogTile(
            label: 'Info',
            icon: Icons.info_outline,
            color: Colors.green,
            onPressed: _logInfo,
          ),
          _LogTile(
            label: 'Warning',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
            onPressed: _logWarning,
          ),
          _LogTile(
            label: 'Error',
            icon: Icons.error_outline,
            color: Colors.red,
            onPressed: _logError,
          ),
          _LogTile(
            label: 'Fatal',
            icon: Icons.dangerous_outlined,
            color: Colors.purple,
            onPressed: _logFatal,
          ),
        ],
      ),
    );
  }
}

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
