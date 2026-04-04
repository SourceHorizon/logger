import 'package:flutter/material.dart';

import '../log_entry.dart';

/// The left panel displaying a table-style log list.
///
/// Shows log entries in rows with TIMESTAMP, LVL (colored dot),
/// and MESSAGE columns. Supports single-row selection to drive
/// the detail panel.
class LogListPanel extends StatelessWidget {
  /// The list of log entries to display.
  final List<LogEntry> logs;

  /// Index of the currently selected log entry, or null if none.
  final int? selectedIndex;

  /// Called when a log entry row is tapped.
  final ValueChanged<int> onLogSelected;

  const LogListPanel({
    super.key,
    required this.logs,
    required this.selectedIndex,
    required this.onLogSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyLogsPlaceholder();
    }
    return ListView.builder(
      itemCount: logs.length,
      itemBuilder: (context, index) => _LogListRow(
        log: logs[index],
        isSelected: selectedIndex == index,
        onTap: () => onLogSelected(index),
      ),
    );
  }
}

/// Shown when the filtered log list is empty.
class _EmptyLogsPlaceholder extends StatelessWidget {
  const _EmptyLogsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.segment_rounded, size: 48),
          Text('No logs found', style: TextTheme.of(context).headlineSmall),
        ],
      ),
    );
  }
}

/// A single row in the log list table.
///
/// All display values ([LogEntry.bracketTime], [LogEntry.levelColor],
/// [LogEntry.messageString]) are pre-resolved fields — no computation
/// happens during the build phase.
class _LogListRow extends StatelessWidget {
  final LogEntry log;
  final bool isSelected;
  final VoidCallback onTap;

  const _LogListRow({
    required this.log,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      selected: isSelected,
      title: Text(
        log.messageString,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      leading: Icon(Icons.circle, color: log.levelColor),
      trailing: Text(log.colonTime),
    );
  }
}
