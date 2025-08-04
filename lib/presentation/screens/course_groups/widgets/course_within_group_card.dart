import 'package:flutter/material.dart';
import '../../../../domain/entities/course.dart';
import '../../../../core/utils/money_formatter.dart';
import 'add_to_basket_button.dart';

/// Card widget for displaying an individual course within a course group
class CourseWithinGroupCard extends StatelessWidget {
  final Course course;
  final VoidCallback onAddToBasket;
  final VoidCallback onTapCourse;

  const CourseWithinGroupCard({
    super.key,
    required this.course,
    required this.onAddToBasket,
    required this.onTapCourse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = course.isAvailable;

    return Card(
      elevation: isAvailable ? 2 : 1,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAvailable 
              ? theme.colorScheme.primary.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTapCourse,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCourseInfo(theme, isAvailable),
                  ),
                  const SizedBox(width: 12),
                  _buildCourseTypeChip(theme),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Course Details
              _buildCourseDetails(theme),
              
              const SizedBox(height: 16),
              
              // Price and Action Section
              _buildPriceAndActions(theme, isAvailable),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo(ThemeData theme, bool isAvailable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Name
        Text(
          course.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isAvailable 
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Course Subtitle
        if (course.subtitle != null && course.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            course.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Availability Status
        const SizedBox(height: 8),
        _buildAvailabilityStatus(theme, isAvailable),
      ],
    );
  }

  Widget _buildCourseTypeChip(ThemeData theme) {
    final isOnline = course is OnlineCourse;
    final isStudio = course is StudioCourse;
    
    Color chipColor;
    IconData chipIcon;
    String chipText;
    
    if (isOnline) {
      chipColor = theme.colorScheme.tertiary;
      chipIcon = Icons.computer;
      chipText = 'Online';
    } else if (isStudio) {
      chipColor = theme.colorScheme.secondary;
      chipIcon = Icons.place;
      chipText = 'Studio';
    } else {
      chipColor = theme.colorScheme.outline;
      chipIcon = Icons.class_;
      chipText = 'Course';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipIcon,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatus(ThemeData theme, bool isAvailable) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isAvailable 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isAvailable ? 'Available' : 'Not Available',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isAvailable 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseDetails(ThemeData theme) {
    final details = <Widget>[];
    
    // Location (for studio courses)
    if (course is StudioCourse) {
      final studioCourse = course as StudioCourse;
      final locationName = _getLocationDisplayName(studioCourse.location);
      details.add(_buildDetailItem(
        Icons.location_on,
        locationName,
        theme,
      ));
    }
    
    // Course Level
    if (course.level != null) {
      final levelName = _getLevelDisplayName(course.level!);
      details.add(_buildDetailItem(
        Icons.trending_up,
        'Level: $levelName',
        theme,
      ));
    }
    
    // Age Group (from attendance types)
    if (course.attendanceTypes.isNotEmpty) {
      final attendanceType = course.attendanceTypes.first;
      final ageGroup = _getAttendanceTypeDisplayName(attendanceType);
      details.add(_buildDetailItem(
        Icons.people,
        ageGroup,
        theme,
      ));
    }
    
    if (details.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: details
          .expand((widget) => [widget, const SizedBox(height: 4)])
          .toList()
        ..removeLast(), // Remove last spacer
    );
  }

  Widget _buildDetailItem(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndActions(ThemeData theme, bool isAvailable) {
    return Row(
      children: [
        // Price
        Expanded(
          child: _buildPriceInfo(theme),
        ),
        
        const SizedBox(width: 12),
        
        // Add to Basket Button
        AddToBasketButton(
          course: course,
          onPressed: isAvailable ? onAddToBasket : null,
          isEnabled: isAvailable,
        ),
      ],
    );
  }

  Widget _buildPriceInfo(ThemeData theme) {
    final price = course.price;
    final isDiscounted = course.originalPrice != null && 
                          course.originalPrice! > price;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Price
        Text(
          MoneyFormatter.formatPenceWithFreeCheck(price),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: MoneyFormatter.isFree(price)
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        
        // Original Price (if discounted)
        if (isDiscounted) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                MoneyFormatter.formatPence(course.originalPrice!),
                style: theme.textTheme.bodySmall?.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SALE',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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

  /// Convert Level enum to display name
  String _getLevelDisplayName(Level level) {
    switch (level) {
      case Level.beginner:
        return 'Beginner';
      case Level.intermediate:
        return 'Intermediate';
      case Level.advanced:
        return 'Advanced';
      case Level.kidsFoundation:
        return 'Kids Foundation';
      case Level.kids1:
        return 'Kids Level 1';
      case Level.kids2:
        return 'Kids Level 2';
    }
  }

  /// Convert AttendanceType enum to display name
  String _getAttendanceTypeDisplayName(AttendanceType attendanceType) {
    switch (attendanceType) {
      case AttendanceType.children:
        return 'Children';
      case AttendanceType.adults:
        return 'Adults';
    }
  }
}

/// Extension to capitalize first letter
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}