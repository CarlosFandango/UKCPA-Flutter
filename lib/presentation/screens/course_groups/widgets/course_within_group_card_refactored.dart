import 'package:flutter/material.dart';
import '../../../../domain/entities/course.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/text_utils.dart';
import '../../../widgets/common/base_detail_card.dart';
import '../../../widgets/common/course_action_buttons.dart';
import '../../../widgets/common/course_schedule_display.dart';
import 'course_type_badge.dart';
import 'taster_session_dropdown.dart';
import 'deposit_payment_section.dart';

/// Refactored course card using reusable components
/// Can be easily adapted for different contexts (booking, user portal, video viewing)
class CourseWithinGroupCardRefactored extends StatelessWidget {
  final Course course;
  final CourseCardContext context;
  final VoidCallback? onAddToBasket;
  final VoidCallback? onTapCourse;
  final VoidCallback? onWatchVideos;
  final VoidCallback? onViewProgress;
  final VoidCallback? onDownloadResources;

  const CourseWithinGroupCardRefactored({
    super.key,
    required this.course,
    this.context = CourseCardContext.booking,
    this.onAddToBasket,
    this.onTapCourse,
    this.onWatchVideos,
    this.onViewProgress,
    this.onDownloadResources,
  });

  @override
  Widget build(BuildContext context) {
    return BaseDetailCard.forCourseBooking(
      title: course.name,
      subtitle: course.subtitle,
      imageUrl: course.image,
      courseTypeBadge: CourseTypeBadge.fromCourse(
        course,
        size: CourseTypeBadgeSize.small,
      ),
      courseDetails: _buildCourseDetails(),
      bookingActions: [_buildPrimaryActionButton()],
      paymentOptions: _buildPaymentOptions(),
      onTap: onTapCourse,
    );
  }

  List<DetailGridItem> _buildCourseDetails() {
    final details = <DetailGridItem>[];
    final scheduleInfo = course.scheduleInfo;
    
    // Smart Schedule Display - Time
    if (scheduleInfo.timeText.isNotEmpty) {
      details.add(DetailGridItem(
        icon: Icons.access_time,
        label: 'Time',
        value: scheduleInfo.timeText,
      ));
    }
    
    // Dates
    if (course.startDateTime != null && course.endDateTime != null) {
      details.add(DetailGridItem(
        icon: Icons.calendar_today,
        label: 'Dates',
        value: date_utils.DateUtils.getDateRange(course.startDateTime!, course.endDateTime!),
      ));
    }
    
    // Weeks
    if (course.weeks != null) {
      details.add(DetailGridItem(
        icon: Icons.repeat,
        label: 'Duration',
        value: TextUtils.formatWeeks(course.weeks!),
      ));
    }
    
    // Level
    details.add(DetailGridItem(
      icon: Icons.star_outline,
      label: 'Level',
      value: course.levelDisplay,
    ));
    
    // Age Group
    details.add(DetailGridItem(
      icon: Icons.people_outline,
      label: 'Age Group',
      value: course.ageGroupDisplay,
    ));
    
    // Address/Location for Studio courses
    if (course.type.contains('Studio') && course.address != null) {
      details.add(DetailGridItem(
        icon: Icons.location_on,
        label: 'Location',
        value: _formatAddressDisplay(course.address!),
        iconColor: Theme.of(context).colorScheme.primary,
        isClickable: true,
        onTap: () => _showLocationDetails(),
      ));
    }
    
    return details;
  }

  Widget _buildPrimaryActionButton() {
    switch (context) {
      case CourseCardContext.booking:
        return CourseActionButtons.forBooking(
          primaryLabel: 'Add to basket',
          onAddToBasket: onAddToBasket,
          disabled: !course.isAvailable,
          isFullyBooked: course.fullyBooked,
        );
        
      case CourseCardContext.userPortal:
        return CourseActionButtons.forUserPortal(
          onWatchVideos: onWatchVideos,
          onViewProgress: onViewProgress,
          onDownloadResources: onDownloadResources,
          disabled: false,
        );
        
      case CourseCardContext.videoViewing:
        return CourseActionButtons.forVideoViewing(
          onPlay: onWatchVideos,
          onBookmark: () => _handleBookmark(),
          onShare: () => _handleShare(),
          onDownload: onDownloadResources,
          disabled: false,
        );
    }
  }

  List<Widget> _buildPaymentOptions() {
    if (context != CourseCardContext.booking) return [];
    
    final options = <Widget>[];
    
    // Taster Session Option
    if (_shouldShowTasterSessions()) {
      options.add(TasterSessionDropdown(
        futureSessions: course.futureCourseSessions,
        tasterPrice: course.tasterPrice,
        disabled: course.fullyBooked,
        onBookTaster: () {
          // TODO: Handle taster booking
        },
      ));
    }
    
    // Deposit Payment Option
    if (_shouldShowDepositOption()) {
      options.add(DepositPaymentSection(
        course: course,
        disabled: course.fullyBooked,
        onPayDeposit: () {
          // TODO: Handle deposit payment
        },
      ));
    }
    
    return options;
  }

  bool _shouldShowTasterSessions() {
    return course.hasTasterClasses && 
           course.tasterPrice > 0 && 
           course.futureCourseSessions.isNotEmpty;
  }

  bool _shouldShowDepositOption() {
    return course.isAcceptingDeposits && 
           course.depositPrice != null && 
           course.depositPrice! > 0;
  }

  String _formatAddressDisplay(Address address) {
    final parts = <String>[];
    
    if (address.line1 != null && address.line1!.isNotEmpty) {
      String addressLine = address.line1!;
      if (address.line2 != null && address.line2!.isNotEmpty) {
        addressLine += ', ${address.line2!}';
      }
      parts.add(addressLine);
    } else if (address.line2 != null && address.line2!.isNotEmpty) {
      parts.add(address.line2!);
    }
    
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    
    if (address.postCode != null && address.postCode!.isNotEmpty) {
      parts.add(address.postCode!);
    }
    
    if (parts.isEmpty) {
      return 'Studio Location';
    }
    
    if (parts.length > 2) {
      return '${parts[0]}, ${parts.last}';
    }
    
    return parts.join(', ');
  }

  void _showLocationDetails() {
    if (course.address == null) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildLocationModal(context),
    );
  }

  Widget _buildLocationModal(BuildContext context) {
    final theme = Theme.of(context);
    final address = course.address!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Studio Location',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            course.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildAddressLine(context, 'Address', _formatFullAddress(address)),
          
          if (address.city != null && address.city!.isNotEmpty)
            _buildAddressLine(context, 'City', address.city!),
            
          if (address.postCode != null && address.postCode!.isNotEmpty)
            _buildAddressLine(context, 'Postcode', address.postCode!),
            
          if (address.county != null && address.county!.isNotEmpty)
            _buildAddressLine(context, 'County', address.county!),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openInMaps(context),
                  icon: const Icon(Icons.map),
                  label: const Text('Open in Maps'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _getDirections(context),
                  icon: const Icon(Icons.directions),
                  label: const Text('Get Directions'),
                ),
              ),
            ],
          ),
          
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildAddressLine(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullAddress(Address address) {
    final parts = <String>[];
    
    if (address.line1 != null && address.line1!.isNotEmpty) {
      parts.add(address.line1!);
    }
    if (address.line2 != null && address.line2!.isNotEmpty) {
      parts.add(address.line2!);
    }
    
    return parts.isNotEmpty ? parts.join(', ') : 'Address not specified';
  }

  void _openInMaps(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maps integration coming soon'),
      ),
    );
  }

  void _getDirections(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Directions feature coming soon'),
      ),
    );
  }

  void _handleBookmark() {
    // TODO: Implement bookmark functionality
  }

  void _handleShare() {
    // TODO: Implement share functionality
  }
}

/// Context enum for different card usage scenarios
enum CourseCardContext {
  booking,      // Course booking/discovery
  userPortal,   // User's enrolled courses
  videoViewing, // Video content access
}

/// Factory methods for different contexts
extension CourseWithinGroupCardFactories on CourseWithinGroupCardRefactored {
  /// Create for course booking context
  static Widget forBooking({
    required Course course,
    required VoidCallback onAddToBasket,
    VoidCallback? onTapCourse,
  }) {
    return CourseWithinGroupCardRefactored(
      course: course,
      context: CourseCardContext.booking,
      onAddToBasket: onAddToBasket,
      onTapCourse: onTapCourse,
    );
  }

  /// Create for user portal context
  static Widget forUserPortal({
    required Course course,
    required VoidCallback onWatchVideos,
    VoidCallback? onViewProgress,
    VoidCallback? onDownloadResources,
    VoidCallback? onTapCourse,
  }) {
    return CourseWithinGroupCardRefactored(
      course: course,
      context: CourseCardContext.userPortal,
      onWatchVideos: onWatchVideos,
      onViewProgress: onViewProgress,
      onDownloadResources: onDownloadResources,
      onTapCourse: onTapCourse,
    );
  }

  /// Create for video viewing context
  static Widget forVideoViewing({
    required Course course,
    required VoidCallback onWatchVideos,
    VoidCallback? onDownloadResources,
    VoidCallback? onTapCourse,
  }) {
    return CourseWithinGroupCardRefactored(
      course: course,
      context: CourseCardContext.videoViewing,
      onWatchVideos: onWatchVideos,
      onDownloadResources: onDownloadResources,
      onTapCourse: onTapCourse,
    );
  }
}