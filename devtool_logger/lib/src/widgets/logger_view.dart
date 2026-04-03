import 'package:logger/logger.dart';
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
  String _searchQuery = '';
  Level _selectedLevel = Level.all;

  @override
  void initState() {
    super.initState();
    _controller = LoggerExtensionController();
    _selectedLevel = Level.all;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              _controller.clearLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Logs cleared'),
                  behavior: SnackBarBehavior.floating,
                  width: 200,
                  backgroundColor: theme.colorScheme.secondary,
                ),
              );
            },
            tooltip: 'Clear All Logs',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(130),
          child: LoggerToolbar(
            searchQuery: _searchQuery,
            selectedLevel: _selectedLevel,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onLevelChanged: (lvl) => setState(() => _selectedLevel = lvl),
            onClearLogs: () {
              _controller.clearLogs();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs cleared')));
            },
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final filteredLogs = _controller.logs
              .where((log) {
                final matchesSearch =
                    log.message.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (log.error?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false);
                final matchesLevel =
                    _selectedLevel == Level.all || log.level == _selectedLevel;
                return matchesSearch && matchesLevel;
              })
              .toList()
              .reversed
              .toList();

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
    );
  }
}
