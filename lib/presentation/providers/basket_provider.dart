import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/basket.dart';
import '../../domain/repositories/basket_repository.dart';
import '../../data/repositories/basket_repository_impl.dart';

final Logger _logger = Logger();

/// Provider for basket repository
final basketRepositoryProvider = Provider<BasketRepository>((ref) {
  return BasketRepositoryImpl();
});

/// Basket state for managing loading and data
/// Based on UKCPA website basket functionality analysis
class BasketState {
  final Basket? basket;
  final bool isLoading;
  final String? error;
  final bool hasError;

  const BasketState({
    this.basket,
    this.isLoading = false,
    this.error,
  }) : hasError = error != null;

  BasketState copyWith({
    Basket? basket,
    bool? isLoading,
    String? error,
  }) {
    return BasketState(
      basket: basket ?? this.basket,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  BasketState loading() {
    return copyWith(isLoading: true, error: null);
  }

  BasketState success(Basket basket) {
    return copyWith(basket: basket, isLoading: false, error: null);
  }

  BasketState failure(String error) {
    return copyWith(isLoading: false, error: error);
  }

  @override
  String toString() {
    return 'BasketState(basket: ${basket?.id}, isLoading: $isLoading, hasError: $hasError, error: $error)';
  }
}

/// Basket state notifier for managing basket operations
/// Implements all operations from website analysis
class BasketNotifier extends StateNotifier<BasketState> {
  final BasketRepository _basketRepository;

  BasketNotifier(this._basketRepository) : super(const BasketState()) {
    // Initialize by fetching current basket
    _initializeBasket();
  }

  /// Initialize basket by fetching current or creating new basket
  Future<void> _initializeBasket() async {
    try {
      state = state.loading();
      _logger.d('Initializing basket');

      // Try to get existing basket first
      final existingBasket = await _basketRepository.getBasket();
      
      if (existingBasket != null) {
        _logger.d('Found existing basket with ${existingBasket.itemCount} items');
        state = state.success(existingBasket);
      } else {
        _logger.d('No existing basket found, creating new basket');
        final newBasket = await _basketRepository.initBasket();
        state = state.success(newBasket);
      }
    } catch (e) {
      _logger.e('Error initializing basket: $e');
      state = state.failure('Failed to initialize basket: ${e.toString()}');
    }
  }

  /// Refresh basket from server
  Future<void> refreshBasket() async {
    try {
      state = state.loading();
      _logger.d('Refreshing basket');

      final basket = await _basketRepository.getBasket();
      
      if (basket != null) {
        state = state.success(basket);
        _logger.d('Basket refreshed successfully');
      } else {
        // If no basket exists, create a new one
        final newBasket = await _basketRepository.initBasket();
        state = state.success(newBasket);
      }
    } catch (e) {
      _logger.e('Error refreshing basket: $e');
      state = state.failure('Failed to refresh basket: ${e.toString()}');
    }
  }

  /// Add item to basket
  /// [itemId] - Course ID or Session ID to add
  /// [itemType] - Type of item (course, session, taster)
  /// [payDeposit] - Whether to pay deposit only (for courses with deposit option)
  /// [assignToUserId] - Optional user ID to assign the item to (gift functionality)
  /// [chargeFromDate] - Optional date for date-based pricing
  Future<bool> addItem(
    String itemId, {
    String itemType = 'course',
    bool? payDeposit,
    String? assignToUserId,
    DateTime? chargeFromDate,
  }) async {
    try {
      _logger.d('Adding item to basket: $itemId, type: $itemType, payDeposit: $payDeposit');

      final result = await _basketRepository.addItem(
        itemId,
        itemType: itemType,
        payDeposit: payDeposit,
        assignToUserId: assignToUserId,
        chargeFromDate: chargeFromDate,
      );

      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Item added to basket successfully');
        return true;
      } else {
        state = state.failure(result.message ?? 'Failed to add item to basket');
        _logger.e('Failed to add item: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error adding item to basket: $e');
      state = state.failure('Failed to add item to basket: ${e.toString()}');
      return false;
    }
  }

  /// Add course to basket (convenience method)
  Future<bool> addCourse(
    String courseId, {
    bool isTaster = false,
    String? sessionId,
    bool? payDeposit,
  }) async {
    return addItem(
      courseId,
      itemType: isTaster ? 'taster' : 'course',
      payDeposit: payDeposit,
    );
  }

  /// Remove item from basket
  Future<bool> removeItem(String itemId, String itemType) async {
    try {
      _logger.d('Removing item from basket: $itemId, type: $itemType');

      final result = await _basketRepository.removeItem(itemId, itemType);

      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Item removed from basket successfully');
        return true;
      } else {
        state = state.failure(result.message ?? 'Failed to remove item from basket');
        _logger.e('Failed to remove item: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error removing item from basket: $e');
      state = state.failure('Failed to remove item from basket: ${e.toString()}');
      return false;
    }
  }

  /// Remove course from basket (convenience method)
  Future<bool> removeCourse(String courseId, {bool isTaster = false}) async {
    return removeItem(courseId, isTaster ? 'taster' : 'course');
  }

  /// Clear/destroy the current basket
  Future<bool> clearBasket() async {
    try {
      _logger.d('Clearing basket');

      final success = await _basketRepository.destroyBasket();

      if (success) {
        // Create a new empty basket after destroying
        final newBasket = await _basketRepository.initBasket();
        state = state.success(newBasket);
        _logger.d('Basket cleared successfully');
        return true;
      } else {
        state = state.failure('Failed to clear basket');
        _logger.e('Failed to clear basket');
        return false;
      }
    } catch (e) {
      _logger.e('Error clearing basket: $e');
      state = state.failure('Failed to clear basket: ${e.toString()}');
      return false;
    }
  }

  /// Toggle credit usage for the basket
  Future<bool> toggleCreditUsage(bool useCredit) async {
    try {
      _logger.d('Toggling credit usage: $useCredit');

      final result = await _basketRepository.useCreditForBasket(useCredit);

      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Credit usage updated successfully');
        return true;
      } else {
        state = state.failure(result.message ?? 'Failed to update credit usage');
        _logger.e('Failed to update credit usage: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error updating credit usage: $e');
      state = state.failure('Failed to update credit usage: ${e.toString()}');
      return false;
    }
  }

  /// Apply promo code to basket
  Future<bool> applyPromoCode(String code) async {
    try {
      _logger.d('Applying promo code: $code');

      final result = await _basketRepository.applyPromoCode(code);

      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Promo code applied successfully');
        return true;
      } else {
        state = state.failure(result.message ?? 'Failed to apply promo code');
        _logger.e('Failed to apply promo code: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error applying promo code: $e');
      state = state.failure('Failed to apply promo code: ${e.toString()}');
      return false;
    }
  }

  /// Remove promo codes from basket
  Future<bool> removePromoCode() async {
    try {
      _logger.d('Removing promo codes');

      final result = await _basketRepository.removePromoCode();

      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Promo codes removed successfully');
        return true;
      } else {
        state = state.failure(result.message ?? 'Failed to remove promo codes');
        _logger.e('Failed to remove promo codes: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error removing promo codes: $e');
      state = state.failure('Failed to remove promo codes: ${e.toString()}');
      return false;
    }
  }

  /// Check if an item is in the basket
  Future<bool> isItemInBasket(String itemId, String itemType) async {
    try {
      return await _basketRepository.isItemInBasket(itemId, itemType);
    } catch (e) {
      _logger.w('Error checking if item is in basket: $e');
      return false;
    }
  }

  /// Check if a course is in the basket (convenience method)
  bool isCourseInBasket(String courseId) {
    final basket = state.basket;
    if (basket == null) return false;
    
    return basket.items.any((item) => item.course.id == courseId);
  }

  /// Get basket item for a specific course
  BasketItem? getBasketItemForCourse(String courseId) {
    final basket = state.basket;
    if (basket == null) return null;
    
    try {
      return basket.items.firstWhere((item) => item.course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  /// Clear any error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for basket state notifier
final basketNotifierProvider = StateNotifierProvider<BasketNotifier, BasketState>((ref) {
  final basketRepository = ref.watch(basketRepositoryProvider);
  return BasketNotifier(basketRepository);
});

/// Convenience provider for current basket
final currentBasketProvider = Provider<Basket?>((ref) {
  final basketState = ref.watch(basketNotifierProvider);
  return basketState.basket;
});

/// Convenience provider for basket loading state
final basketLoadingProvider = Provider<bool>((ref) {
  final basketState = ref.watch(basketNotifierProvider);
  return basketState.isLoading;
});

/// Convenience provider for basket error state
final basketErrorProvider = Provider<String?>((ref) {
  final basketState = ref.watch(basketNotifierProvider);
  return basketState.error;
});

/// Convenience provider for basket item count
final basketItemCountProvider = Provider<int>((ref) {
  final basket = ref.watch(currentBasketProvider);
  return basket?.itemCount ?? 0;
});

/// Convenience provider for checking if basket is empty
final basketIsEmptyProvider = Provider<bool>((ref) {
  final basket = ref.watch(currentBasketProvider);
  return basket?.isEmpty ?? true;
});

/// Convenience provider for basket total
final basketTotalProvider = Provider<int>((ref) {
  final basket = ref.watch(currentBasketProvider);
  return basket?.total ?? 0;
});

/// Convenience provider for basket charge total (amount to pay now)
final basketChargeTotalProvider = Provider<int>((ref) {
  final basket = ref.watch(currentBasketProvider);
  return basket?.chargeTotal ?? 0;
});

/// Convenience provider for basket pay later amount
final basketPayLaterProvider = Provider<int>((ref) {
  final basket = ref.watch(currentBasketProvider);
  return basket?.payLater ?? 0;
});

/// Provider for checking if a specific course is in basket
final courseInBasketProvider = Provider.family<bool, String>((ref, courseId) {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.isCourseInBasket(courseId);
});

/// Parameters for basket item operations
class BasketItemParams {
  final String itemId;
  final String itemType;
  final bool? payDeposit;
  final String? assignToUserId;
  final DateTime? chargeFromDate;

  const BasketItemParams({
    required this.itemId,
    this.itemType = 'course',
    this.payDeposit,
    this.assignToUserId,
    this.chargeFromDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BasketItemParams &&
        other.itemId == itemId &&
        other.itemType == itemType &&
        other.payDeposit == payDeposit &&
        other.assignToUserId == assignToUserId &&
        other.chargeFromDate == chargeFromDate;
  }

  @override
  int get hashCode => Object.hash(itemId, itemType, payDeposit, assignToUserId, chargeFromDate);
}

/// Parameters for course basket operations (backwards compatibility)
class CourseBasketParams {
  final String courseId;
  final bool isTaster;
  final String? sessionId;
  final bool? payDeposit;

  const CourseBasketParams({
    required this.courseId,
    this.isTaster = false,
    this.sessionId,
    this.payDeposit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseBasketParams &&
        other.courseId == courseId &&
        other.isTaster == isTaster &&
        other.sessionId == sessionId &&
        other.payDeposit == payDeposit;
  }

  @override
  int get hashCode => Object.hash(courseId, isTaster, sessionId, payDeposit);
}

/// Provider for adding item to basket
final addItemToBasketProvider = FutureProvider.family<bool, BasketItemParams>((ref, params) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.addItem(
    params.itemId,
    itemType: params.itemType,
    payDeposit: params.payDeposit,
    assignToUserId: params.assignToUserId,
    chargeFromDate: params.chargeFromDate,
  );
});

/// Provider for adding course to basket (backwards compatibility)
final addCourseToBasketProvider = FutureProvider.family<bool, CourseBasketParams>((ref, params) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.addCourse(
    params.courseId,
    isTaster: params.isTaster,
    payDeposit: params.payDeposit,
  );
});

/// Provider for removing item from basket
final removeItemFromBasketProvider = FutureProvider.family<bool, BasketItemParams>((ref, params) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.removeItem(params.itemId, params.itemType);
});

/// Provider for removing course from basket (backwards compatibility)
final removeCourseFromBasketProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.removeCourse(courseId);
});

/// Provider for applying promo code
final applyPromoCodeProvider = FutureProvider.family<bool, String>((ref, code) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.applyPromoCode(code);
});

/// Provider for toggling credit usage
final toggleCreditUsageProvider = FutureProvider.family<bool, bool>((ref, useCredit) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.toggleCreditUsage(useCredit);
});