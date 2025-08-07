import 'package:flutter/material.dart';
import '../../../../domain/entities/course_group.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/utils/image_loader.dart' as image_utils;
import '../../../widgets/markdown_view.dart';

/// Header widget for course group detail screen showing image, name, and key information
/// Enhanced to support markdown descriptions matching website layout
class CourseGroupHeader extends StatelessWidget {
  final CourseGroup courseGroup;

  const CourseGroupHeader({
    super.key,
    required this.courseGroup,
  });

  @override
  Widget build(BuildContext context) {
    // Return multiple slivers to be used in CustomScrollView
    return const SizedBox.shrink(); // This will be handled in the main screen
  }

  /// Build the hero image section as a sliver
  Widget buildImageSliver(BuildContext context) {
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

  /// Build the description section as a sliver
  Widget buildDescriptionSliver(BuildContext context) {
    if (courseGroup.description == null || courseGroup.description!.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
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
            Text(
              courseGroup.name,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            if (courseGroup.shortDescription != null && courseGroup.shortDescription!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                courseGroup.shortDescription!,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 20),
            
            MarkdownViewExtensions.courseDescription(
              markdown: courseGroup.description!,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseGroupImage(ThemeData theme) {
    final imageUrl = courseGroup.image ?? courseGroup.thumbImage;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return image_utils.ImageLoader.forHero(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 300,
        imagePosition: courseGroup.imagePosition != null
            ? image_utils.ImagePosition(
                X: courseGroup.imagePosition!.X.toDouble(),
                Y: courseGroup.imagePosition!.Y.toDouble(),
              )
            : null,
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
        TextUtils.formatDanceType(courseGroup.danceType!),
        Icons.music_note,
        theme.colorScheme.primary,
        theme,
      ));
    }
    
    // Locations Badge
    if (courseGroup.locations.isNotEmpty) {
      final locationText = courseGroup.locations.length == 1
          ? TextUtils.formatLocationName(courseGroup.locations.first)
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
      final typeText = TextUtils.formatCourseTypes(courseGroup.courseTypes);
      
      IconData typeIcon;
      if (typeText.contains('Online') && typeText.contains('Studio')) {
        typeIcon = Icons.web;
      } else if (typeText.contains('Online')) {
        typeIcon = Icons.computer;
      } else {
        typeIcon = Icons.place;
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
      final attendanceText = TextUtils.formatAttendanceTypesList(courseGroup.attendanceTypes);
      
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