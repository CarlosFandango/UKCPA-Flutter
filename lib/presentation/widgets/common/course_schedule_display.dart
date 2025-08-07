import 'package:flutter/material.dart';
import '../../../domain/entities/course.dart';
import '../../../domain/entities/course_session.dart';
import '../../../core/utils/date_utils.dart' as date_utils;
import '../../../core/utils/text_utils.dart';

/// Reusable component for displaying course schedule information
/// Adapts to different contexts: booking, user portal, video viewing
class CourseScheduleDisplay extends StatelessWidget {
  final Course? course;
  final List<CourseSession>? sessions;
  final ScheduleDisplayMode mode;
  final ScheduleDisplayStyle style;
  final bool showUpcomingSessions;
  final bool showProgress;
  final int? maxSessionsToShow;
  final VoidCallback? onViewAllSessions;

  const CourseScheduleDisplay({
    super.key,
    this.course,
    this.sessions,
    this.mode = ScheduleDisplayMode.overview,
    this.style = ScheduleDisplayStyle.card,
    this.showUpcomingSessions = false,
    this.showProgress = false,
    this.maxSessionsToShow,
    this.onViewAllSessions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (mode) {
      case ScheduleDisplayMode.overview:
        return _buildOverviewMode(theme);
      case ScheduleDisplayMode.detailed:
        return _buildDetailedMode(theme);
      case ScheduleDisplayMode.upcoming:
        return _buildUpcomingMode(theme);
      case ScheduleDisplayMode.progress:
        return _buildProgressMode(theme);
    }
  }

  Widget _buildOverviewMode(ThemeData theme) {
    if (course == null) return const SizedBox.shrink();
    
    final items = <Widget>[];
    
    // Schedule Summary
    if (course!.scheduleInfo.timeText.isNotEmpty) {
      items.add(_buildScheduleItem(
        Icons.access_time,
        'Time',
        course!.scheduleInfo.timeText,
        theme,
      ));
    }
    
    // Date Range
    if (course!.startDateTime != null && course!.endDateTime != null) {
      items.add(_buildScheduleItem(
        Icons.calendar_today,
        'Dates',
        date_utils.DateUtils.getDateRange(course!.startDateTime!, course!.endDateTime!),
        theme,
      ));
    }
    
    // Duration
    if (course!.weeks != null) {
      items.add(_buildScheduleItem(
        Icons.repeat,
        'Duration',
        TextUtils.formatWeeks(course!.weeks!),
        theme,
      ));
    }

    return _wrapInContainer(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Schedule', theme),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: item,
          )),
        ],
      ),
    );
  }

  Widget _buildDetailedMode(ThemeData theme) {
    final sessionsToShow = sessions ?? course?.courseSessions ?? [];
    if (sessionsToShow.isEmpty) return _buildOverviewMode(theme);
    
    final limitedSessions = maxSessionsToShow != null 
        ? sessionsToShow.take(maxSessionsToShow!).toList()
        : sessionsToShow;

    return _wrapInContainer(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Sessions', theme),
              if (maxSessionsToShow != null && sessionsToShow.length > maxSessionsToShow!)
                TextButton(
                  onPressed: onViewAllSessions,
                  child: Text('View All (${sessionsToShow.length})'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...limitedSessions.map((session) => _buildSessionItem(session, theme)),
        ],
      ),
    );
  }

  Widget _buildUpcomingMode(ThemeData theme) {
    final allSessions = sessions ?? course?.courseSessions ?? [];
    final upcomingSessions = allSessions.where((session) {
      return session.startDateTime.isAfter(DateTime.now());
    }).take(3).toList();
    
    if (upcomingSessions.isEmpty) {
      return _wrapInContainer(
        theme,
        Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Course Complete',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All sessions have been completed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _wrapInContainer(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Upcoming Sessions', theme),
          const SizedBox(height: 12),
          ...upcomingSessions.map((session) => _buildUpcomingSessionItem(session, theme)),
        ],
      ),
    );
  }

  Widget _buildProgressMode(ThemeData theme) {
    final allSessions = sessions ?? course?.courseSessions ?? [];
    if (allSessions.isEmpty) return const SizedBox.shrink();
    
    final completedSessions = allSessions.where((session) {
      return session.endDateTime.isBefore(DateTime.now());
    }).length;
    
    final totalSessions = allSessions.length;
    final progress = totalSessions > 0 ? completedSessions / totalSessions : 0.0;

    return _wrapInContainer(
      theme,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Progress', theme),
              Text(
                '$completedSessions of $totalSessions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% Complete',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionItem(CourseSession session, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date_utils.DateUtils.getDateWithDay(session.startDateTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date_utils.DateUtils.getTimeRange(
                    session.startDateTime,
                    session.endDateTime,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          _buildSessionStatus(session, theme),
        ],
      ),
    );
  }

  Widget _buildUpcomingSessionItem(CourseSession session, ThemeData theme) {
    final isToday = date_utils.DateUtils.isToday(session.startDateTime);
    final isTomorrow = date_utils.DateUtils.isTomorrow(session.startDateTime);
    final isHappeningSoon = date_utils.DateUtils.isHappeningSoon(session.startDateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday 
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : isTomorrow
                ? theme.colorScheme.secondaryContainer.withOpacity(0.5)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday || isTomorrow
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          if (isHappeningSoon)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'SOON',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date_utils.DateUtils.getCourseCardDateString(session.startDateTime),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday || isTomorrow 
                        ? theme.colorScheme.primary
                        : null,
                  ),
                ),
                if (session.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    session.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          if (isToday)
            Icon(
              Icons.star,
              color: theme.colorScheme.primary,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildSessionStatus(CourseSession session, ThemeData theme) {
    final now = DateTime.now();
    final isCompleted = session.endDateTime.isBefore(now);
    final isActive = date_utils.DateUtils.isCurrentlyActive(
      session.startDateTime,
      session.endDateTime,
    );

    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'LIVE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onTertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isCompleted) {
      return Icon(
        Icons.check_circle,
        color: theme.colorScheme.primary,
        size: 20,
      );
    }

    return Icon(
      Icons.schedule,
      color: theme.colorScheme.onSurface.withOpacity(0.5),
      size: 20,
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _wrapInContainer(ThemeData theme, Widget child) {
    switch (style) {
      case ScheduleDisplayStyle.card:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: child,
        );
      case ScheduleDisplayStyle.plain:
        return child;
      case ScheduleDisplayStyle.section:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
    }
  }
}

/// Display modes for schedule information
enum ScheduleDisplayMode {
  overview,    // Basic schedule info (time, dates, duration)
  detailed,    // Full session list
  upcoming,    // Only upcoming sessions
  progress,    // Progress tracking for user portal
}

/// Visual styles for schedule display
enum ScheduleDisplayStyle {
  card,        // Card container with border
  plain,       // No container styling
  section,     // Section background styling
}

/// Factory methods for common schedule display configurations
extension CourseScheduleDisplayFactories on CourseScheduleDisplay {
  /// Create for course booking context
  static Widget forBooking({
    required Course course,
  }) {
    return CourseScheduleDisplay(
      course: course,
      mode: ScheduleDisplayMode.overview,
      style: ScheduleDisplayStyle.plain,
    );
  }

  /// Create for user portal context
  static Widget forUserPortal({
    required Course course,
    List<CourseSession>? sessions,
    bool showProgress = true,
  }) {
    return CourseScheduleDisplay(
      course: course,
      sessions: sessions,
      mode: showProgress ? ScheduleDisplayMode.progress : ScheduleDisplayMode.upcoming,
      style: ScheduleDisplayStyle.card,
      showUpcomingSessions: true,
      showProgress: showProgress,
      maxSessionsToShow: 5,
    );
  }

  /// Create for session management
  static Widget forSessionManagement({
    required List<CourseSession> sessions,
    VoidCallback? onViewAllSessions,
  }) {
    return CourseScheduleDisplay(
      sessions: sessions,
      mode: ScheduleDisplayMode.detailed,
      style: ScheduleDisplayStyle.card,
      maxSessionsToShow: 10,
      onViewAllSessions: onViewAllSessions,
    );
  }
}