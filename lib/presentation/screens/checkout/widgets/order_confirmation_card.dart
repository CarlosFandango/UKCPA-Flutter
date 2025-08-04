import 'package:flutter/material.dart';
import '../../../../domain/entities/basket.dart';
import '../../../../domain/entities/checkout.dart';
import 'order_summary_card.dart';

/// Order confirmation card for final checkout step
/// Shows order summary, payment method, and billing address for final review
class OrderConfirmationCard extends StatelessWidget {
  final Basket basket;
  final PaymentMethod? paymentMethod;
  final Address? billingAddress;

  const OrderConfirmationCard({
    super.key,
    required this.basket,
    this.paymentMethod,
    this.billingAddress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Review Your Order',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review your order details before completing your purchase.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Order summary (compact version)
        OrderSummaryCard(
          basket: basket,
          isCompact: true,
        ),
        
        const SizedBox(height: 20),
        
        // Payment method
        if (paymentMethod != null) ...[
          _buildPaymentMethodSection(context, theme),
          const SizedBox(height: 20),
        ],
        
        // Billing address
        if (billingAddress != null) ...[
          _buildBillingAddressSection(context, theme),
          const SizedBox(height: 20),
        ],
        
        // Important notices
        _buildImportantNotices(context, theme),
      ],
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payment,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Payment Method',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getCardColor(paymentMethod!.brand),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getBrandDisplayName(paymentMethod!.brand)} •••• ${paymentMethod!.last4}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Expires ${paymentMethod!.expiryMonth}/${paymentMethod!.expiryYear}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingAddressSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Billing Address',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            billingAddress!.displayName,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotices(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNoticeItem(
            theme,
            'Your order confirmation will be sent to your email address.',
          ),
          _buildNoticeItem(
            theme,
            'Course access details will be provided before the start date.',
          ),
          if (basket.hasPayLater)
            _buildNoticeItem(
              theme,
              'Remaining balance will be charged automatically before the course starts.',
            ),
          _buildNoticeItem(
            theme,
            'Cancellation policy applies as per our Terms and Conditions.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(top: 8, right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCardColor(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return Colors.blue[700]!;
      case 'mastercard':
        return Colors.red[700]!;
      case 'amex':
      case 'american_express':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getBrandDisplayName(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
      case 'american_express':
        return 'Amex';
      default:
        return brand?.toUpperCase() ?? 'Card';
    }
  }
}