import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/basket_provider.dart';

/// Basket icon widget with item count badge
/// Based on UKCPA website basket icon functionality
class BasketIcon extends ConsumerWidget {
  final bool showBadge;
  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback? onTap;

  const BasketIcon({
    super.key,
    this.showBadge = true,
    this.iconSize = 24,
    this.iconColor,
    this.badgeColor,
    this.badgeTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemCount = ref.watch(basketItemCountProvider);
    final isLoading = ref.watch(basketLoadingProvider);
    
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap ?? () => context.go('/basket'),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main basket icon
            Icon(
              Icons.shopping_basket_outlined,
              size: iconSize,
              color: iconColor ?? theme.colorScheme.onSurface,
            ),
            
            // Loading indicator overlay (small dot)
            if (isLoading)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 6,
                    height: 6,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Item count badge
            if (showBadge && itemCount > 0 && !isLoading)
              Positioned(
                right: -6,
                top: -6,
                child: BasketBadge(
                  count: itemCount,
                  color: badgeColor ?? theme.colorScheme.error,
                  textColor: badgeTextColor ?? theme.colorScheme.onError,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Badge component for displaying item count
class BasketBadge extends StatelessWidget {
  final int count;
  final Color color;
  final Color textColor;
  final double? minSize;
  final double? maxSize;

  const BasketBadge({
    super.key,
    required this.count,
    required this.color,
    required this.textColor,
    this.minSize = 16,
    this.maxSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Don't show badge for zero items
    if (count <= 0) return const SizedBox.shrink();
    
    // Format count display (99+ for large numbers)
    final displayText = count > 99 ? '99+' : count.toString();
    
    // Calculate badge size based on text length
    final textLength = displayText.length;
    final badgeSize = (minSize! + (textLength - 1) * 4).clamp(minSize!, maxSize!);
    
    return Container(
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: theme.textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Enhanced basket icon with popover preview functionality
/// Based on website's basket preview popover
class BasketIconWithPreview extends ConsumerStatefulWidget {
  final bool showBadge;
  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final Color? badgeTextColor;

  const BasketIconWithPreview({
    super.key,
    this.showBadge = true,
    this.iconSize = 24,
    this.iconColor,
    this.badgeColor,
    this.badgeTextColor,
  });

  @override
  ConsumerState<BasketIconWithPreview> createState() => _BasketIconWithPreviewState();
}

class _BasketIconWithPreviewState extends ConsumerState<BasketIconWithPreview> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showPreview() {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-250, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: const BasketPreviewPopover(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () => context.go('/basket'),
        onLongPress: _showPreview,
        child: BasketIcon(
          showBadge: widget.showBadge,
          iconSize: widget.iconSize,
          iconColor: widget.iconColor,
          badgeColor: widget.badgeColor,
          badgeTextColor: widget.badgeTextColor,
          onTap: () => context.go('/basket'),
        ),
      ),
    );
  }
}

/// Popover preview of basket contents
/// Simplified version for mobile - shows item count and total
class BasketPreviewPopover extends ConsumerWidget {
  const BasketPreviewPopover({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final basket = ref.watch(currentBasketProvider);
    final isLoading = ref.watch(basketLoadingProvider);
    final error = ref.watch(basketErrorProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.shopping_basket,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Basket',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Content
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Text(
              'Error loading basket',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            )
          else if (basket == null || basket.isEmpty)
            Text(
              'Your basket is empty',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            )
          else
            Column(
              children: [
                // Item count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${basket.itemCount} item${basket.itemCount != 1 ? 's' : ''}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      basket.formattedTotal,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // View basket button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close popover and navigate to basket
                      Navigator.of(context).pop();
                      context.go('/basket');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('View Basket'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Floating action button variant of basket icon
/// Useful for mobile layouts where basket access is important
class BasketFloatingActionButton extends ConsumerWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool mini;

  const BasketFloatingActionButton({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final itemCount = ref.watch(basketItemCountProvider);
    final isEmpty = ref.watch(basketIsEmptyProvider);

    // Don't show FAB if basket is empty
    if (isEmpty) return const SizedBox.shrink();

    return FloatingActionButton(
      mini: mini,
      elevation: elevation,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      onPressed: () => context.go('/basket'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_basket),
          if (itemCount > 0)
            Positioned(
              right: -6,
              top: -6,
              child: BasketBadge(
                count: itemCount,
                color: theme.colorScheme.error,
                textColor: theme.colorScheme.onError,
                minSize: 14,
                maxSize: 20,
              ),
            ),
        ],
      ),
    );
  }
}

/// Extension methods for easier basket icon usage
extension BasketIconExtensions on BasketIcon {
  /// Create a basket icon for app bar usage
  static Widget appBar(BuildContext context) {
    return const BasketIcon(
      iconSize: 24,
      showBadge: true,
    );
  }

  /// Create a basket icon for bottom navigation
  static Widget bottomNav(BuildContext context, {bool isSelected = false}) {
    final theme = Theme.of(context);
    return BasketIcon(
      iconSize: 24,
      showBadge: true,
      iconColor: isSelected ? theme.colorScheme.primary : null,
    );
  }

  /// Create a basket icon for drawer usage
  static Widget drawer(BuildContext context) {
    return const BasketIcon(
      iconSize: 20,
      showBadge: true,
    );
  }
}