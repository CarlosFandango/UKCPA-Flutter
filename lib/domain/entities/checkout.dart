import 'package:freezed_annotation/freezed_annotation.dart';
import 'basket.dart';

part 'checkout.freezed.dart';
part 'checkout.g.dart';

/// Core checkout domain entities based on UKCPA website checkout functionality
/// Handles order placement, payment processing, and billing address management

@freezed
class Address with _$Address {
  const factory Address({
    String? id,
    String? name,
    required String line1,
    String? line2,
    required String city,
    String? county,
    required String postCode,
    String? country,
    @Default('GB') String countryCode,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
}

@freezed 
class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod({
    required String id,
    @Default('card') String type,
    String? last4,
    String? brand,
    String? expiryMonth,
    String? expiryYear,
    bool? isDefault,
    Address? billingAddress,
    DateTime? createdAt,
  }) = _PaymentMethod;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => _$PaymentMethodFromJson(json);
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String id,
    required String itemId,
    required String itemType,
    required String itemName,
    required int price,
    required int totalPrice,
    int? discountValue,
    int? promoCodeDiscountValue,
    String? assignToUserId,
    String? assignToUserName,
    DateTime? chargeFromDate,
    Map<String, dynamic>? extraInfo,
    DateTime? createdAt,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String userId,
    @Default([]) List<OrderItem> items,
    @Default(0) int subTotal,
    @Default(0) int discountTotal,
    @Default(0) int promoCodeDiscountValue,
    @Default(0) int creditTotal,
    @Default(0) int tax,
    @Default(0) int total,
    @Default(0) int chargeTotal,
    @Default(0) int payLater,
    @Default('pending') String status,
    String? paymentMethodId,
    @Default('card') String paymentMethodType,
    String? paymentIntentId,
    String? paymentTransactionStatus,
    Address? billingAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

/// Payment processing results
@freezed
class PaymentResult with _$PaymentResult {
  const factory PaymentResult({
    required bool success,
    Order? order,
    String? error,
    String? errorCode,
    String? clientSecret,
    @Default('none') String nextAction,
    String? paymentTransactionStatus,
  }) = _PaymentResult;

  factory PaymentResult.fromJson(Map<String, dynamic> json) => _$PaymentResultFromJson(json);
}

/// Checkout form state
@freezed
class CheckoutFormData with _$CheckoutFormData {
  const factory CheckoutFormData({
    Address? billingAddress,
    String? paymentMethodId,
    @Default('card') String paymentMethodType,
    @Default(false) bool savePaymentMethod,
    @Default(false) bool termsAccepted,
    Map<String, dynamic>? lineItemInfo,
  }) = _CheckoutFormData;

  factory CheckoutFormData.fromJson(Map<String, dynamic> json) => _$CheckoutFormDataFromJson(json);
}

/// Checkout session state
@freezed
class CheckoutSession with _$CheckoutSession {
  const factory CheckoutSession({
    String? id,
    Basket? basket,
    @Default([]) List<PaymentMethod> availablePaymentMethods,
    PaymentMethod? selectedPaymentMethod,
    Address? billingAddress,
    CheckoutFormData? formData,
    @Default(1) int currentStep,
    @Default(false) bool isProcessing,
    String? error,
    String? clientSecret,
  }) = _CheckoutSession;

  factory CheckoutSession.fromJson(Map<String, dynamic> json) => _$CheckoutSessionFromJson(json);
}

/// Extension methods for formatted display
extension CheckoutSessionExtensions on CheckoutSession {
  bool get canProceedToPayment => 
    basket != null && 
    !basket!.isEmpty && 
    currentStep >= 2 && 
    (selectedPaymentMethod != null || billingAddress != null);

  bool get requiresPayment => 
    basket != null && basket!.chargeTotal > 0;

  String get stepTitle {
    switch (currentStep) {
      case 1: return 'Review Order';
      case 2: return 'Payment Details';
      case 3: return 'Processing';
      case 4: return 'Complete';
      default: return 'Checkout';
    }
  }

  double get progressPercent => 
    currentStep >= 4 ? 100.0 : (currentStep * 25.0);
}

extension OrderExtensions on Order {
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'success';
  bool get isPaymentPending => status == 'payment_pending';
  bool get hasFailed => status == 'failed';

  bool get requiresAdditionalPayment => payLater > 0;
  
  String get statusDisplay {
    switch (status) {
      case 'success': return 'Completed';
      case 'pending': return 'Processing';
      case 'payment_pending': return 'Payment Pending';
      case 'failed': return 'Failed';
      default: return status;
    }
  }

  String get formattedTotal => '£${(total / 100).toStringAsFixed(2)}';
  String get formattedChargeTotal => '£${(chargeTotal / 100).toStringAsFixed(2)}';
  String get formattedPayLater => '£${(payLater / 100).toStringAsFixed(2)}';
}

extension AddressExtensions on Address {
  String get displayName {
    final parts = <String>[];
    if (name != null && name!.isNotEmpty) parts.add(name!);
    parts.add(line1);
    if (line2 != null && line2!.isNotEmpty) parts.add(line2!);
    parts.add(city);
    parts.add(postCode);
    return parts.join(', ');
  }

  String get shortDisplay => '$line1, $city $postCode';
}