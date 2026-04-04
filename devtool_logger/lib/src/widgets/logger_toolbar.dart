import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../log_level_color.dart';

/// A toolbar for the logger extension with search, regex toggle,
/// level filter chips, preserve toggle, and clear action.
///
/// Matches the DevTools-style toolbar layout with [FilterChip]s
/// for log levels displayed inline.
class LoggerToolbar extends StatelessWidget {
  /// The current search query text.
  final String searchQuery;

  /// The currently selected log level filter.
  final Level selectedLevel;

  /// Whether regex search mode is enabled.
  final bool useRegex;

  /// Whether logs are preserved across hot reloads.
  final bool preserveLogs;

  /// Called when the search query changes.
  final ValueChanged<String> onSearchChanged;

  /// Called when a level filter chip is selected.
  final ValueChanged<Level> onLevelChanged;

  /// Called when the regex toggle is tapped.
  final ValueChanged<bool> onRegexChanged;

  /// Called when the preserve toggle is switched.
  final ValueChanged<bool> onPreserveChanged;

  /// Called when the clear logs button is pressed.
  final VoidCallback onClearLogs;

  const LoggerToolbar({
    super.key,
    required this.searchQuery,
    required this.selectedLevel,
    required this.useRegex,
    required this.preserveLogs,
    required this.onSearchChanged,
    required this.onLevelChanged,
    required this.onRegexChanged,
    required this.onPreserveChanged,
    required this.onClearLogs,
  });

  /// The log levels displayed as filter chips in the toolbar.
  static const _filterLevels = [
    Level.trace,
    Level.debug,
    Level.info,
    Level.warning,
    Level.error,
    Level.fatal,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: _SearchField(
            query: searchQuery,
            useRegex: useRegex,
            onChanged: onSearchChanged,
            onRegexToggled: () => onRegexChanged(!useRegex),
          ),
        ),
        ..._filterLevels.map(
          (level) => _LevelFilterChip(
            level: level,
            isSelected: selectedLevel == level,
            onSelected: () {
              if (selectedLevel == level) {
                onLevelChanged(Level.all);
              } else {
                onLevelChanged(level);
              }
            },
          ),
        ),
        _PreserveToggle(value: preserveLogs, onChanged: onPreserveChanged),
        _ClearButton(onPressed: onClearLogs),
      ],
    );
  }
}

/// A search text field with an inline regex toggle icon.
///
/// Properly owns its [TextEditingController] to avoid memory leaks.
class _SearchField extends StatefulWidget {
  final String query;
  final bool useRegex;
  final ValueChanged<String> onChanged;
  final VoidCallback onRegexToggled;

  const _SearchField({
    required this.query,
    required this.useRegex,
    required this.onChanged,
    required this.onRegexToggled,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Filter logs',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _RegexToggleButton(
          isActive: widget.useRegex,
          onPressed: widget.onRegexToggled,
        ),
        border: OutlineInputBorder(),
      ),
    );
  }
}

/// A small `.*` icon button that toggles regex search mode.
///
/// Highlights with the primary color when regex mode is active.
class _RegexToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _RegexToggleButton({required this.isActive, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Text(
        '.*',
        style: TextTheme.of(context).labelMedium?.copyWith(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onPressed: onPressed,
      tooltip: isActive ? 'Disable regex' : 'Enable regex',
    );
  }
}

/// A labeled toggle switch for the PRESERVE feature.
///
/// When enabled, logs are kept across hot reloads.
class _PreserveToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreserveToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('PRESERVE', style: TextTheme.of(context).labelMedium),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('CLEAR', style: TextTheme.of(context).labelMedium),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onPressed,
          tooltip: 'Clear Logs',
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        ),
      ],
    );
  }
}

/// A single filter chip for a log level.
///
/// Uses [FilterChip] to toggle between active and inactive states
/// with a color matching the log level severity.
class _LevelFilterChip extends StatelessWidget {
  final Level level;
  final bool isSelected;
  final VoidCallback onSelected;

  const _LevelFilterChip({
    required this.level,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(level.label, style: TextStyle(color: Colors.white)),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      color: WidgetStateProperty.all(level.color),
    );
  }
}
