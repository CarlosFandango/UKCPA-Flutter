import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/basket_provider.dart';
import '../../../domain/entities/course.dart';

/// Smart booking button that shows "Add to basket" or "Remove" based on basket state
/// Similar to UKCPA-Website's BookButton component
class BookButton extends ConsumerWidget {
  final Course course;
  final bool disabled;
  final String? customText;
  final bool singleItem;
  final bool payDeposit;
  final bool isTaster;
  final String? sessionId;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;

  const BookButton({
    Key? key,
    required this.course,
    this.disabled = false,
    this.customText,
    this.singleItem = false,
    this.payDeposit = false,
    this.isTaster = false,
    this.sessionId,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketNotifier = ref.watch(basketNotifierProvider.notifier);
    final isInBasket = ref.watch(courseInBasketProvider(course.id));
    final basketLoading = ref.watch(basketLoadingProvider);
    
    final theme = Theme.of(context);
    final isLoading = basketLoading;

    // Determine button text and action
    final bool showRemove = isInBasket && singleItem;
    final String buttonText = showRemove 
        ? 'Remove' 
        : customText ?? (isTaster ? 'Book Taster Class' : 'Add to Basket');

    // Determine button colors
    final Color backgroundColor = showRemove 
        ? theme.colorScheme.error 
        : theme.colorScheme.primary;
    final Color foregroundColor = showRemove 
        ? theme.colorScheme.onError 
        : theme.colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: disabled || isLoading ? null : () => _handleButtonPress(
          context,
          basketNotifier,
          showRemove,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: theme.colorScheme.surfaceVariant,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading 
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                buttonText,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleButtonPress(
    BuildContext context,
    BasketNotifier basketNotifier,
    bool isRemove,
  ) async {
    bool success;
    
    if (isRemove) {
      success = await basketNotifier.removeCourse(course.id);
    } else {
      success = await basketNotifier.addCourse(
        course.id,
        isTaster: isTaster,
        sessionId: sessionId,
      );
    }

    if (!context.mounted) return;

    if (success) {
      // Show success feedback
      _showSuccessSnackBar(context, isRemove);
      onSuccess?.call();
    } else {
      // Show error feedback
      _showErrorSnackBar(context, isRemove);
      onError?.call();
    }
  }

  void _showSuccessSnackBar(BuildContext context, bool wasRemove) {
    final message = wasRemove 
        ? 'Course removed from basket'
        : isTaster
            ? 'Taster class added to basket'
            : 'Course added to basket';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View Basket',
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {
            // TODO: Navigate to basket screen
            // Navigator.of(context).pushNamed('/basket');
          },
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, bool wasRemove) {
    final message = wasRemove 
        ? 'Failed to remove course from basket'
        : 'Failed to add course to basket';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            _handleButtonPress(context, 
              // Need to get basketNotifier reference again
              // This is a limitation of the current structure
              ProviderScope.containerOf(context).read(basketNotifierProvider.notifier),
              wasRemove
            );
          },
        ),
      ),
    );
  }
}

/// Variant of BookButton for taster classes
class TasterBookButton extends BookButton {
  const TasterBookButton({
    Key? key,
    required Course course,
    bool disabled = false,
    String? sessionId,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) : super(
          key: key,
          course: course,
          disabled: disabled,
          isTaster: true,
          sessionId: sessionId,
          customText: 'Book Taster Class',
          onSuccess: onSuccess,
          onError: onError,
        );
}

/// Variant of BookButton for deposit payments
class DepositBookButton extends BookButton {
  const DepositBookButton({
    Key? key,
    required Course course,
    bool disabled = false,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) : super(
          key: key,
          course: course,
          disabled: disabled,
          payDeposit: true,
          customText: 'Pay Deposit',
          onSuccess: onSuccess,
          onError: onError,
        );
}

/// Compact variant of BookButton for use in cards
class CompactBookButton extends BookButton {
  const CompactBookButton({
    Key? key,
    required Course course,
    bool disabled = false,
    bool isTaster = false,
    String? sessionId,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) : super(
          key: key,
          course: course,
          disabled: disabled,
          isTaster: isTaster,
          sessionId: sessionId,
          singleItem: true, // Show remove button when in basket
          onSuccess: onSuccess,
          onError: onError,
        );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 36, // Smaller height for compact version
      child: super.build(context, ref),
    );
  }
}