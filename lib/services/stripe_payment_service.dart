import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/payment_exception.dart';

/// Stripe payment service provider
final stripePaymentServiceProvider = Provider<StripePaymentService>((ref) {
  return StripePaymentService();
});

/// Service for handling Stripe payment operations
/// Matches the behavior of the UKCPA website's Stripe integration
class StripePaymentService {
  static bool _isInitialized = false;

  /// Initialize Stripe SDK
  /// Based on website's stripe initialization pattern
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      stripe.Stripe.publishableKey = AppConstants.stripePublishableKey;
      
      // Configure merchant settings
      await stripe.Stripe.instance.applySettings();

      _isInitialized = true;
      debugPrint('Stripe SDK initialized successfully');
    } catch (e) {
      throw PaymentException(
        message: 'Failed to initialize payment system',
        code: 'STRIPE_INIT_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Create a payment method from card details
  /// Matches website's stripe.createPaymentMethod implementation
  Future<stripe.PaymentMethod> createPaymentMethod({
    required Map<String, dynamic> cardDetails,
    stripe.BillingDetails? billingDetails,
  }) async {
    try {
      final paymentMethod = await stripe.Stripe.instance.createPaymentMethod(
        params: stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ),
      );

      return paymentMethod;
    } on stripe.StripeException catch (e) {
      throw PaymentException(
        message: _getReadableErrorMessage(e),
        code: e.error.code.name,
        details: e.error.message,
      );
    } catch (e) {
      throw PaymentException(
        message: 'Failed to process card details',
        code: 'UNKNOWN_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Confirm a payment intent with 3DS handling
  /// Matches website's stripe.confirmCardPayment implementation
  Future<PaymentIntentResult> confirmCardPayment({
    required String clientSecret,
  }) async {
    try {
      final result = await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: const stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(),
        ),
      );

      return _mapPaymentIntentStatus(result);
    } on stripe.StripeException catch (e) {
      // Handle 3DS cancellation like the website
      if (e.error.code == stripe.FailureCode.Canceled) {
        throw PaymentException(
          message: 'Authentication cancelled',
          code: 'AUTH_CANCELLED',
          isUserCancellation: true,
        );
      }
      
      throw PaymentException(
        message: _getReadableErrorMessage(e),
        code: e.error.code.name,
        details: e.error.message,
      );
    } catch (e) {
      if (e is PaymentException) rethrow;
      
      throw PaymentException(
        message: 'Payment processing failed',
        code: 'UNKNOWN_ERROR',
        details: e.toString(),
      );
    }
  }

  /// Handle 3D Secure authentication if required
  /// Based on website's 3DS handling pattern
  Future<PaymentIntentResult> handle3DSAuthentication({
    required String clientSecret,
  }) async {
    try {
      final result = await stripe.Stripe.instance.handleNextAction(clientSecret);
      
      return _mapPaymentIntentStatus(result);
    } on stripe.StripeException catch (e) {
      throw PaymentException(
        message: _getReadableErrorMessage(e),
        code: e.error.code.name,
        details: e.error.message,
      );
    }
  }

  /// Map Stripe PaymentIntent status to our result model
  /// Matches website's payment status handling
  PaymentIntentResult _mapPaymentIntentStatus(stripe.PaymentIntent paymentIntent) {
    switch (paymentIntent.status) {
      case stripe.PaymentIntentsStatus.Succeeded:
        return PaymentIntentResult(
          status: PaymentStatus.succeeded,
          paymentIntentId: paymentIntent.id,
        );
      case stripe.PaymentIntentsStatus.RequiresAction:
        return PaymentIntentResult(
          status: PaymentStatus.requiresAction,
          paymentIntentId: paymentIntent.id,
        );
      case stripe.PaymentIntentsStatus.RequiresPaymentMethod:
        return PaymentIntentResult(
          status: PaymentStatus.failed,
          errorMessage: 'Payment method required',
        );
      case stripe.PaymentIntentsStatus.Processing:
        return PaymentIntentResult(
          status: PaymentStatus.processing,
          paymentIntentId: paymentIntent.id,
        );
      case stripe.PaymentIntentsStatus.Canceled:
        return PaymentIntentResult(
          status: PaymentStatus.cancelled,
          errorMessage: 'Payment was cancelled',
        );
      default:
        return PaymentIntentResult(
          status: PaymentStatus.failed,
          errorMessage: 'Payment failed with status: ${paymentIntent.status}',
        );
    }
  }

  /// Get user-friendly error message from Stripe exception
  /// Matches website's error message handling
  String _getReadableErrorMessage(stripe.StripeException e) {
    final errorMessage = e.error.message ?? '';
    final errorCode = e.error.code.name.toLowerCase();
    
    // Map common error codes to user-friendly messages
    if (errorCode.contains('card_declined') || errorCode.contains('declined')) {
      return 'Your card was declined. Please try another card.';
    }
    if (errorCode.contains('invalid_number') || errorCode.contains('number')) {
      return 'The card number is invalid. Please check and try again.';
    }
    if (errorCode.contains('invalid_expiry') || errorCode.contains('expiry')) {
      return 'The expiry date is invalid. Please check and try again.';
    }
    if (errorCode.contains('invalid_cvc') || errorCode.contains('cvc')) {
      return 'The security code is invalid. Please check and try again.';
    }
    if (errorCode.contains('expired_card') || errorCode.contains('expired')) {
      return 'Your card has expired. Please use another card.';
    }
    if (errorCode.contains('insufficient_funds') || errorCode.contains('funds')) {
      return 'Your card has insufficient funds.';
    }
    if (errorCode.contains('processing_error') || errorCode.contains('processing')) {
      return 'An error occurred while processing your card. Please try again.';
    }
    
    // Return original message if we have one, otherwise generic message
    return errorMessage.isNotEmpty 
        ? errorMessage 
        : 'Payment failed. Please try again.';
  }

  /// Create billing details from address and user info
  /// Helper method to create billing details for payment methods
  static stripe.BillingDetails createBillingDetails({
    required String email,
    required String name,
    required BillingAddress address,
  }) {
    return stripe.BillingDetails(
      email: email,
      name: name,
      address: stripe.Address(
        line1: address.line1,
        line2: address.line2,
        city: address.city,
        state: address.county,
        country: address.countryCode,
        postalCode: address.postcode,
      ),
    );
  }
}

/// Payment intent result model matching website's response structure
class PaymentIntentResult {
  final PaymentStatus status;
  final String? paymentIntentId;
  final String? errorMessage;
  final String? clientSecret;

  PaymentIntentResult({
    required this.status,
    this.paymentIntentId,
    this.errorMessage,
    this.clientSecret,
  });

  bool get isSuccess => status == PaymentStatus.succeeded;
  bool get requiresAction => status == PaymentStatus.requiresAction;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
}

/// Payment status enum matching website's handling
enum PaymentStatus {
  succeeded,
  failed,
  cancelled,
  processing,
  requiresAction,
}

/// Billing address model for payment method creation
class BillingAddress {
  final String line1;
  final String? line2;
  final String city;
  final String county;
  final String postcode;
  final String countryCode;

  const BillingAddress({
    required this.line1,
    this.line2,
    required this.city,
    required this.county,
    required this.postcode,
    required this.countryCode,
  });

  Map<String, dynamic> toJson() => {
    'line1': line1,
    'line2': line2,
    'city': city,
    'county': county,
    'postcode': postcode,
    'countryCode': countryCode,
  };
}