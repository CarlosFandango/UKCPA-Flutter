import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/course.dart';
import '../../../providers/basket_provider.dart';

/// Add to basket button widget for courses
/// Enhanced in Phase 3 with full basket integration
class AddToBasketButton extends ConsumerStatefulWidget {
  final Course course;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final EdgeInsetsGeometry? padding;
  final bool isCompact;
  final bool isTaster;
  final bool payDeposit;
  final String? sessionId;

  const AddToBasketButton({
    super.key,
    required this.course,
    this.onPressed,
    this.isEnabled = true,
    this.padding,
    this.isCompact = true,
    this.isTaster = false,
    this.payDeposit = false,
    this.sessionId,
  });

  @override
  ConsumerState<AddToBasketButton> createState() => _AddToBasketButtonState();
}

class _AddToBasketButtonState extends ConsumerState<AddToBasketButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

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
    final isInBasket = ref.watch(courseInBasketProvider(widget.course.id));
    final basketLoading = ref.watch(basketLoadingProvider);
    
    // Check if this specific item (course/taster) is in basket
    final basketState = ref.watch(basketNotifierProvider);
    final specificItemInBasket = basketState.basket?.items.any((item) => 
      item.course.id == widget.course.id && item.isTaster == widget.isTaster
    ) ?? false;

    final isEnabled = widget.isEnabled && 
                     widget.course.isAvailable && 
                     !widget.course.fullyBooked &&
                     !_isLoading &&
                     !basketLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildButton(theme, isEnabled, specificItemInBasket),
        );
      },
    );
  }

  Widget _buildButton(ThemeData theme, bool isEnabled, bool isInBasket) {
    if (!widget.course.isAvailable) {
      return _buildDisabledButton(theme, 'Not Available');
    }

    if (widget.course.fullyBooked) {
      return _buildDisabledButton(theme, 'Fully Booked');
    }

    if (isInBasket) {
      return _buildInBasketButton(theme);
    }

    if (!isEnabled) {
      return _buildDisabledButton(theme, 'Loading...');
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
      onTap: () => _handleAddToBasket(),
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
            if (_isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            else
              Icon(
                Icons.add_shopping_cart,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
            const SizedBox(width: 6),
            Text(
              _isLoading ? 'Adding...' : 'Add',
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
      onTap: () => _handleAddToBasket(),
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
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            else
              Icon(
                Icons.add_shopping_cart,
                color: theme.colorScheme.onPrimary,
              ),
            const SizedBox(width: 8),
            Text(
              _isLoading ? 'Adding to Basket...' : 'Add to Basket',
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

  Widget _buildInBasketButton(ThemeData theme) {
    final buttonContent = Row(
      mainAxisSize: widget.isCompact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: widget.isCompact ? 16 : 20,
          color: theme.colorScheme.primary,
        ),
        SizedBox(width: widget.isCompact ? 6 : 8),
        Text(
          widget.isCompact ? 'Added' : 'In Basket',
          style: (widget.isCompact ? theme.textTheme.bodySmall : theme.textTheme.titleMedium)?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
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
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(widget.isCompact ? 20 : 12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
      ),
      child: buttonContent,
    );
  }

  Widget _buildDisabledButton(ThemeData theme, String text) {
    final buttonContent = Row(
      mainAxisSize: widget.isCompact ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.block,
          size: widget.isCompact ? 16 : 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: widget.isCompact ? 6 : 8),
        Text(
          widget.isCompact ? (text == 'Not Available' ? 'N/A' : text) : text,
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
        color: theme.colorScheme.surfaceVariant,
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

  /// Handle adding course to basket
  Future<void> _handleAddToBasket() async {
    if (_isLoading) return;

    // Call custom onPressed if provided
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final basketNotifier = ref.read(basketNotifierProvider.notifier);
      final success = await basketNotifier.addCourse(
        widget.course.id,
        isTaster: widget.isTaster,
        payDeposit: widget.payDeposit,
      );

      if (mounted) {
        if (success) {
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.course.name} added to basket',
              ),
              action: SnackBarAction(
                label: 'View Basket',
                onPressed: () {
                  // Navigate to basket - would need GoRouter context
                  // context.go('/basket');
                },
              ),
            ),
          );
        } else {
          // Show error from basket state
          final error = ref.read(basketErrorProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to add course to basket'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Enhanced add to basket button with multiple booking options
/// Used in individual course detail screen with full basket integration
class EnhancedAddToBasketButton extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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

    // Show multiple options with basket integration
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
                  child: _buildDepositButton(context, ref, theme),
                ),
                if (showTasterOption) const SizedBox(width: 12),
              ],
              
              // Taster Option
              if (showTasterOption)
                Expanded(
                  child: _buildTasterButton(context, ref, theme),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDepositButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    final basketState = ref.watch(basketNotifierProvider);
    final depositInBasket = basketState.basket?.items.any((item) => 
      item.course.id == course.id && !item.isTaster
    ) ?? false;

    return OutlinedButton.icon(
      onPressed: depositInBasket ? null : () async {
        if (onAddDeposit != null) {
          onAddDeposit!();
        } else {
          // Add deposit payment to basket
          final basketNotifier = ref.read(basketNotifierProvider.notifier);
          final success = await basketNotifier.addCourse(
            course.id,
            payDeposit: true,
          );
          
          if (context.mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${course.name} (deposit) added to basket')),
            );
          }
        }
      },
      icon: Icon(depositInBasket ? Icons.check_circle : Icons.payment),
      label: Text(depositInBasket ? 'Deposit Added' : 'Deposit Only'),
      style: OutlinedButton.styleFrom(
        foregroundColor: depositInBasket 
            ? theme.colorScheme.primary 
            : theme.colorScheme.secondary,
        side: BorderSide(
          color: depositInBasket 
              ? theme.colorScheme.primary 
              : theme.colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildTasterButton(BuildContext context, WidgetRef ref, ThemeData theme) {
    final basketState = ref.watch(basketNotifierProvider);
    final tasterInBasket = basketState.basket?.items.any((item) => 
      item.course.id == course.id && item.isTaster
    ) ?? false;

    return OutlinedButton.icon(
      onPressed: tasterInBasket ? null : () async {
        if (onAddTaster != null) {
          onAddTaster!();
        } else {
          // Add taster to basket
          final basketNotifier = ref.read(basketNotifierProvider.notifier);
          final success = await basketNotifier.addCourse(
            course.id,
            isTaster: true,
          );
          
          if (context.mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${course.name} (taster) added to basket')),
            );
          }
        }
      },
      icon: Icon(tasterInBasket ? Icons.check_circle : Icons.preview),
      label: Text(tasterInBasket ? 'Taster Added' : 'Taster Class'),
      style: OutlinedButton.styleFrom(
        foregroundColor: tasterInBasket 
            ? theme.colorScheme.primary 
            : theme.colorScheme.tertiary,
        side: BorderSide(
          color: tasterInBasket 
              ? theme.colorScheme.primary 
              : theme.colorScheme.tertiary,
        ),
      ),
    );
  }
}