import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';

import '../log_entry.dart';
import '../logger_extension_controller.dart';
import 'log_detail_panel.dart';
import 'log_list_panel.dart';
import 'logger_toolbar.dart';

/// The main view for the logger extension.
///
/// Displays a split-pane layout with a log list on the left
/// and a detail panel on the right, matching the DevTools style.
class LoggerView extends StatefulWidget {
  const LoggerView({super.key});

  @override
  State<LoggerView> createState() => _LoggerViewState();
}

class _LoggerViewState extends State<LoggerView> {
  late final LoggerExtensionController _controller;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier<int?>(null);

  @override
  void initState() {
    super.initState();
    _controller = LoggerExtensionController();
    _controller.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onLogsChanged);
    _selectedIndex.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Resets the selected index when the filtered logs change.
  ///
  /// This prevents showing stale details if a filter narrows the list
  /// down past the previously selected index.
  void _onLogsChanged() {
    final currentIdx = _selectedIndex.value;
    if (currentIdx == null) return;

    if (currentIdx >= _controller.filteredLogs.length) {
      _selectedIndex.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => _LoggerToolbarWrapper(
            controller: _controller,
            onClearLogs: () {
              _controller.clearLogs();
              _selectedIndex.value = null;
            },
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _SplitPane(
              filteredLogs: _controller.filteredLogs,
              selectedIndex: _selectedIndex,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bridges the [LoggerExtensionController] to the [LoggerToolbar] widget.
///
/// Reads the current filter state from [controller] and forwards user
/// interactions back as setter calls. Extracted from [_LoggerViewState]
/// to avoid a private widget-returning method.
class _LoggerToolbarWrapper extends StatelessWidget {
  final LoggerExtensionController controller;
  final VoidCallback onClearLogs;

  const _LoggerToolbarWrapper({
    required this.controller,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    return LoggerToolbar(
      searchQuery: controller.searchQuery,
      selectedLevel: controller.selectedLevel,
      useRegex: controller.useRegex,
      preserveLogs: controller.preserveLogs,
      onSearchChanged: (value) => controller.searchQuery = value,
      onLevelChanged: (lvl) => controller.selectedLevel = lvl,
      onRegexChanged: (value) => controller.useRegex = value,
      onPreserveChanged: (value) => controller.preserveLogs = value,
      onClearLogs: onClearLogs,
    );
  }
}

/// The horizontal split between the log list and detail panels.
///
/// Separated from [_LoggerViewState] to keep the build method
/// under the line-count guideline.
class _SplitPane extends StatelessWidget {
  final List<LogEntry> filteredLogs;
  final ValueNotifier<int?> selectedIndex;

  const _SplitPane({required this.filteredLogs, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return SplitPane(
      axis: Axis.horizontal,
      initialFractions: [0.6, 0.4],
      children: [
        OutlineDecoration(
          child: ValueListenableBuilder<int?>(
            valueListenable: selectedIndex,
            builder: (context, selectedIdx, _) => LogListPanel(
              logs: filteredLogs,
              selectedIndex: selectedIdx,
              onLogSelected: (index) => selectedIndex.value = index,
            ),
          ),
        ),
        OutlineDecoration(
          child: ValueListenableBuilder<int?>(
            valueListenable: selectedIndex,
            builder: (context, selectedIdx, _) {
              if (selectedIdx == null || selectedIdx >= filteredLogs.length) {
                return const _EmptyDetailPlaceholder();
              }
              return LogDetailPanel(log: filteredLogs[selectedIdx]);
            },
          ),
        ),
      ],
    );
  }
}

/// Placeholder shown when no log is selected in the detail panel.
class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.segment_rounded, size: 48),
          Text(
            'Select a log to view details',
            style: TextTheme.of(context).headlineSmall,
          ),
        ],
      ),
    );
  }
}
