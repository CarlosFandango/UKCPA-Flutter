import 'package:flutter/material.dart';
import '../../../../domain/entities/course.dart';
import '../../../../core/utils/text_utils.dart';

/// Badge widget that displays course type (Online, Studio, Mixed) matching website design
class CourseTypeBadge extends StatelessWidget {
  final bool hasOnline;
  final bool hasStudio;
  final String? locationText;
  final CourseTypeBadgeSize size;
  final CourseTypeBadgeStyle style;

  const CourseTypeBadge({
    super.key,
    required this.hasOnline,
    required this.hasStudio,
    this.locationText,
    this.size = CourseTypeBadgeSize.medium,
    this.style = CourseTypeBadgeStyle.filled,
  });

  /// Create badge from a single course
  factory CourseTypeBadge.fromCourse(
    Course course, {
    CourseTypeBadgeSize size = CourseTypeBadgeSize.medium,
    CourseTypeBadgeStyle style = CourseTypeBadgeStyle.filled,
  }) {
    final isOnline = course.type?.contains('Online') ?? false;
    final isStudio = course.type?.contains('Studio') ?? false;
    
    String? locationText;
    if (isStudio && course.address != null) {
      // For studio courses, show simplified location
      final address = course.address!;
      if (address.city != null && address.city!.isNotEmpty) {
        locationText = address.city!;
      } else {
        locationText = 'Studio';
      }
    } else if (isOnline) {
      locationText = 'Online';
    }

    return CourseTypeBadge(
      hasOnline: isOnline,
      hasStudio: isStudio,
      locationText: locationText,
      size: size,
      style: style,
    );
  }

  /// Create badge from course types list
  factory CourseTypeBadge.fromCourseTypes(
    List<String> courseTypes, {
    List<Location>? locations,
    CourseTypeBadgeSize size = CourseTypeBadgeSize.medium,
    CourseTypeBadgeStyle style = CourseTypeBadgeStyle.filled,
  }) {
    final hasOnline = courseTypes.any((type) => type.contains('Online')) ||
                     (locations?.contains(Location.online) ?? false);
    final hasStudio = courseTypes.any((type) => type.contains('Studio')) ||
                     (locations?.any((loc) => loc != Location.online) ?? false);

    String? locationText;
    if (hasOnline && hasStudio) {
      locationText = 'Online & Studio';
    } else if (hasOnline) {
      locationText = 'Online';
    } else if (hasStudio) {
      if (locations != null && locations.length == 1) {
        locationText = TextUtils.formatLocationName(locations.first.name);
      } else {
        locationText = 'Studio';
      }
    }

    return CourseTypeBadge(
      hasOnline: hasOnline,
      hasStudio: hasStudio,
      locationText: locationText,
      size: size,
      style: style,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine badge configuration
    final config = _getBadgeConfig();
    if (config == null) return const SizedBox.shrink();

    // Get size configuration
    final sizeConfig = _getSizeConfig();
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sizeConfig.horizontalPadding,
        vertical: sizeConfig.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: style == CourseTypeBadgeStyle.filled 
            ? config.backgroundColor 
            : theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(sizeConfig.borderRadius),
        border: style == CourseTypeBadgeStyle.outlined 
            ? Border.all(
                color: config.backgroundColor,
                width: 1.5,
              )
            : null,
        boxShadow: style == CourseTypeBadgeStyle.filled
            ? [
                BoxShadow(
                  color: config.backgroundColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: sizeConfig.iconSize,
            color: style == CourseTypeBadgeStyle.filled 
                ? config.textColor 
                : config.backgroundColor,
          ),
          SizedBox(width: sizeConfig.iconSpacing),
          Text(
            locationText ?? config.text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: sizeConfig.fontSize,
              fontWeight: FontWeight.w600,
              color: style == CourseTypeBadgeStyle.filled 
                  ? config.textColor 
                  : config.backgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Get badge configuration based on course types
  _BadgeConfig? _getBadgeConfig() {
    if (hasOnline && hasStudio) {
      return _BadgeConfig(
        text: 'Mixed',
        icon: Icons.language,
        backgroundColor: const Color(0xFF7C3AED), // Purple for mixed
        textColor: Colors.white,
      );
    } else if (hasOnline) {
      return _BadgeConfig(
        text: 'Online',
        icon: Icons.videocam,
        backgroundColor: const Color(0xFF059669), // Green for online
        textColor: Colors.white,
      );
    } else if (hasStudio) {
      return _BadgeConfig(
        text: 'Studio',
        icon: Icons.location_on,
        backgroundColor: const Color(0xFFDC2626), // Red for studio
        textColor: Colors.white,
      );
    }
    return null;
  }

  /// Get size configuration
  _SizeConfig _getSizeConfig() {
    switch (size) {
      case CourseTypeBadgeSize.small:
        return _SizeConfig(
          horizontalPadding: 6,
          verticalPadding: 3,
          borderRadius: 6,
          iconSize: 12,
          iconSpacing: 4,
          fontSize: 10,
        );
      case CourseTypeBadgeSize.medium:
        return _SizeConfig(
          horizontalPadding: 8,
          verticalPadding: 4,
          borderRadius: 8,
          iconSize: 14,
          iconSpacing: 4,
          fontSize: 11,
        );
      case CourseTypeBadgeSize.large:
        return _SizeConfig(
          horizontalPadding: 12,
          verticalPadding: 6,
          borderRadius: 10,
          iconSize: 16,
          iconSpacing: 6,
          fontSize: 12,
        );
    }
  }
}

/// Badge size options
enum CourseTypeBadgeSize {
  small,
  medium,
  large,
}

/// Badge style options
enum CourseTypeBadgeStyle {
  filled,
  outlined,
}

/// Internal badge configuration
class _BadgeConfig {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  const _BadgeConfig({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
  });
}

/// Internal size configuration
class _SizeConfig {
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double iconSize;
  final double iconSpacing;
  final double fontSize;

  const _SizeConfig({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.iconSize,
    required this.iconSpacing,
    required this.fontSize,
  });
}

/// Extension for easier badge creation
extension CourseTypeBadgeExtensions on CourseTypeBadge {
  /// Create a small badge for card overlays
  static Widget small({
    required bool hasOnline,
    required bool hasStudio,
    String? locationText,
    CourseTypeBadgeStyle style = CourseTypeBadgeStyle.filled,
  }) {
    return CourseTypeBadge(
      hasOnline: hasOnline,
      hasStudio: hasStudio,
      locationText: locationText,
      size: CourseTypeBadgeSize.small,
      style: style,
    );
  }

  /// Create a medium badge for general use
  static Widget medium({
    required bool hasOnline,
    required bool hasStudio,
    String? locationText,
    CourseTypeBadgeStyle style = CourseTypeBadgeStyle.filled,
  }) {
    return CourseTypeBadge(
      hasOnline: hasOnline,
      hasStudio: hasStudio,
      locationText: locationText,
      size: CourseTypeBadgeSize.medium,
      style: style,
    );
  }

  /// Create a large badge for headers
  static Widget large({
    required bool hasOnline,
    required bool hasStudio,
    String? locationText,
    CourseTypeBadgeStyle style = CourseTypeBadgeStyle.filled,
  }) {
    return CourseTypeBadge(
      hasOnline: hasOnline,
      hasStudio: hasStudio,
      locationText: locationText,
      size: CourseTypeBadgeSize.large,
      style: style,
    );
  }
}