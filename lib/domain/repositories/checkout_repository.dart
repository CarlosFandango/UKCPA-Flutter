import '../entities/checkout.dart';
import '../entities/basket.dart';

/// Repository interface for checkout and payment operations
/// Based on UKCPA website checkout functionality
abstract class CheckoutRepository {
  /// Get available payment methods for the current user
  Future<List<PaymentMethod>> getPaymentMethods();

  /// Get Stripe publishable key for client-side integration
  Future<String> getStripePublishableKey();

  /// Create a new payment method with billing address
  Future<PaymentMethod> createPaymentMethod({
    required String stripePaymentMethodId,
    required Address billingAddress,
    bool setAsDefault = false,
  });

  /// Delete a payment method
  Future<bool> deletePaymentMethod(String paymentMethodId);

  /// Set a payment method as default
  Future<bool> setDefaultPaymentMethod(String paymentMethodId);

  /// Place an order with payment processing
  Future<PaymentResult> placeOrder({
    required Basket basket,
    String? paymentMethodId,
    required String paymentMethodType,
    Address? billingAddress,
    Map<String, dynamic>? lineItemInfo,
  });

  /// Update payment intent after 3DS authentication
  Future<bool> updatePaymentIntent(String paymentIntentId);

  /// Get order details by ID
  Future<Order?> getOrder(String orderId);

  /// Get user's order history
  Future<List<Order>> getOrderHistory({
    int limit = 20,
    int offset = 0,
  });

  /// Cancel an order (if allowed)
  Future<bool> cancelOrder(String orderId);

  /// Process a refund (admin only)
  Future<bool> processRefund({
    required String orderId,
    required int amount,
    String? reason,
  });
}