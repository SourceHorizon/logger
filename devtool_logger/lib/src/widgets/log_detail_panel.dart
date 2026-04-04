import 'package:devtools_app_shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../log_entry.dart';

/// The right panel displaying detailed information about a selected log entry.
///
/// Shows sections matching the DevTools UI:
/// - **MESSAGE PAYLOAD**: The raw log message text.
/// - **STRUCTURE**: A tree view of any structured data in the message.
/// - **ERROR**: The error object if present.
/// - **STACK TRACE**: A frame-by-frame view parsed from the raw trace.
///
/// All string and JSON values are read from pre-parsed [LogEntry] fields —
/// no `.toString()` calls or JSON decoding happen during the build phase.
class LogDetailPanel extends StatelessWidget {
  /// The log entry to display details for.
  final LogEntry log;

  const LogDetailPanel({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlineDecoration.onlyBottom(
          child: _DetailHeader(onCopy: () => _copyToClipboard(context)),
        ),
        Expanded(
          child: SelectionArea(child: _DetailContent(log: log)),
        ),
        OutlineDecoration.onlyTop(child: _DetailFooter(log: log)),
      ],
    );
  }

  void _copyToClipboard(BuildContext context) {
    // Uses pre-resolved strings — no repeated .toString() here.
    final buffer = StringBuffer()
      ..writeln('Level: ${log.levelLabel}')
      ..writeln('Time: ${log.time}')
      ..writeln('Message: ${log.messageString}');

    if (log.errorString != null) {
      buffer.writeln('Error: ${log.errorString}');
    }
    if (log.stackTraceString != null) {
      buffer.writeln('StackTrace: ${log.stackTraceString}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Log copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        width: 220,
      ),
    );
  }
}

/// Header bar with "LOG DETAIL" title and copy action.
class _DetailHeader extends StatelessWidget {
  final VoidCallback onCopy;

  const _DetailHeader({required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Text(
            'LOG DETAIL',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy_outlined, size: 18),
            onPressed: onCopy,
            tooltip: 'Copy log',
            style: IconButton.styleFrom(
              minimumSize: const Size(32, 32),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable body containing all detail sections.
class _DetailContent extends StatelessWidget {
  final LogEntry log;

  const _DetailContent({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSection(
            title: 'MESSAGE PAYLOAD',
            child: _CodeBlock(
              text: log.messageString, // Pre-converted — no allocation.
              color: colorScheme.onSurface,
            ),
          ),
          _DetailSection(
            title: 'STRUCTURE',
            // parsedJson is null when message isn't valid JSON.
            child: _StructureView(
              messageString: log.messageString,
              parsedJson: log.parsedJson,
            ),
          ),
          if (log.errorString != null)
            _DetailSection(
              title: 'ERROR',
              child: _CodeBlock(
                text: log.errorString!,
                color: colorScheme.error,
                backgroundColor: colorScheme.errorContainer.withValues(
                  alpha: 0.2,
                ),
              ),
            ),
          if (log.parsedStackFrames.isNotEmpty)
            _DetailSection(
              title: 'STACK TRACE',
              // Uses pre-parsed frames from LogEntry — no regex at build time.
              child: _StackTraceView(frames: log.parsedStackFrames),
            )
          else if (log.stackTraceString != null)
            _DetailSection(
              title: 'STACK TRACE',
              child: _CodeBlock(
                text: log.stackTraceString!,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom bar showing level and timestamp metadata.
class _DetailFooter extends StatelessWidget {
  final LogEntry log;

  const _DetailFooter({required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Level: ${log.levelLabel}', style: style), // Pre-resolved label.
          const SizedBox(width: 16),
          Text('Time: ${log.colonTime}', style: style), // Pre-formatted time.
        ],
      ),
    );
  }
}

/// A section header with a title label and content below.
class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// A styled monospace text container used for message, error, and stack trace.
///
/// Extracted to eliminate the repeated Container+SelectableText pattern
/// that was duplicated across each detail section.
class _CodeBlock extends StatelessWidget {
  final String text;
  final Color color;
  final Color? backgroundColor;

  const _CodeBlock({
    required this.text,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color),
      ),
    );
  }
}

/// Displays the structure section of a log entry.
///
/// Receives the already-parsed [parsedJson] from [LogEntry] —
/// no JSON decoding happens here. Falls back to a plain-text
/// code block when [parsedJson] is null.
class _StructureView extends StatelessWidget {
  final String messageString;
  final Object? parsedJson;

  const _StructureView({required this.messageString, required this.parsedJson});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (parsedJson != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _JsonTreeNode(data: parsedJson!, rootKey: 'data'),
      );
    }

    return _CodeBlock(text: messageString, color: colorScheme.onSurfaceVariant);
  }
}

// ── Stack trace view ──────────────────────────────────────────────────────

/// Renders a list of [ParsedStackFrame]s as a nicely formatted frame table.
///
/// Each row shows:
/// - A numbered badge (`#N`)
/// - The symbol (method / closure), if available
/// - The file location (package path + line:col)
///
/// Frames are separated by a thin divider. The entire block is selectable
/// via long-press on the copy icon in the header.
class _StackTraceView extends StatelessWidget {
  /// Pre-parsed frames — no regex work happens here.
  final List<ParsedStackFrame> frames;

  const _StackTraceView({required this.frames});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < frames.length; i++) ...[
            _StackFrameRow(frame: frames[i], isFirst: i == 0),
            if (i < frames.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.25),
              ),
          ],
        ],
      ),
    );
  }
}

/// A single row in the stack trace view.
class _StackFrameRow extends StatelessWidget {
  final ParsedStackFrame frame;

  /// Whether this is the top-most (first visible) frame — shown with accent.
  final bool isFirst;

  const _StackFrameRow({required this.frame, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final symbolStyle = textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
      color: isFirst ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
    );

    final locationStyle = textTheme.bodySmall?.copyWith(
      fontFamily: 'monospace',
      fontSize: 11,
      color: isFirst ? colorScheme.primary : colorScheme.outline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        spacing: 8,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FrameBadge(
            index: frame.index,
            style: locationStyle,
            isFirst: isFirst,
            colorScheme: colorScheme,
          ),
          Expanded(
            child: _LocationChip(
              frame: frame,
              style: locationStyle,
              isFirst: isFirst,
              colorScheme: colorScheme,
            ),
          ),
          if (frame.symbol.isNotEmpty)
            Text(
              frame.symbol,
              style: symbolStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
        ],
      ),
    );
  }
}

/// A small numbered badge showing the frame index.
class _FrameBadge extends StatelessWidget {
  final int index;
  final TextStyle? style;
  final bool isFirst;
  final ColorScheme colorScheme;

  const _FrameBadge({
    required this.index,
    required this.style,
    required this.isFirst,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        '#$index',
        style: style?.copyWith(
          color: isFirst ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: isFirst ? FontWeight.bold : null,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

/// Displays the file location of a stack frame.
class _LocationChip extends StatelessWidget {
  final ParsedStackFrame frame;
  final TextStyle? style;
  final bool isFirst;
  final ColorScheme colorScheme;

  const _LocationChip({
    required this.frame,
    required this.style,
    required this.isFirst,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final hasPrefix = frame.packagePrefix.isNotEmpty;
    return Text.rich(
      TextSpan(
        children: [
          if (hasPrefix) TextSpan(text: frame.packagePrefix),
          TextSpan(text: frame.path),
          if (frame.lineCol.isNotEmpty) TextSpan(text: frame.lineCol),
        ],
      ),
      style: style?.copyWith(
        color: isFirst ? colorScheme.primary : colorScheme.outline,
        fontWeight: isFirst || !hasPrefix ? FontWeight.bold : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── JSON tree ─────────────────────────────────────────────────────────────

/// A recursive tree node widget for displaying JSON data.
///
/// Maps are displayed with expandable keys, lists show indices,
/// and primitive values are displayed inline with type-based coloring.
class _JsonTreeNode extends StatefulWidget {
  final dynamic data;
  final String rootKey;
  final int depth;

  const _JsonTreeNode({
    required this.data,
    required this.rootKey,
    this.depth = 0,
  });

  @override
  State<_JsonTreeNode> createState() => _JsonTreeNodeState();
}

class _JsonTreeNodeState extends State<_JsonTreeNode> {
  bool _isExpanded = true;

  bool get _isExpandable => widget.data is Map || widget.data is List;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final style = TextTheme.of(context).bodyMedium;

    if (!_isExpandable) {
      return _LeafNode(
        depth: widget.depth,
        label: widget.rootKey,
        value: widget.data,
        style: style,
        colorScheme: colorScheme,
      );
    }

    final entries = widget.data is Map
        ? (widget.data as Map).entries.toList()
        : (widget.data as List).asMap().entries.toList();

    final bracket = widget.data is Map ? ('{', '}') : ('[', ']');

    return Padding(
      padding: EdgeInsets.only(left: widget.depth * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                Text(
                  _isExpanded
                      ? '"${widget.rootKey}": ${bracket.$1}'
                      : '"${widget.rootKey}": ${bracket.$1}...${bracket.$2}',
                  style: style?.copyWith(color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            ...entries.map(
              (entry) => _JsonTreeNode(
                data: entry.value,
                rootKey: entry.key.toString(),
                depth: widget.depth + 1,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: (widget.depth + 1) * 16.0),
              child: Text(
                bracket.$2,
                style: style?.copyWith(color: colorScheme.onSurface),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A leaf node (non-expandable) in the JSON tree.
class _LeafNode extends StatelessWidget {
  final int depth;
  final String label;
  final dynamic value;
  final TextStyle? style;
  final ColorScheme colorScheme;

  const _LeafNode({
    required this.depth,
    required this.label,
    required this.value,
    required this.style,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 20),
          Text(
            '"$label": ',
            style: style?.copyWith(color: colorScheme.onSurface),
          ),
          Flexible(
            child: Text(
              _formatValue(value),
              style: style?.copyWith(color: _valueColor),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(dynamic v) {
    if (v is String) return '"$v"';
    return v.toString();
  }

  Color get _valueColor {
    if (value is String) return Colors.green;
    if (value is num) return Colors.blue;
    if (value is bool) return Colors.orange;
    if (value == null) return colorScheme.outline;
    return colorScheme.onSurface;
  }
}
