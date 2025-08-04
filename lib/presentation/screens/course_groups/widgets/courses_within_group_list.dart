import 'package:flutter/material.dart';
import '../../../../domain/entities/course_group.dart';
import '../../../../domain/entities/course.dart';
import 'course_within_group_card.dart';

/// Widget that displays the list of individual courses within a course group
class CoursesWithinGroupList extends StatelessWidget {
  final CourseGroup courseGroup;

  const CoursesWithinGroupList({
    super.key,
    required this.courseGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Group Description
        if (courseGroup.description != null && courseGroup.description!.isNotEmpty) ...[
          _buildDescription(theme),
          const SizedBox(height: 24),
        ],
        
        // Course Group Statistics
        _buildCourseGroupStats(theme),
        const SizedBox(height: 24),
        
        // Individual Courses Section
        _buildCoursesSection(context, theme),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About This Course Group',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Text(
            courseGroup.description!,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseGroupStats(ThemeData theme) {
    final stats = <Widget>[];
    
    // Number of courses
    if (courseGroup.courses.isNotEmpty) {
      stats.add(_buildStatCard(
        icon: Icons.class_,
        label: 'Courses',
        value: courseGroup.courses.length.toString(),
        theme: theme,
      ));
    }
    
    // Available courses count
    final availableCourses = courseGroup.courses.where((course) => course.isAvailable).length;
    if (availableCourses > 0) {
      stats.add(_buildStatCard(
        icon: Icons.event_available,
        label: 'Available',
        value: availableCourses.toString(),
        theme: theme,
      ));
    }
    
    // Unique locations count
    final uniqueLocations = <String>{};
    for (final course in courseGroup.courses) {
      if (course is StudioCourse) {
        final studioCourse = course as StudioCourse;
        uniqueLocations.add(_getLocationDisplayName(studioCourse.location));
      }
    }
    if (uniqueLocations.isNotEmpty) {
      stats.add(_buildStatCard(
        icon: Icons.location_on,
        label: 'Locations',
        value: uniqueLocations.length.toString(),
        theme: theme,
      ));
    }
    
    if (stats.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: stats
              .expand((widget) => [widget, const SizedBox(width: 12)])
              .toList()
            ..removeLast(), // Remove last spacer
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection(BuildContext context, ThemeData theme) {
    if (courseGroup.courses.isEmpty) {
      return _buildEmptyCoursesState(theme);
    }

    // Sort courses: available first, then by name
    final sortedCourses = List<Course>.from(courseGroup.courses);
    sortedCourses.sort((a, b) {
      // Available courses first
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;
      
      // Then sort by name
      return a.name.compareTo(b.name);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Courses',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${sortedCourses.length} courses',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Course cards
        ...sortedCourses.map((course) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CourseWithinGroupCard(
            course: course,
            onAddToBasket: () => _handleAddToBasket(context, course),
            onTapCourse: () => _handleCourseTap(context, course),
          ),
        )),
      ],
    );
  }

  Widget _buildEmptyCoursesState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.class_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Courses Available',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This course group doesn\'t have any individual courses available at the moment.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddToBasket(BuildContext context, Course course) {
    // TODO: Implement basket functionality in Phase 3
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add to basket: ${course.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  void _handleCourseTap(BuildContext context, Course course) {
    // TODO: Navigate to individual course detail screen (Slice 2.5)
    // For now, show course info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.subtitle != null) ...[
              Text(course.subtitle!),
              const SizedBox(height: 8),
            ],
            Text('Type: ${course.runtimeType.toString().replaceAll('Course', '')}'),
            if (course is StudioCourse) ...[
              const SizedBox(height: 4),
              Text('Location: ${_getLocationDisplayName((course as StudioCourse).location)}'),
            ],
            const SizedBox(height: 8),
            Text('Status: ${course.isAvailable ? 'Available' : 'Not Available'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Convert Location enum to display name
  String _getLocationDisplayName(Location location) {
    switch (location) {
      case Location.online:
        return 'Online';
      case Location.studio1:
        return 'Studio 1';
      case Location.studio2:
        return 'Studio 2';
      case Location.external:
        return 'External Venue';
    }
  }
}