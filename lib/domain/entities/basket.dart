import 'package:freezed_annotation/freezed_annotation.dart';
import 'course.dart';

part 'basket.freezed.dart';
part 'basket.g.dart';

/// Basket item representing a course, session, exam, or event in the user's basket
/// Based on LineItem from the website GraphQL schema
@freezed
class BasketItem with _$BasketItem {
  const factory BasketItem({
    required String id,
    required Course course,
    required int price,
    int? discountValue,
    int? promoCodeDiscountValue,
    required int totalPrice,
    DateTime? addedAt,
    String? sessionId, // For specific session bookings
    @Default(false) bool isTaster,
  }) = _BasketItem;

  factory BasketItem.fromJson(Map<String, dynamic> json) => _$BasketItemFromJson(json);
}

/// Credit item for account credits applied to the basket
/// Based on CreditItem from the website GraphQL schema
@freezed
class CreditItem with _$CreditItem {
  const factory CreditItem({
    required String id,
    required String description,
    required int value,
    String? code,
    DateTime? validUntil,
  }) = _CreditItem;

  factory CreditItem.fromJson(Map<String, dynamic> json) => _$CreditItemFromJson(json);
}

/// Fee item for additional charges (registration fees, etc.)
/// Based on FeeItem from the website GraphQL schema
@freezed
class FeeItem with _$FeeItem {
  const factory FeeItem({
    required String id,
    required String description,
    required int value,
    @Default(false) bool optional,
  }) = _FeeItem;

  factory FeeItem.fromJson(Map<String, dynamic> json) => _$FeeItemFromJson(json);
}

/// Main basket entity containing items, pricing, and calculations
/// Based on Basket from the website GraphQL schema
@freezed
class Basket with _$Basket {
  const factory Basket({
    required String id,
    @Default([]) List<BasketItem> items,
    @Default([]) List<CreditItem> creditItems,
    @Default([]) List<FeeItem> feeItems,
    @Default(0) int discountValue,
    @Default(0) int discountTotal,
    @Default(0) int promoCodeDiscountValue,
    @Default(0) int creditTotal,
    @Default(0) int subTotal,
    @Default(0) int tax,
    @Default(0) int total,
    @Default(0) int chargeTotal,
    @Default(0) int payLater,
    String? sessionId, // For anonymous users
    String? userId, // For authenticated users
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) = _Basket;

  factory Basket.fromJson(Map<String, dynamic> json) => _$BasketFromJson(json);
}

/// Result wrapper for basket operations
/// Based on BasketOperationResult from the website GraphQL schema
@freezed
class BasketOperationResult with _$BasketOperationResult {
  const factory BasketOperationResult({
    required bool success,
    required Basket basket,
    String? message,
    String? errorCode,
  }) = _BasketOperationResult;

  factory BasketOperationResult.fromJson(Map<String, dynamic> json) => _$BasketOperationResultFromJson(json);
}

/// Extension methods for basket utilities
extension BasketExtensions on Basket {
  /// Check if the basket is empty
  bool get isEmpty => items.isEmpty;

  /// Get the total number of items in the basket
  int get itemCount => items.length;

  /// Check if the basket has any discounts applied
  bool get hasDiscounts => discountTotal > 0 || promoCodeDiscountValue > 0;

  /// Check if the basket has credits applied
  bool get hasCredits => creditTotal > 0;

  /// Check if the basket has a pay later amount (deposit payments)
  bool get hasPayLater => payLater > 0;

  /// Get items that are taster sessions
  List<BasketItem> get tasterItems => items.where((item) => item.isTaster).toList();

  /// Get items that are full courses
  List<BasketItem> get courseItems => items.where((item) => !item.isTaster).toList();

  /// Calculate savings amount (discounts + credits)
  int get totalSavings => discountTotal + promoCodeDiscountValue + creditTotal;

  /// Get formatted price strings using existing TextUtils
  String get formattedSubTotal => '£${(subTotal / 100).toStringAsFixed(2)}';
  String get formattedTotal => '£${(total / 100).toStringAsFixed(2)}';
  String get formattedChargeTotal => '£${(chargeTotal / 100).toStringAsFixed(2)}';
  String get formattedPayLater => '£${(payLater / 100).toStringAsFixed(2)}';
  String get formattedSavings => '£${(totalSavings / 100).toStringAsFixed(2)}';
}

/// Extension methods for basket item utilities
extension BasketItemExtensions on BasketItem {
  /// Check if the item has a discount applied
  bool get hasDiscount => (discountValue ?? 0) > 0 || (promoCodeDiscountValue ?? 0) > 0;

  /// Get the total discount for this item
  int get totalDiscount => (discountValue ?? 0) + (promoCodeDiscountValue ?? 0);

  /// Get formatted price strings
  String get formattedPrice => '£${(price / 100).toStringAsFixed(2)}';
  String get formattedTotalPrice => '£${(totalPrice / 100).toStringAsFixed(2)}';

  /// Get item type display name based on course type and properties
  String get itemTypeDisplay {
    if (isTaster) return 'Taster Class';
    if (course.type == 'OnlineCourse') return 'Online Course';
    if (course.type == 'StudioCourse') return 'Studio Course';
    return 'Course';
  }

  /// Get a shortened version of the course name for display
  String get displayName {
    if (course.name.length <= 30) return course.name;
    return '${course.name.substring(0, 27)}...';
  }
}

/// Basket exceptions for error handling
class BasketException implements Exception {
  final String message;
  final String? errorCode;
  final dynamic cause;

  const BasketException(this.message, {this.errorCode, this.cause});

  @override
  String toString() => 'BasketException: $message${errorCode != null ? ' ($errorCode)' : ''}';
}