import 'package:flutter/material.dart';

/// Reusable action button component for different course contexts
/// Supports booking, user portal, video viewing, and other action patterns
class CourseActionButtons extends StatelessWidget {
  final CourseActionContext context;
  final CourseActionConfig config;
  final bool disabled;

  const CourseActionButtons({
    super.key,
    required this.context,
    required this.config,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (this.context) {
      case CourseActionContext.booking:
        return _buildBookingActions(context);
      case CourseActionContext.userPortal:
        return _buildUserPortalActions(context);
      case CourseActionContext.videoViewing:
        return _buildVideoViewingActions(context);
      case CourseActionContext.tasterBooking:
        return _buildTasterBookingActions(context);
    }
  }

  Widget _buildBookingActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Primary Action (Add to Basket)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: disabled ? null : config.primaryAction?.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              config.primaryAction?.label ?? 'Add to basket',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        // Secondary Actions (if any)
        if (config.secondaryActions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: config.secondaryActions.map((action) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton(
                  onPressed: disabled ? null : action.onPressed,
                  child: Text(action.label),
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildUserPortalActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Primary Action (View Course/Watch Videos)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: disabled ? null : config.primaryAction?.onPressed,
            icon: Icon(config.primaryAction?.icon ?? Icons.play_arrow),
            label: Text(config.primaryAction?.label ?? 'Watch Videos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // Secondary Actions Row
        if (config.secondaryActions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: config.secondaryActions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index > 0 ? 6 : 0,
                    right: index < config.secondaryActions.length - 1 ? 6 : 0,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: disabled ? null : action.onPressed,
                    icon: Icon(action.icon, size: 16),
                    label: Text(
                      action.label,
                      style: theme.textTheme.bodySmall,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoViewingActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Play Button (Primary)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: disabled ? null : config.primaryAction?.onPressed,
            icon: Icon(config.primaryAction?.icon ?? Icons.play_arrow, size: 20),
            label: Text(config.primaryAction?.label ?? 'Play Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        // Video Controls Row
        if (config.secondaryActions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: config.secondaryActions.map((action) => 
              IconButton(
                onPressed: disabled ? null : action.onPressed,
                icon: Icon(action.icon),
                tooltip: action.label,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTasterBookingActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Price Display
        if (config.priceDisplay != null) 
          Text(
            config.priceDisplay!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.tertiary,
            ),
          ),
        
        // Book Taster Button
        SizedBox(
          width: 120,
          child: ElevatedButton(
            onPressed: disabled ? null : config.primaryAction?.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.tertiary,
              foregroundColor: theme.colorScheme.onTertiary,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              config.primaryAction?.label ?? 'Book Taster',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Configuration class for action buttons
class CourseActionConfig {
  final ActionButtonData? primaryAction;
  final List<ActionButtonData> secondaryActions;
  final String? priceDisplay;

  const CourseActionConfig({
    this.primaryAction,
    this.secondaryActions = const [],
    this.priceDisplay,
  });
}

/// Data class for individual action buttons
class ActionButtonData {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ActionButtonData({
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });
}

/// Context enum for different action button layouts
enum CourseActionContext {
  booking,
  userPortal,
  videoViewing,
  tasterBooking,
}

/// Factory methods for common action button configurations
extension CourseActionButtonsFactories on CourseActionButtons {
  /// Create booking action buttons
  static Widget forBooking({
    required String primaryLabel,
    required VoidCallback? onAddToBasket,
    List<ActionButtonData> secondaryActions = const [],
    bool disabled = false,
    bool isFullyBooked = false,
  }) {
    return CourseActionButtons(
      context: CourseActionContext.booking,
      config: CourseActionConfig(
        primaryAction: ActionButtonData(
          label: isFullyBooked ? 'Fully booked' : primaryLabel,
          onPressed: isFullyBooked ? null : onAddToBasket,
        ),
        secondaryActions: secondaryActions,
      ),
      disabled: disabled || isFullyBooked,
    );
  }

  /// Create user portal action buttons
  static Widget forUserPortal({
    required VoidCallback? onWatchVideos,
    VoidCallback? onViewSchedule,
    VoidCallback? onDownloadResources,
    VoidCallback? onViewProgress,
    bool disabled = false,
  }) {
    final secondaryActions = <ActionButtonData>[];
    
    if (onViewSchedule != null) {
      secondaryActions.add(ActionButtonData(
        label: 'Schedule',
        icon: Icons.calendar_today,
        onPressed: onViewSchedule,
      ));
    }
    
    if (onDownloadResources != null) {
      secondaryActions.add(ActionButtonData(
        label: 'Resources',
        icon: Icons.download,
        onPressed: onDownloadResources,
      ));
    }
    
    if (onViewProgress != null) {
      secondaryActions.add(ActionButtonData(
        label: 'Progress',
        icon: Icons.trending_up,
        onPressed: onViewProgress,
      ));
    }

    return CourseActionButtons(
      context: CourseActionContext.userPortal,
      config: CourseActionConfig(
        primaryAction: ActionButtonData(
          label: 'Watch Videos',
          icon: Icons.play_arrow,
          onPressed: onWatchVideos,
        ),
        secondaryActions: secondaryActions,
      ),
      disabled: disabled,
    );
  }

  /// Create video viewing action buttons
  static Widget forVideoViewing({
    required VoidCallback? onPlay,
    VoidCallback? onBookmark,
    VoidCallback? onShare,
    VoidCallback? onDownload,
    bool disabled = false,
  }) {
    final secondaryActions = <ActionButtonData>[];
    
    if (onBookmark != null) {
      secondaryActions.add(ActionButtonData(
        label: 'Bookmark',
        icon: Icons.bookmark_add,
        onPressed: onBookmark,
      ));
    }
    
    if (onShare != null) {
      secondaryActions.add(ActionButtonData(
        label: 'Share',
        icon: Icons.share,
        onPressed: onShare,
      ));
    }
    
    if (onDownload != null) {
      secondaryActions.add(ActionButtonData(
        label: 'Download',
        icon: Icons.download,
        onPressed: onDownload,
      ));
    }

    return CourseActionButtons(
      context: CourseActionContext.videoViewing,
      config: CourseActionConfig(
        primaryAction: ActionButtonData(
          label: 'Play Video',
          icon: Icons.play_arrow,
          onPressed: onPlay,
        ),
        secondaryActions: secondaryActions,
      ),
      disabled: disabled,
    );
  }

  /// Create taster booking action buttons
  static Widget forTasterBooking({
    required String priceDisplay,
    required VoidCallback? onBookTaster,
    bool disabled = false,
  }) {
    return CourseActionButtons(
      context: CourseActionContext.tasterBooking,
      config: CourseActionConfig(
        primaryAction: ActionButtonData(
          label: 'Book Taster',
          onPressed: onBookTaster,
        ),
        priceDisplay: priceDisplay,
      ),
      disabled: disabled,
    );
  }
}