import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

import '../models/log_entry.dart';

/// A widget to display a single log entry.
class LogItem extends StatelessWidget {
  final LogEntry log;

  const LogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelColor = _getLevelColor(colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: levelColor.withValues(alpha: 0.2), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      color: levelColor.withValues(alpha: 0.05),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: levelColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: levelColor.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        title: Text(
          log.message,
          style: GoogleFonts.firaCode(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${log.level.name.toUpperCase()} • ${log.time.toLocal().toString().split(' ').last}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        children: [
          if (log.error != null || log.stackTrace != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                border: Border(
                  top: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (log.error != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 14,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Error',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      log.error!,
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (log.stackTrace != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.stacked_line_chart,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stack Trace',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      log.stackTrace!,
                      style: GoogleFonts.firaCode(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getLevelColor(ColorScheme colorScheme) {
    switch (log.level) {
      case Level.trace:
      case Level.debug:
        return colorScheme.outline;
      case Level.info:
        return colorScheme.primary;
      case Level.warning:
        return Colors.orange; // ColorScheme doesn't have a direct warning color
      case Level.error:
        return colorScheme.error;
      case Level.fatal:
        return colorScheme.tertiary;
      case Level.off:
        return colorScheme.onSurface;
      default:
        return colorScheme.outline;
    }
  }
}
