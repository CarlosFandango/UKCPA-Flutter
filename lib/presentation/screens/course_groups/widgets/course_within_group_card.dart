import 'package:flutter/material.dart';
import '../../../../domain/entities/course.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/schedule_utils.dart';
import '../../../../core/utils/text_utils.dart';
import 'course_type_badge.dart';
import 'taster_session_dropdown.dart';
import 'deposit_payment_section.dart';

/// Card widget for displaying an individual course within a course group
/// Enhanced to match the website's course display exactly
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
    final isFullyBooked = course.fullyBooked;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Course Image (if available)
          if (course.image != null) _buildCourseImage(theme),
          
          // Course Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Course Title and Badge
                _buildCourseHeader(theme),
                const SizedBox(height: 12),
                
                // Course Details Grid (matching website layout)
                _buildCourseDetailsGrid(theme),
                const SizedBox(height: 16),
                
                // Price and Main Action
                _buildPriceAndMainAction(theme, isAvailable, isFullyBooked),
                
                // Taster Session Option (if available)
                if (_shouldShowTasterSessions()) ...[
                  const SizedBox(height: 16),
                  _buildTasterSessionSection(),
                ],
                
                // Deposit Payment Option (if available)
                if (_shouldShowDepositOption()) ...[
                  const SizedBox(height: 16),
                  _buildDepositPaymentSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build course image with proper positioning
  Widget _buildCourseImage(ThemeData theme) {
    final imagePosition = course.imagePosition;
    final positionX = imagePosition?.X ?? 0;
    final positionY = imagePosition?.Y ?? 0;
    
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        image: DecorationImage(
          image: NetworkImage(course.image!),
          fit: BoxFit.cover,
          alignment: Alignment(
            (positionX / 50) - 1, // Convert 0-100 to -1 to 1
            (positionY / 50) - 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          
          // Course type badge
          Positioned(
            top: 8,
            left: 8,
            child: CourseTypeBadge.fromCourse(
              course,
              size: CourseTypeBadgeSize.small,
            ),
          ),
        ],
      ),
    );
  }

  /// Build course header with title and badge
  Widget _buildCourseHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Course Name (centered like website)
        Text(
          course.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Course Subtitle (if available)
        if (course.subtitle != null && course.subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            course.subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Build course details grid matching website layout exactly
  Widget _buildCourseDetailsGrid(ThemeData theme) {
    final scheduleInfo = course.scheduleInfo;
    final detailItems = <Widget>[];
    
    // Smart Schedule Display - Time (matching website ScheduleDisplay component)
    if (scheduleInfo.timeText.isNotEmpty) {
      detailItems.add(
        _buildDetailGridItem(
          Icons.access_time,
          'Time',
          scheduleInfo.timeText,
          theme,
        ),
      );
    }
    
    // Dates (matching website date format)
    if (course.startDateTime != null && course.endDateTime != null) {
      detailItems.add(
        _buildDetailGridItem(
          Icons.calendar_today,
          'Dates',
          date_utils.DateUtils.getDateRange(course.startDateTime!, course.endDateTime!),
          theme,
        ),
      );
    }
    
    // Weeks (matching website weeks display)
    if (course.weeks != null) {
      detailItems.add(
        _buildDetailGridItem(
          Icons.repeat,
          'Weeks',
          course.weeks.toString(),
          theme,
        ),
      );
    }
    
    // Level (matching website level formatting)
    detailItems.add(
      _buildDetailGridItem(
        Icons.star_outline,
        'Level',
        course.levelDisplay,
        theme,
      ),
    );
    
    // Age Group (matching website age group formatting)
    detailItems.add(
      _buildDetailGridItem(
        Icons.people_outline,
        'Age Group',
        course.ageGroupDisplay,
        theme,
      ),
    );
    
    // Address/Location for Studio courses (matching website location display)
    if (course.type.contains('Studio') && course.address != null) {
      detailItems.add(
        _buildDetailGridItem(
          Icons.location_on,
          'Location',
          _formatAddressDisplay(course.address!),
          theme,
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 12,
      childAspectRatio: 3,
      children: detailItems,
    );
  }

  /// Build individual detail grid item
  Widget _buildDetailGridItem(IconData icon, String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Build price section and main add to basket button
  Widget _buildPriceAndMainAction(ThemeData theme, bool isAvailable, bool isFullyBooked) {
    final effectivePrice = course.currentPrice ?? course.price;
    
    return Column(
      children: [
        Text(
          '£${(effectivePrice / 100).toStringAsFixed(2)}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAvailable && !isFullyBooked ? onAddToBasket : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isFullyBooked 
                  ? 'Fully booked' 
                  : isAvailable 
                      ? 'Add to basket'
                      : 'Not Available',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build taster session section
  Widget _buildTasterSessionSection() {
    if (!course.hasTasterClasses || course.futureCourseSessions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return TasterSessionDropdown(
      futureSessions: course.futureCourseSessions,
      tasterPrice: course.tasterPrice,
      disabled: course.fullyBooked,
      onBookTaster: () {
        // TODO: Handle taster booking in Phase 3
      },
    );
  }

  /// Build deposit payment section
  Widget _buildDepositPaymentSection() {
    return DepositPaymentSection(
      course: course,
      disabled: course.fullyBooked,
      onPayDeposit: () {
        // TODO: Handle deposit payment in Phase 3
      },
    );
  }

  /// Check if taster sessions should be shown
  bool _shouldShowTasterSessions() {
    return course.hasTasterClasses && 
           course.tasterPrice > 0 && 
           course.futureCourseSessions.isNotEmpty;
  }

  /// Check if deposit option should be shown
  bool _shouldShowDepositOption() {
    return course.isAcceptingDeposits && 
           course.depositPrice != null && 
           course.depositPrice! > 0;
  }

  /// Format address for location display (matching website CourseLocation component)
  String _formatAddressDisplay(Address address) {
    final parts = <String>[];
    
    if (address.line1 != null && address.line1!.isNotEmpty) {
      parts.add(address.line1!);
    }
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    if (address.postCode != null && address.postCode!.isNotEmpty) {
      parts.add(address.postCode!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Studio Location';
  }
}