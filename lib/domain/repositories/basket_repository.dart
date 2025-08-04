import '../entities/basket.dart';

/// Repository interface for basket operations
/// Based on the UKCPA website basket functionality analysis
abstract class BasketRepository {
  /// Initialize a new basket for the current user/session
  Future<Basket> initBasket();

  /// Get the current user's basket
  Future<Basket?> getBasket();

  /// Add an item to the basket
  /// [itemId] - Course ID or Session ID to add
  /// [itemType] - Type of item (course, session, exam, event)
  /// [payDeposit] - Whether to pay deposit only (for courses with deposit option)
  /// [assignToUserId] - Optional user ID to assign the item to (gift functionality)
  /// [chargeFromDate] - Optional date for date-based pricing
  Future<BasketOperationResult> addItem(
    String itemId, {
    required String itemType,
    bool? payDeposit,
    String? assignToUserId,
    DateTime? chargeFromDate,
  });

  /// Remove an item from the basket
  /// [itemId] - Item ID to remove
  /// [itemType] - Type of item being removed
  Future<BasketOperationResult> removeItem(String itemId, String itemType);

  /// Clear/destroy the current basket
  Future<bool> destroyBasket();

  /// Toggle credit usage for the basket
  /// [useCredit] - Whether to automatically apply available credits
  Future<BasketOperationResult> useCreditForBasket(bool useCredit);

  /// Apply a promo code to the basket
  /// [code] - Promo code to apply
  Future<BasketOperationResult> applyPromoCode(String code);

  /// Remove all applied promo codes from the basket
  Future<BasketOperationResult> removePromoCode();

  /// Watch basket changes for real-time updates
  Stream<Basket?> watchBasket();

  /// Get basket item count for badge display
  Future<int> getBasketItemCount();

  /// Check if a specific item is already in the basket
  Future<bool> isItemInBasket(String itemId, String itemType);
}