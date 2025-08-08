import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

/// Stripe card input form widget
/// Provides a native Stripe card input field with consistent styling
class StripeCardInputForm extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onCardChanged;
  final Function(Map<String, dynamic>)? onCardComplete;
  final bool enabled;
  final String? errorText;

  const StripeCardInputForm({
    super.key,
    required this.onCardChanged,
    this.onCardComplete,
    this.enabled = true,
    this.errorText,
  });

  @override
  ConsumerState<StripeCardInputForm> createState() => _StripeCardInputFormState();
}

class _StripeCardInputFormState extends ConsumerState<StripeCardInputForm> {
  Map<String, dynamic> _cardData = {};
  bool _isComplete = false;

  void _onCardChanged(Map<String, dynamic> cardData) {
    setState(() {
      _cardData = cardData;
      _isComplete = _isCardComplete(cardData);
    });
    
    widget.onCardChanged(cardData);

    // Check if card is complete (matches website's validation)
    if (_isComplete) {
      widget.onCardComplete?.call(cardData);
    }
  }

  bool _isCardComplete(Map<String, dynamic> cardData) {
    final complete = cardData['complete'] as bool? ?? false;
    return complete;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.errorText != null 
                ? AppTheme.errorColor 
                : Colors.grey[300]!,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
            color: widget.enabled ? Colors.white : AppTheme.backgroundColor,
          ),
          child: stripe.CardField(
            onCardChanged: (card) {
              if (card != null) {
                _onCardChanged({
                  'complete': card.complete,
                  'validNumber': card.validNumber,
                  'validCVC': card.validCVC,
                  'validExpiryDate': card.validExpiryDate,
                  'last4': card.last4,
                  'brand': card.brand,
                });
              }
            },
            enablePostalCode: false, // Handle separately to match website
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.errorColor,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildSecurityNotice(),
      ],
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            size: 20,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Payment',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your card details are encrypted and secure. We never store your full card number.',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card validation result model
class CardValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? cardData;

  const CardValidationResult({
    required this.isValid,
    this.errorMessage,
    this.cardData,
  });

  factory CardValidationResult.valid(Map<String, dynamic> cardData) {
    return CardValidationResult(
      isValid: true,
      cardData: cardData,
    );
  }

  factory CardValidationResult.invalid(String errorMessage) {
    return CardValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

/// Helper class for card validation
class CardValidationHelper {
  /// Validate card details and return validation result
  /// Matches website's client-side validation
  static CardValidationResult validateCard(Map<String, dynamic> cardData) {
    final complete = cardData['complete'] as bool? ?? false;
    if (!complete) {
      return CardValidationResult.invalid('Please complete all card fields');
    }

    final validNumber = cardData['validNumber'] as bool? ?? false;
    if (!validNumber) {
      return CardValidationResult.invalid('Please enter a valid card number');
    }

    final validExpiryDate = cardData['validExpiryDate'] as bool? ?? false;
    if (!validExpiryDate) {
      return CardValidationResult.invalid('Please enter a valid expiry date');
    }

    final validCVC = cardData['validCVC'] as bool? ?? false;
    if (!validCVC) {
      return CardValidationResult.invalid('Please enter a valid security code');
    }

    return CardValidationResult.valid(cardData);
  }

  /// Get card brand from card number
  static String getCardBrand(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) return 'unknown';
    
    // Remove spaces and non-digits
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanNumber.startsWith('4')) return 'visa';
    if (cleanNumber.startsWith('5') || 
        (cleanNumber.length >= 4 && 
         int.tryParse(cleanNumber.substring(0, 4)) != null &&
         int.parse(cleanNumber.substring(0, 4)) >= 2221 && 
         int.parse(cleanNumber.substring(0, 4)) <= 2720)) {
      return 'mastercard';
    }
    if (cleanNumber.startsWith('34') || cleanNumber.startsWith('37')) return 'amex';
    if (cleanNumber.startsWith('6011') || cleanNumber.startsWith('65')) return 'discover';
    
    return 'unknown';
  }

  /// Format card number for display (e.g., "**** **** **** 1234")
  static String formatCardNumber(String? cardNumber) {
    if (cardNumber == null || cardNumber.length < 4) return '';
    
    final lastFour = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $lastFour';
  }
}