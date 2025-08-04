import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/entities/course_group.dart';
import '../../../../core/utils/money_formatter.dart';

/// Header widget for course group detail screen showing image, name, and key information
class CourseGroupHeader extends StatelessWidget {
  final CourseGroup courseGroup;

  const CourseGroupHeader({
    super.key,
    required this.courseGroup,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          courseGroup.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Course Group Image
            _buildCourseGroupImage(theme),
            
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Course Group Summary Info
            Positioned(
              left: 16,
              right: 16,
              bottom: 80, // Above the title
              child: _buildCourseGroupSummary(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseGroupImage(ThemeData theme) {
    final imageUrl = courseGroup.image ?? courseGroup.thumbImage;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        alignment: courseGroup.imagePosition != null
            ? Alignment(
                courseGroup.imagePosition!.X,
                courseGroup.imagePosition!.Y,
              )
            : Alignment.center,
        placeholder: (context, url) => Container(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackImage(theme),
      );
    }
    
    return _buildFallbackImage(theme);
  }

  Widget _buildFallbackImage(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.secondary.withOpacity(0.5),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: 64,
          color: theme.colorScheme.onPrimary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildCourseGroupSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price Range
          if (courseGroup.minPrice != null || courseGroup.maxPrice != null)
            _buildPriceRange(theme),
          
          // Location and Type Badges
          const SizedBox(height: 12),
          _buildInfoBadges(theme),
          
          // Short Description
          if (courseGroup.shortDescription != null && courseGroup.shortDescription!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              courseGroup.shortDescription!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRange(ThemeData theme) {
    final minPrice = courseGroup.minPrice;
    final maxPrice = courseGroup.maxPrice;
    
    String priceText;
    if (minPrice != null && maxPrice != null) {
      if (minPrice == maxPrice) {
        priceText = MoneyFormatter.formatPence(minPrice);
      } else {
        priceText = '${MoneyFormatter.formatPence(minPrice)} - ${MoneyFormatter.formatPence(maxPrice)}';
      }
    } else if (minPrice != null) {
      priceText = 'From ${MoneyFormatter.formatPence(minPrice)}';
    } else if (maxPrice != null) {
      priceText = 'Up to ${MoneyFormatter.formatPence(maxPrice)}';
    } else {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        Icon(
          Icons.payment,
          size: 16,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(width: 8),
        Text(
          priceText,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadges(ThemeData theme) {
    final badges = <Widget>[];
    
    // Dance Type Badge
    if (courseGroup.danceType != null && courseGroup.danceType!.isNotEmpty) {
      badges.add(_buildBadge(
        courseGroup.danceType!,
        Icons.music_note,
        theme.colorScheme.primary,
        theme,
      ));
    }
    
    // Locations Badge
    if (courseGroup.locations.isNotEmpty) {
      final locationText = courseGroup.locations.length == 1
          ? courseGroup.locations.first
          : '${courseGroup.locations.length} locations';
      
      badges.add(_buildBadge(
        locationText,
        Icons.location_on,
        theme.colorScheme.secondary,
        theme,
      ));
    }
    
    // Course Types Badge
    if (courseGroup.courseTypes.isNotEmpty) {
      final hasOnline = courseGroup.courseTypes.contains('OnlineCourse');
      final hasStudio = courseGroup.courseTypes.contains('StudioCourse');
      
      String typeText;
      IconData typeIcon;
      if (hasOnline && hasStudio) {
        typeText = 'Online & Studio';
        typeIcon = Icons.web;
      } else if (hasOnline) {
        typeText = 'Online';
        typeIcon = Icons.computer;
      } else if (hasStudio) {
        typeText = 'Studio';
        typeIcon = Icons.place;
      } else {
        typeText = courseGroup.courseTypes.first;
        typeIcon = Icons.class_;
      }
      
      badges.add(_buildBadge(
        typeText,
        typeIcon,
        theme.colorScheme.tertiary,
        theme,
      ));
    }
    
    // Attendance Types Badge
    if (courseGroup.attendanceTypes.isNotEmpty) {
      final attendanceText = courseGroup.attendanceTypes.length == 1
          ? courseGroup.attendanceTypes.first.toLowerCase().capitalize()
          : 'All ages';
      
      badges.add(_buildBadge(
        attendanceText,
        Icons.people,
        theme.colorScheme.outline,
        theme,
      ));
    }
    
    if (badges.isEmpty) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: badges,
    );
  }

  Widget _buildBadge(String text, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension to capitalize first letter
extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}