import 'package:flutter/material.dart';
import '../../../../domain/entities/checkout.dart';

/// Payment method selection widget for checkout
/// Allows users to select from saved payment methods or add new ones
class PaymentMethodSelection extends StatelessWidget {
  final List<PaymentMethod> availablePaymentMethods;
  final PaymentMethod? selectedPaymentMethod;
  final Function(PaymentMethod) onPaymentMethodSelected;
  final VoidCallback onAddPaymentMethod;

  const PaymentMethodSelection({
    super.key,
    required this.availablePaymentMethods,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    required this.onAddPaymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (availablePaymentMethods.isEmpty) ...[
              // No payment methods - show add card option
              _buildAddPaymentMethodCard(context, theme),
            ] else ...[
              // Show available payment methods
              ...availablePaymentMethods.map((method) => 
                _buildPaymentMethodCard(context, theme, method)
              ),
              const SizedBox(height: 12),
              _buildAddNewCardButton(context, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, ThemeData theme, PaymentMethod method) {
    final isSelected = selectedPaymentMethod?.id == method.id;
    
    return GestureDetector(
      onTap: () => onPaymentMethodSelected(method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Card icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getCardColor(method.brand),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getCardIcon(method.brand),
                color: Colors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Card details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getBrandDisplayName(method.brand)} •••• ${method.last4}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Expires ${method.expiryMonth}/${method.expiryYear}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  if (method.isDefault == true) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DEFAULT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: theme.colorScheme.outline,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPaymentMethodCard(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: onAddPaymentMethod,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_card,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Add Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a credit or debit card to complete your purchase',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewCardButton(BuildContext context, ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: onAddPaymentMethod,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add New Card'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  IconData _getCardIcon(String? brand) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american_express':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
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