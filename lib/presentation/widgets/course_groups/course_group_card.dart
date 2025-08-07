import 'package:flutter/material.dart';
import '../../../domain/entities/course_group.dart';
import '../../../core/utils/image_loader.dart' as image_utils;

/// Card widget for displaying a course group
class CourseGroupCard extends StatelessWidget {
  final CourseGroup courseGroup;
  final VoidCallback onTap;

  const CourseGroupCard({
    super.key,
    required this.courseGroup,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: _buildImageSection(context),
              ),
              
              // Content Section
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive padding matching website patterns
                    final isMobile = constraints.maxWidth < 768;
                    return Padding(
                      padding: EdgeInsets.all(isMobile ? 16.0 : 12.0), // More padding on mobile
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Use minimum space needed
                    children: [
                      // Title - Responsive typography matching website
                      Flexible(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Match website responsive typography patterns
                            final isDesktop = constraints.maxWidth > 768;
                            return Text(
                              courseGroup.name,
                              style: isDesktop 
                                  ? theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16, // Desktop: more compact
                                      height: 1.2, // Tighter line height
                                    )
                                  : theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 18, // Mobile: larger for readability
                                      height: 1.3, // More generous line height
                                    ),
                              maxLines: isDesktop ? 1 : 2, // More lines on mobile
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 4), // Responsive spacing
                      
                      // Description - Responsive visibility and sizing
                      if (courseGroup.shortDescription != null)
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth > 768;
                              return Text(
                                courseGroup.shortDescription!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: isDesktop ? 11 : 13, // Larger on mobile
                                  height: isDesktop ? 1.2 : 1.4, // Better mobile readability
                                ),
                                maxLines: isDesktop ? 1 : 2, // More lines on mobile
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                      
                      const SizedBox(height: 4), // Small fixed space instead of Spacer
                      
                      // Bottom Row: Price and Course Type - Responsive Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 768;
                          final isMobile = constraints.maxWidth < 768;
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Price - Responsive sizing
                              if (courseGroup.priceRangeDisplay != null)
                                Flexible(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 8 : 6, // More padding on mobile
                                      vertical: isMobile ? 4 : 2, // More padding on mobile
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        isMobile ? 8 : 6, // More rounded on mobile
                                      ),
                                    ),
                                    child: Text(
                                      courseGroup.priceRangeDisplay!,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isMobile ? 12 : 10, // Larger on mobile
                                      ),
                                    ),
                                  ),
                                ),
                              
                              SizedBox(width: isMobile ? 12 : 8), // More spacing on mobile
                              
                              // View Course Button - Responsive
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: onTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 12 : 8,
                                      vertical: isMobile ? 10 : 6, // Taller on mobile
                                    ),
                                    minimumSize: Size(
                                      isMobile ? 100 : 80, // Wider on mobile
                                      isMobile ? 36 : 28, // Taller on mobile
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        isMobile ? 8 : 6, // More rounded on mobile
                                      ),
                                    ),
                                    elevation: isDesktop ? 1 : 2, // More shadow on mobile
                                  ),
                                  child: Text(
                                    isMobile ? 'View Course' : 'View', // Full text on mobile
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isMobile ? 12 : 10, // Larger on mobile
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Course Image
            if (courseGroup.image != null && courseGroup.image!.isNotEmpty)
              image_utils.ImageLoader.forCourseCard(
                imageUrl: courseGroup.image,
                width: double.infinity,
                height: double.infinity,
                imagePosition: courseGroup.imagePosition != null
                    ? image_utils.ImagePosition(
                        X: courseGroup.imagePosition!.X.toDouble(),
                        Y: courseGroup.imagePosition!.Y.toDouble(),
                      )
                    : null,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              )
            else
              _buildPlaceholderImage(context),

            // Location/Type Badge (bottom right)
            Positioned(
              bottom: 8,
              right: 8,
              child: _buildLocationBadge(context),
            ),

            // Gradient Overlay for better text readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              courseGroup.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBadge(BuildContext context) {
    final theme = Theme.of(context);
    final hasOnline = courseGroup.hasOnlineCourses;
    final hasStudio = courseGroup.hasStudioCourses;
    
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (hasOnline && hasStudio) {
      badgeColor = theme.colorScheme.tertiary;
      badgeIcon = Icons.laptop_mac;
      badgeText = courseGroup.locationDisplay ?? 'Online & Studio';
    } else if (hasOnline) {
      badgeColor = theme.colorScheme.secondary;
      badgeIcon = Icons.laptop;
      badgeText = 'Online';
    } else {
      badgeColor = theme.colorScheme.primary;
      badgeIcon = Icons.location_on;
      badgeText = courseGroup.locationDisplay ?? 'Studio';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 12,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}