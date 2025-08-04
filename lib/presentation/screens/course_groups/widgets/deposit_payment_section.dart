import 'package:flutter/material.dart';
import '../../../../domain/entities/course.dart';
import '../../../../core/utils/text_utils.dart';

/// Widget that displays deposit payment option matching website design
class DepositPaymentSection extends StatelessWidget {
  final Course course;
  final bool disabled;
  final VoidCallback? onPayDeposit;

  const DepositPaymentSection({
    super.key,
    required this.course,
    this.disabled = false,
    this.onPayDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show if deposits aren't accepted or prices aren't available
    if (!course.isAcceptingDeposits || 
        course.depositPrice == null || 
        course.depositPrice! <= 0) {
      return const SizedBox.shrink();
    }

    final depositPrice = course.depositPrice!;
    final totalPrice = course.currentPrice ?? course.price;
    final remainingPrice = totalPrice - depositPrice;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with dollar icon and title
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pay in Installments',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description of payment plan
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              children: [
                const TextSpan(text: 'Pay '),
                TextSpan(
                  text: TextUtils.formatPrice(depositPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const TextSpan(text: ' now and '),
                TextSpan(
                  text: TextUtils.formatPrice(remainingPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const TextSpan(text: ' later'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment breakdown and button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextUtils.formatPrice(depositPrice),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    '(Deposit)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: disabled ? null : () {
                    onPayDeposit?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Pay Deposit',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Optional: Show payment breakdown
          if (remainingPrice > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildBreakdownRow(
                    'Deposit today:',
                    TextUtils.formatPrice(depositPrice),
                    theme,
                    isDeposit: true,
                  ),
                  const SizedBox(height: 4),
                  _buildBreakdownRow(
                    'Remaining balance:',
                    TextUtils.formatPrice(remainingPrice),
                    theme,
                  ),
                  const Divider(height: 16),
                  _buildBreakdownRow(
                    'Total course price:',
                    TextUtils.formatPrice(totalPrice),
                    theme,
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build a breakdown row for payment details
  Widget _buildBreakdownRow(
    String label,
    String amount,
    ThemeData theme, {
    bool isDeposit = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDeposit 
                ? theme.colorScheme.primary 
                : isTotal 
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.8),
            fontWeight: isTotal || isDeposit ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// Extension for easier creation of deposit payment sections
extension DepositPaymentSectionExtensions on DepositPaymentSection {
  /// Create a deposit payment section with preset styling
  static Widget create({
    required Course course,
    bool disabled = false,
    VoidCallback? onPayDeposit,
  }) {
    return DepositPaymentSection(
      course: course,
      disabled: disabled,
      onPayDeposit: onPayDeposit,
    );
  }

  /// Check if course is eligible for deposit payments
  static bool isEligible(Course course) {
    return course.isAcceptingDeposits && 
           course.depositPrice != null && 
           course.depositPrice! > 0;
  }
}