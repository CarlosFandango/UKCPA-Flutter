import 'package:flutter/material.dart';
import '../../../core/utils/image_loader.dart';

/// Base card component for displaying course/content details
/// Reusable across different contexts: course booking, user portal, video access, etc.
class BaseDetailCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final Widget? imageOverlay;
  final List<DetailGridItem> detailItems;
  final List<Widget> actionButtons;
  final List<Widget> additionalSections;
  final EdgeInsets? padding;
  final double? imageHeight;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showShadow;

  const BaseDetailCard({
    super.key,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.imageOverlay,
    this.detailItems = const [],
    this.actionButtons = const [],
    this.additionalSections = const [],
    this.padding,
    this.imageHeight = 160,
    this.borderRadius,
    this.backgroundColor,
    this.onTap,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surface,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          boxShadow: showShadow ? [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            if (imageUrl != null) _buildImageSection(theme),
            
            // Content Section
            Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title and Subtitle
                  if (title != null || subtitle != null) 
                    _buildHeaderSection(theme),
                  
                  // Detail Grid
                  if (detailItems.isNotEmpty) ...[ 
                    const SizedBox(height: 12),
                    _buildDetailGrid(theme),
                  ],
                  
                  // Action Buttons
                  if (actionButtons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...actionButtons.map((button) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: button,
                    )),
                  ],
                  
                  // Additional Sections
                  if (additionalSections.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...additionalSections.map((section) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: section,
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    final topRadius = BorderRadius.only(
      topLeft: (borderRadius ?? BorderRadius.circular(16)).topLeft,
      topRight: (borderRadius ?? BorderRadius.circular(16)).topRight,
    );

    Widget imageWidget = ImageLoader.forCourseCard(
      imageUrl: imageUrl,
      width: double.infinity,
      height: imageHeight!,
      borderRadius: topRadius,
    );

    if (imageOverlay != null) {
      imageWidget = Stack(
        children: [
          imageWidget,
          // Gradient overlay for better text readability
          Container(
            height: imageHeight,
            decoration: BoxDecoration(
              borderRadius: topRadius,
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
          imageOverlay!,
        ],
      );
    }

    return imageWidget;
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        
        if (subtitle != null) ...[ 
          const SizedBox(height: 4),
          Text(
            subtitle!,
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

  Widget _buildDetailGrid(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 12,
      childAspectRatio: 3,
      children: detailItems.map((item) => item.build(theme)).toList(),
    );
  }
}

/// Data class for detail grid items
class DetailGridItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool isClickable;

  const DetailGridItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.onTap,
    this.isClickable = false,
  });

  Widget build(ThemeData theme) {
    final widget = Container(
      decoration: isClickable ? BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ) : null,
      padding: isClickable ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: iconColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isClickable)
                Icon(
                  Icons.info_outline,
                  size: 12,
                  color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.6),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (isClickable && onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }
    
    return widget;
  }
}

/// Specialized factory constructors for common use cases
extension BaseDetailCardFactories on BaseDetailCard {
  /// Create card for course booking context
  static Widget forCourseBooking({
    required String title,
    String? subtitle,
    String? imageUrl,
    Widget? courseTypeBadge,
    required List<DetailGridItem> courseDetails,
    required List<Widget> bookingActions,
    List<Widget> paymentOptions = const [],
    VoidCallback? onTap,
  }) {
    return BaseDetailCard(
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      imageOverlay: courseTypeBadge != null ? Positioned(
        top: 8,
        left: 8,
        child: courseTypeBadge,
      ) : null,
      detailItems: courseDetails,
      actionButtons: bookingActions,
      additionalSections: paymentOptions,
      onTap: onTap,
    );
  }

  /// Create card for user portal (booked courses)
  static Widget forUserPortal({
    required String title,
    String? subtitle,
    String? imageUrl,
    Widget? statusBadge,
    required List<DetailGridItem> courseDetails,
    required List<Widget> userActions,
    List<Widget> progressSections = const [],
    VoidCallback? onTap,
  }) {
    return BaseDetailCard(
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
      imageOverlay: statusBadge != null ? Positioned(
        top: 8,
        right: 8,
        child: statusBadge,
      ) : null,
      detailItems: courseDetails,
      actionButtons: userActions,
      additionalSections: progressSections,
      onTap: onTap,
    );
  }

  /// Create card for video/content viewing
  static Widget forVideoContent({
    required String title,
    String? subtitle,
    String? thumbnailUrl,
    Widget? playButton,
    required List<DetailGridItem> contentDetails,
    required List<Widget> viewingActions,
    List<Widget> relatedContent = const [],
    VoidCallback? onTap,
  }) {
    return BaseDetailCard(
      title: title,
      subtitle: subtitle,
      imageUrl: thumbnailUrl,
      imageOverlay: playButton != null ? Center(
        child: playButton,
      ) : null,
      detailItems: contentDetails,
      actionButtons: viewingActions,
      additionalSections: relatedContent,
      onTap: onTap,
    );
  }
}