import 'package:flutter/material.dart';
import '../../../../domain/entities/basket.dart';
import '../../../../core/utils/text_utils.dart';

/// Order summary card for checkout screens
/// Displays basket contents with pricing breakdown
class OrderSummaryCard extends StatelessWidget {
  final Basket basket;
  final bool showEditButton;
  final VoidCallback? onEdit;
  final bool isCompact;

  const OrderSummaryCard({
    super.key,
    required this.basket,
    this.showEditButton = false,
    this.onEdit,
    this.isCompact = false,
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
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, theme),
            
            const SizedBox(height: 16),
            
            // Items list
            if (!isCompact) ...basket.items.map((item) => _buildItemRow(context, theme, item)),
            
            if (isCompact && basket.items.isNotEmpty) ...[
              _buildCompactItemsList(context, theme),
              const SizedBox(height: 16),
            ],
            
            // Pricing summary
            _buildPricingSummary(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${basket.itemCount} item${basket.itemCount != 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (showEditButton && onEdit != null)
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildItemRow(BuildContext context, ThemeData theme, BasketItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.isTaster ? Icons.preview : Icons.school,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.itemTypeDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (item.hasDiscount) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        item.formattedPrice,
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SAVE ${item.formattedDiscountValue}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.formattedTotalPrice,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (item.hasDiscount)
                Text(
                  'per item',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItemsList(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items in your order:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          ...basket.items.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  '• ',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                Expanded(
                  child: Text(
                    item.displayName,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.formattedTotalPrice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
          if (basket.items.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              '... and ${basket.items.length - 3} more item${basket.items.length - 3 > 1 ? 's' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingSummary(BuildContext context, ThemeData theme) {
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
        children: [
          // Subtotal
          _buildPricingRow('Subtotal', basket.formattedSubTotal, theme),
          
          // Discounts
          if (basket.discountTotal > 0) ...[
            const SizedBox(height: 8),
            _buildPricingRow(
              'Discount',
              '-${TextUtils.formatPrice(basket.discountTotal)}',
              theme,
              valueColor: Colors.green[700],
            ),
          ],
          
          // Promo code discount
          if (basket.promoCodeDiscountValue > 0) ...[
            const SizedBox(height: 8),
            _buildPricingRow(
              'Promo Code',
              '-${TextUtils.formatPrice(basket.promoCodeDiscountValue)}',
              theme,
              valueColor: Colors.green[700],
            ),
          ],
          
          // Credits
          if (basket.creditTotal > 0) ...[
            const SizedBox(height: 8),
            _buildPricingRow(
              'Account Credit',
              '-${TextUtils.formatPrice(basket.creditTotal)}',
              theme,
              valueColor: Colors.blue[700],
            ),
          ],
          
          // Tax
          if (basket.tax > 0) ...[
            const SizedBox(height: 8),
            _buildPricingRow(
              'VAT (20%)',
              TextUtils.formatPrice(basket.tax),
              theme,
            ),
          ],
          
          // Divider
          if (basket.hasDiscounts || basket.hasCredits || basket.tax > 0) ...[
            const SizedBox(height: 12),
            Divider(
              color: theme.colorScheme.outline.withOpacity(0.3),
              height: 1,
            ),
            const SizedBox(height: 12),
          ],
          
          // Total
          _buildPricingRow(
            'Total',
            basket.formattedTotal,
            theme,
            isTotal: true,
          ),
          
          // Payment breakdown for deposits
          if (basket.hasPayLater) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Payment Breakdown',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPricingRow(
                    'Pay now',
                    basket.formattedChargeTotal,
                    theme,
                    valueColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 4),
                  _buildPricingRow(
                    'Pay later',
                    basket.formattedPayLater,
                    theme,
                    valueColor: theme.colorScheme.secondary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPricingRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
        ),
      ],
    );
  }
}