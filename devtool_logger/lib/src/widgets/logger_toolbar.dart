import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

/// A toolbar for the logger extension with search, filter, and clear actions.
class LoggerToolbar extends StatelessWidget {
  final String searchQuery;
  final Level selectedLevel;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Level> onLevelChanged;
  final VoidCallback onClearLogs;

  const LoggerToolbar({
    super.key,
    required this.searchQuery,
    required this.selectedLevel,
    required this.onSearchChanged,
    required this.onLevelChanged,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          SearchBar(
            hintText: 'Search logs...',
            leading: const Icon(Icons.search),
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 12.0),
            ),
            onChanged: onSearchChanged,
            trailing: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onClearLogs,
                tooltip: 'Clear Logs',
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownMenu<Level>(
            initialSelection: selectedLevel,
            label: const Text('Filter Level'),
            dropdownMenuEntries: [
              ...Level.values.map(
                (l) => DropdownMenuEntry(
                  value: l,
                  label: l.name.toUpperCase(),
                  leadingIcon: Icon(
                    Icons.circle,
                    size: 12,
                    color: _getLevelColor(l),
                  ),
                ),
              ),
            ],
            onSelected: (lvl) {
              if (lvl != null) onLevelChanged(lvl);
            },
            expandedInsets: EdgeInsets.zero,
            inputDecorationTheme: InputDecorationTheme(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(Level level) {
    switch (level) {
      case Level.all:
        return Colors.blueGrey;
      case Level.trace:
      case Level.debug:
        return Colors.grey;
      case Level.info:
        return Colors.blue;
      case Level.warning:
        return Colors.orange;
      case Level.error:
        return Colors.red;
      case Level.fatal:
        return Colors.deepPurple;
      case Level.off:
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}
