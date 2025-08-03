import 'package:flutter/material.dart';

/// Reusable loading state components
/// 
/// Provides consistent loading indicators across the app
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2,
    this.message,
  });

  /// Creates a centered loading indicator with optional message
  factory AppLoadingIndicator.centered({
    Key? key,
    double size = 32,
    Color? color,
    String? message,
  }) {
    return AppLoadingIndicator(
      key: key,
      size: size,
      color: color,
      message: message,
    );
  }

  /// Creates a small inline loading indicator
  factory AppLoadingIndicator.small({
    Key? key,
    Color? color,
  }) {
    return AppLoadingIndicator(
      key: key,
      size: 16,
      color: color,
      strokeWidth: 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return indicator;
  }
}

/// Full-screen loading overlay
class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final Color? overlayColor;

  const AppLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: overlayColor ?? theme.colorScheme.surface.withOpacity(0.8),
              child: Center(
                child: AppLoadingIndicator.centered(
                  message: message,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// List loading states
class AppListLoading extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const AppListLoading({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  /// Creates a standard list loading with shimmer cards
  factory AppListLoading.cards({
    Key? key,
    int itemCount = 5,
    double? itemHeight,
  }) {
    return AppListLoading(
      key: key,
      itemCount: itemCount,
      itemBuilder: (context, index) => Container(
        height: itemHeight ?? 100,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Button loading state
class AppButtonLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const AppButtonLoading({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// Image loading placeholder
class AppImageLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const AppImageLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: borderRadius,
      ),
      child: child ?? Center(
        child: Icon(
          Icons.image_outlined,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          size: 32,
        ),
      ),
    );
  }
}

/// Error states
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Widget? icon;

  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  /// Creates a network error state
  factory AppErrorState.network({
    Key? key,
    VoidCallback? onRetry,
  }) {
    return AppErrorState(
      key: key,
      message: 'Network error. Please check your connection and try again.',
      onRetry: onRetry,
      icon: const Icon(Icons.wifi_off, size: 48),
    );
  }

  /// Creates a generic error state
  factory AppErrorState.generic({
    Key? key,
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppErrorState(
      key: key,
      message: message ?? 'Something went wrong. Please try again.',
      onRetry: onRetry,
      icon: const Icon(Icons.error_outline, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(
                  color: theme.colorScheme.error,
                ),
                child: icon!,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty states
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? icon;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  /// Creates a "no items" empty state
  factory AppEmptyState.noItems({
    Key? key,
    required String title,
    String? subtitle,
    Widget? action,
  }) {
    return AppEmptyState(
      key: key,
      title: title,
      subtitle: subtitle,
      action: action,
      icon: const Icon(Icons.inbox_outlined, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                child: icon!,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}