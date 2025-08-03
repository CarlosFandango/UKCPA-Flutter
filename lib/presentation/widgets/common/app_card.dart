import 'package:flutter/material.dart';

/// Reusable card component following UKCPA design system
/// 
/// Provides consistent styling and behavior across the app
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final bool isClickable;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
    this.isClickable = false,
    this.boxShadow,
  });

  /// Creates a standard content card
  factory AppCard.content({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin,
      onTap: onTap,
      isClickable: onTap != null,
      child: child,
    );
  }

  /// Creates a course card
  factory AppCard.course({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: EdgeInsets.zero,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      isClickable: onTap != null,
      child: child,
    );
  }

  /// Creates a compact list item card
  factory AppCard.listItem({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      isClickable: onTap != null,
      child: child,
    );
  }

  /// Creates an elevated card for important content
  factory AppCard.elevated({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return AppCard(
      key: key,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      isClickable: onTap != null,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border,
        boxShadow: boxShadow ?? (elevation != null ? [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: elevation! * 2,
            offset: Offset(0, elevation! / 2),
          ),
        ] : null),
      ),
      child: child,
    );

    if (isClickable && onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Shimmer placeholder card for loading states
class AppShimmerCard extends StatelessWidget {
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const AppShimmerCard({
    super.key,
    this.height,
    this.width,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height ?? 100,
      width: width,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: const _ShimmerEffect(),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 - _controller.value, 0.0),
              end: Alignment(1.0 - _controller.value, 0.0),
              colors: [
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
                theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}