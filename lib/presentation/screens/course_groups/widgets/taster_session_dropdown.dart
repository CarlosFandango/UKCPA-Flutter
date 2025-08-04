import 'package:flutter/material.dart';
import '../../../../domain/entities/course_session.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/text_utils.dart';

/// Widget that displays taster session selection dropdown matching website design
class TasterSessionDropdown extends StatefulWidget {
  final List<CourseSession> futureSessions;
  final int tasterPrice;
  final bool disabled;
  final VoidCallback? onSessionSelect;
  final VoidCallback? onBookTaster;

  const TasterSessionDropdown({
    super.key,
    required this.futureSessions,
    required this.tasterPrice,
    this.disabled = false,
    this.onSessionSelect,
    this.onBookTaster,
  });

  @override
  State<TasterSessionDropdown> createState() => _TasterSessionDropdownState();
}

class _TasterSessionDropdownState extends State<TasterSessionDropdown> {
  CourseSession? selectedSession;

  @override
  void initState() {
    super.initState();
    if (widget.futureSessions.isNotEmpty) {
      selectedSession = widget.futureSessions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.futureSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with info icon and title
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Try a Taster Class',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            'Try our taster classes before committing to the full course',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Session selection label
          Text(
            'Select a class:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),

          // Session dropdown
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CourseSession>(
                value: selectedSession,
                isExpanded: true,
                onChanged: widget.disabled ? null : (session) {
                  setState(() {
                    selectedSession = session;
                  });
                  if (session != null) {
                    widget.onSessionSelect?.call();
                  }
                },
                items: widget.futureSessions.map((session) {
                  return DropdownMenuItem<CourseSession>(
                    value: session,
                    child: Text(
                      _formatSessionOption(session),
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selected session details
          if (selectedSession != null) ...[
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Date and day
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          date_utils.DateUtils.getDateWithDay(selectedSession!.startDateTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: theme.colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          date_utils.DateUtils.getTimeRange(
                            selectedSession!.startDateTime,
                            selectedSession!.endDateTime,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price and book button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        TextUtils.formatPrice(widget.tasterPrice),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: widget.disabled ? null : () {
                            widget.onBookTaster?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.tertiary,
                            foregroundColor: theme.colorScheme.onTertiary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Book Taster',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format session option for dropdown display
  String _formatSessionOption(CourseSession session) {
    final date = date_utils.DateUtils.getDateString(session.startDateTime);
    final day = date_utils.DateUtils.getDayFromDate(session.startDateTime);
    final time = date_utils.DateUtils.getTimeFromDate(session.startDateTime);
    return '$date - $day at $time';
  }
}

/// Extension for easier creation of taster session dropdowns
extension TasterSessionDropdownExtensions on TasterSessionDropdown {
  /// Create a taster session dropdown with preset styling
  static Widget create({
    required List<CourseSession> futureSessions,
    required int tasterPrice,
    bool disabled = false,
    VoidCallback? onSessionSelect,
    VoidCallback? onBookTaster,
  }) {
    return TasterSessionDropdown(
      futureSessions: futureSessions,
      tasterPrice: tasterPrice,
      disabled: disabled,
      onSessionSelect: onSessionSelect,
      onBookTaster: onBookTaster,
    );
  }
}