import 'package:flutter/material.dart';
import '../../../../domain/entities/course.dart';

/// Add to basket button widget for courses
/// UI-only implementation for Phase 2, will be enhanced in Phase 3
class AddToBasketButton extends StatefulWidget {
  final Course course;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final EdgeInsetsGeometry? padding;
  final bool isCompact;

  const AddToBasketButton({
    super.key,
    required this.course,
    this.onPressed,
    this.isEnabled = true,
    this.padding,
    this.isCompact = true,
  });

  @override
  State<AddToBasketButton> createState() => _AddToBasketButtonState();
}

class _AddToBasketButtonState extends State<AddToBasketButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.isEnabled && widget.onPressed != null;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButton(theme, isEnabled),
        );
      },
    );
  }

  Widget _buildButton(ThemeData theme, bool isEnabled) {
    if (!isEnabled) {
      return _buildDisabledButton(theme);
    }

    if (widget.isCompact) {
      return _buildCompactButton(theme);
    }

    return _buildFullButton(theme);
  }

  Widget _buildCompactButton(ThemeData theme) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapCancel(),
      onTap: widget.onPressed,
      child: Container(
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_shopping_cart,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              'Add',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullButton(ThemeData theme) {
    return GestureDetector(
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: () => _handleTapCancel(),
      onTap: widget.onPressed,
      child: Container(
        width: double.infinity,
        padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_shopping_cart,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Add to Basket',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledButton(ThemeData theme) {
    final buttonContent = Row(
      mainAxisSize: widget.isCompact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: widget.isCompact ? MainAxisAlignment.center : MainAxisAlignment.center,
      children: [
        Icon(
          Icons.block,
          size: widget.isCompact ? 16 : 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: widget.isCompact ? 6 : 8),
        Text(
          widget.isCompact ? 'N/A' : 'Not Available',
          style: (widget.isCompact ? theme.textTheme.bodySmall : theme.textTheme.titleMedium)?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Container(
      width: widget.isCompact ? null : double.infinity,
      padding: widget.padding ?? EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 16 : 0,
        vertical: widget.isCompact ? 8 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(widget.isCompact ? 20 : 12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: buttonContent,
    );
  }

  void _handleTapDown() {
    if (!mounted) return;
    _animationController.forward();
  }

  void _handleTapUp() {
    if (!mounted) return;
    _animationController.reverse();
  }

  void _handleTapCancel() {
    if (!mounted) return;
    _animationController.reverse();
  }
}

/// Enhanced add to basket button with multiple booking options
/// Will be used in individual course detail screen (Slice 2.5)
class EnhancedAddToBasketButton extends StatelessWidget {
  final Course course;
  final VoidCallback? onAddFullPrice;
  final VoidCallback? onAddDeposit;
  final VoidCallback? onAddTaster;
  final bool showDepositOption;
  final bool showTasterOption;

  const EnhancedAddToBasketButton({
    super.key,
    required this.course,
    this.onAddFullPrice,
    this.onAddDeposit,
    this.onAddTaster,
    this.showDepositOption = false,
    this.showTasterOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = course.isAvailable;

    if (!isAvailable) {
      return AddToBasketButton(
        course: course,
        isEnabled: false,
        isCompact: false,
      );
    }

    // If no additional options, show simple button
    if (!showDepositOption && !showTasterOption) {
      return AddToBasketButton(
        course: course,
        onPressed: onAddFullPrice,
        isCompact: false,
      );
    }

    // Show multiple options
    return Column(
      children: [
        // Full Price Button
        AddToBasketButton(
          course: course,
          onPressed: onAddFullPrice,
          isCompact: false,
        ),
        
        if (showDepositOption || showTasterOption) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              // Deposit Option
              if (showDepositOption) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddDeposit,
                    icon: const Icon(Icons.payment),
                    label: const Text('Deposit Only'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                      side: BorderSide(color: theme.colorScheme.secondary),
                    ),
                  ),
                ),
                if (showTasterOption) const SizedBox(width: 12),
              ],
              
              // Taster Option
              if (showTasterOption)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddTaster,
                    icon: const Icon(Icons.preview),
                    label: const Text('Taster'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.tertiary,
                      side: BorderSide(color: theme.colorScheme.tertiary),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}