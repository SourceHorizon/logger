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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              hintText: 'Search logs...',
              leading: const Icon(Icons.search, size: 20),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              padding: const WidgetStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 12.0),
              ),
              onChanged: onSearchChanged,
              controller: TextEditingController(text: searchQuery)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: searchQuery.length),
                ),
              trailing: [
                if (searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => onSearchChanged(''),
                    tooltip: 'Clear search',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onClearLogs,
                  tooltip: 'Clear Logs',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: DropdownMenu<Level>(
              initialSelection: selectedLevel,
              dropdownMenuEntries: Level.values
                  .map(
                    (l) => DropdownMenuEntry(
                      value: l,
                      label: l.name.toUpperCase(),
                      leadingIcon: Icon(
                        Icons.circle,
                        size: 10,
                        color: _getLevelColor(l),
                      ),
                    ),
                  )
                  .toList(),
              onSelected: (lvl) {
                if (lvl != null) onLevelChanged(lvl);
              },
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
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
