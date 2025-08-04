import 'package:flutter/material.dart';
import '../../../../domain/entities/basket.dart';
import '../../../../core/utils/text_utils.dart';

/// Basket summary widget showing pricing breakdown and checkout
/// Based on UKCPA website basket summary functionality
class BasketSummary extends StatefulWidget {
  final Basket basket;
  final VoidCallback onCheckout;
  final Function(String) onApplyPromoCode;
  final VoidCallback onRemovePromoCode;
  final Function(bool) onToggleCredit;

  const BasketSummary({
    super.key,
    required this.basket,
    required this.onCheckout,
    required this.onApplyPromoCode,
    required this.onRemovePromoCode,
    required this.onToggleCredit,
  });

  @override
  State<BasketSummary> createState() => _BasketSummaryState();
}

class _BasketSummaryState extends State<BasketSummary> {
  final TextEditingController _promoCodeController = TextEditingController();
  bool _showPromoCodeInput = false;

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Promo code section
        _buildPromoCodeSection(theme),
        
        const SizedBox(height: 16),
        
        // Credit usage toggle (if user has credits)
        if (widget.basket.creditTotal > 0 || widget.basket.hasCredits)
          _buildCreditSection(theme),
        
        // Pricing breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Subtotal
              _buildSummaryRow(
                'Subtotal',
                widget.basket.formattedSubTotal,
                theme,
              ),
              
              // Discounts (if any)
              if (widget.basket.discountTotal > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Discount',
                  '-${TextUtils.formatPrice(widget.basket.discountTotal)}',
                  theme,
                  valueColor: theme.colorScheme.error,
                ),
              ],
              
              // Promo code discounts (if any)
              if (widget.basket.promoCodeDiscountValue > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Promo Code',
                  '-${TextUtils.formatPrice(widget.basket.promoCodeDiscountValue)}',
                  theme,
                  valueColor: theme.colorScheme.error,
                ),
              ],
              
              // Credits applied (if any)
              if (widget.basket.creditTotal > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'Credits Applied',
                  '-${TextUtils.formatPrice(widget.basket.creditTotal)}',
                  theme,
                  valueColor: theme.colorScheme.error,
                ),
              ],
              
              // Tax (if applicable)
              if (widget.basket.tax > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'VAT (20%)',
                  TextUtils.formatPrice(widget.basket.tax),
                  theme,
                ),
              ],
              
              // Total savings (if any)
              if (widget.basket.totalSavings > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Savings',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.basket.formattedSavings,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Divider before total
              if (widget.basket.hasDiscounts || widget.basket.hasCredits || widget.basket.tax > 0) ...[
                const SizedBox(height: 12),
                Divider(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  height: 1,
                ),
                const SizedBox(height: 12),
              ],
              
              // Total
              _buildSummaryRow(
                'Total',
                widget.basket.formattedTotal,
                theme,
                isTotal: true,
              ),
              
              // Payment breakdown (if using deposits)
              if (widget.basket.hasPayLater) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Payment Breakdown',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pay now',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            widget.basket.formattedChargeTotal,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pay later',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            widget.basket.formattedPayLater,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Checkout button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.basket.isEmpty ? null : widget.onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Secure Checkout • ${widget.basket.formattedTotal}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Security notice
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              'Secure payment powered by Stripe',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build promo code input section
  Widget _buildPromoCodeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Promo code header with toggle
        Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Promo Code',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _showPromoCodeInput = !_showPromoCodeInput;
                });
              },
              child: Text(_showPromoCodeInput ? 'Cancel' : 'Add Code'),
            ),
          ],
        ),
        
        // Promo code input (if visible)
        if (_showPromoCodeInput) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _promoCodeController.text.isEmpty 
                    ? null 
                    : () {
                        widget.onApplyPromoCode(_promoCodeController.text.trim());
                        _promoCodeController.clear();
                        setState(() {
                          _showPromoCodeInput = false;
                        });
                      },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
        
        // Applied promo codes (if any)
        if (widget.basket.promoCodeDiscountValue > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.successContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Promo code applied',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '-${TextUtils.formatPrice(widget.basket.promoCodeDiscountValue)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onRemovePromoCode,
                  child: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Build credit usage section
  Widget _buildCreditSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Account Credits',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.basket.creditTotal > 0)
                  Text(
                    '${TextUtils.formatPrice(widget.basket.creditTotal)} applied',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: widget.basket.creditTotal > 0,
            onChanged: widget.onToggleCredit,
          ),
        ],
      ),
    );
  }

  /// Build a summary row
  Widget _buildSummaryRow(
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
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
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