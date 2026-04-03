import 'package:flutter/material.dart';

import '../logger_extension_controller.dart';
import 'log_item.dart';
import 'logger_toolbar.dart';

/// The main view for the logger extension.
class LoggerView extends StatefulWidget {
  const LoggerView({super.key});

  @override
  State<LoggerView> createState() => _LoggerViewState();
}

class _LoggerViewState extends State<LoggerView> {
  late final LoggerExtensionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoggerExtensionController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Flutter Logger',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => LoggerToolbar(
              searchQuery: _controller.searchQuery,
              selectedLevel: _controller.selectedLevel,
              onSearchChanged: (value) => _controller.searchQuery = value,
              onLevelChanged: (lvl) => _controller.selectedLevel = lvl,
              onClearLogs: () {
                _controller.clearLogs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logs cleared'),
                    behavior: SnackBarBehavior.floating,
                    width: 200,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final filteredLogs = _controller.filteredLogs;

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.segment_rounded,
                          size: 48,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No logs found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    return LogItem(log: filteredLogs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
