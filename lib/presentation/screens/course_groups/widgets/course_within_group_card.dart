import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/course.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/schedule_utils.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/utils/image_loader.dart';
import '../../../providers/basket_provider.dart';
import 'course_type_badge.dart';
import 'taster_session_dropdown.dart';
import 'deposit_payment_section.dart';

/// Card widget for displaying an individual course within a course group
/// Enhanced to match the website's course display exactly
class CourseWithinGroupCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAvailable = course.isAvailable;
    final isFullyBooked = course.fullyBooked;
    
    // Check if course is already in basket
    final isInBasket = ref.watch(courseInBasketProvider(course.id));

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
                _buildPriceAndMainAction(theme, isAvailable, isFullyBooked, ref),
                
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
    final imagePosition = course.imagePosition != null
        ? ImagePosition(
            X: course.imagePosition!.X.toDouble(),
            Y: course.imagePosition!.Y.toDouble(),
          )
        : null;

    return Stack(
      children: [
        ImageLoader.forCourseCard(
          imageUrl: course.image,
          width: double.infinity,
          height: 160,
          imagePosition: imagePosition,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        
        // Gradient overlay
        Container(
          height: 160,
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
        _buildLocationGridItem(
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

  /// Build location grid item (tappable for more details)
  Widget _buildLocationGridItem(String locationText, ThemeData theme) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showLocationDetails(context),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Location',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: theme.colorScheme.primary.withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                locationText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
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
  Widget _buildPriceAndMainAction(ThemeData theme, bool isAvailable, bool isFullyBooked, WidgetRef ref) {
    final effectivePrice = course.currentPrice ?? course.price;
    final isInBasket = ref.watch(courseInBasketProvider(course.id));
    
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
            onPressed: isAvailable && !isFullyBooked && !isInBasket ? onAddToBasket : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInBasket 
                  ? theme.colorScheme.surfaceVariant 
                  : theme.colorScheme.primary,
              foregroundColor: isInBasket 
                  ? theme.colorScheme.onSurfaceVariant 
                  : theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isInBasket) ...[
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  isInBasket 
                      ? 'In Basket'
                      : isFullyBooked 
                          ? 'Fully booked' 
                          : isAvailable 
                              ? 'Add to basket'
                              : 'Not Available',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
    
    // Add address line 1 and 2 if available
    if (address.line1 != null && address.line1!.isNotEmpty) {
      String addressLine = address.line1!;
      if (address.line2 != null && address.line2!.isNotEmpty) {
        addressLine += ', ${address.line2!}';
      }
      parts.add(addressLine);
    } else if (address.line2 != null && address.line2!.isNotEmpty) {
      parts.add(address.line2!);
    }
    
    // Add city
    if (address.city != null && address.city!.isNotEmpty) {
      parts.add(address.city!);
    }
    
    // Add postcode - always show postcode if available for UK addresses
    if (address.postCode != null && address.postCode!.isNotEmpty) {
      parts.add(address.postCode!);
    }
    
    // If no location information available, show studio location placeholder
    if (parts.isEmpty) {
      return 'Studio Location';
    }
    
    // Join parts with commas, but limit to avoid overcrowding in card
    if (parts.length > 2) {
      return '${parts[0]}, ${parts.last}'; // Show first part and postcode/last part
    }
    
    return parts.join(', ');
  }

  /// Show detailed location information in a modal
  void _showLocationDetails(BuildContext context) {
    if (course.address == null) return;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildLocationModal(context),
    );
  }

  /// Build location details modal
  Widget _buildLocationModal(BuildContext context) {
    final theme = Theme.of(context);
    final address = course.address!;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modal header
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
          
          // Course name
          Text(
            course.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Full address
          _buildAddressLine(context, 'Address', _formatFullAddress(address)),
          
          if (address.city != null && address.city!.isNotEmpty)
            _buildAddressLine(context, 'City', address.city!),
            
          if (address.postCode != null && address.postCode!.isNotEmpty)
            _buildAddressLine(context, 'Postcode', address.postCode!),
            
          if (address.county != null && address.county!.isNotEmpty)
            _buildAddressLine(context, 'County', address.county!),
            
          if (address.country != null && address.country!.isNotEmpty)
            _buildAddressLine(context, 'Country', address.country!),
          
          const SizedBox(height: 24),
          
          // Action buttons
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
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Build address line in modal
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

  /// Format full address for display
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

  /// Open location in maps app
  void _openInMaps(BuildContext context) {
    // TODO: Implement maps integration in Phase 3
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Maps integration coming soon'),
      ),
    );
  }

  /// Get directions to location
  void _getDirections(BuildContext context) {
    // TODO: Implement directions in Phase 3
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Directions feature coming soon'),
      ),
    );
  }
}