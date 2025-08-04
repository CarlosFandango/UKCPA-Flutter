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
class BasketNotifier extends StateNotifier<BasketState> {
  final BasketRepository _basketRepository;

  BasketNotifier(this._basketRepository) : super(const BasketState()) {
    // Initialize by fetching current basket
    _initializeBasket();
  }

  /// Initialize basket by fetching current or creating anonymous basket
  Future<void> _initializeBasket() async {
    try {
      state = state.loading();
      _logger.d('Initializing basket');

      // Try to get existing basket first
      final existingBasket = await _basketRepository.getCurrentBasket();
      
      if (existingBasket != null) {
        _logger.d('Found existing basket with ${existingBasket.itemCount} items');
        state = state.success(existingBasket);
      } else {
        _logger.d('No existing basket found, creating anonymous basket');
        final newBasket = await _basketRepository.createAnonymousBasket();
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

      final result = await _basketRepository.refreshBasket();
      
      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Basket refreshed successfully');
      } else {
        state = state.failure(result.message ?? 'Failed to refresh basket');
        _logger.e('Failed to refresh basket: ${result.message}');
      }
    } catch (e) {
      _logger.e('Error refreshing basket: $e');
      state = state.failure('Failed to refresh basket: ${e.toString()}');
    }
  }

  /// Add course to basket
  Future<bool> addCourse(
    String courseId, {
    bool isTaster = false,
    String? sessionId,
  }) async {
    try {
      _logger.d('Adding course to basket: $courseId, isTaster: $isTaster');

      final result = await _basketRepository.addCourse(
        courseId,
        isTaster: isTaster,
        sessionId: sessionId,
      );

      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Course added to basket successfully');
        return true;
      } else {
        state = state.failure(result.message ?? 'Failed to add course');
        _logger.e('Failed to add course: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error adding course to basket: $e');
      state = state.failure('Failed to add course: ${e.toString()}');
      return false;
    }
  }

  /// Remove course from basket
  Future<bool> removeCourse(String courseId) async {
    try {
      _logger.d('Removing course from basket: $courseId');

      final result = await _basketRepository.removeCourse(courseId);

      if (result.success) {
        state = state.success(result.basket);
        _logger.d('Course removed from basket successfully');
        return true;
      } else {
        state = state.failure(result.message ?? 'Failed to remove course');
        _logger.e('Failed to remove course: ${result.message}');
        return false;
      }
    } catch (e) {
      _logger.e('Error removing course from basket: $e');
      state = state.failure('Failed to remove course: ${e.toString()}');
      return false;
    }
  }

  /// Check if a course is in the basket
  bool isCourseInBasket(String courseId) {
    final basket = state.basket;
    if (basket == null) return false;
    
    return basket.containsCourse(courseId);
  }

  /// Get basket item for a specific course
  BasketItem? getBasketItemForCourse(String courseId) {
    final basket = state.basket;
    if (basket == null) return null;
    
    return basket.getItemForCourse(courseId);
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
  return basket?.finalTotal ?? 0;
});

/// Provider for checking if a specific course is in basket
final courseInBasketProvider = Provider.family<bool, String>((ref, courseId) {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.isCourseInBasket(courseId);
});

/// Parameters for course basket operations
class CourseBasketParams {
  final String courseId;
  final bool isTaster;
  final String? sessionId;

  const CourseBasketParams({
    required this.courseId,
    this.isTaster = false,
    this.sessionId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseBasketParams &&
        other.courseId == courseId &&
        other.isTaster == isTaster &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode => Object.hash(courseId, isTaster, sessionId);
}

/// Provider for adding course to basket
final addCourseToBasketProvider = FutureProvider.family<bool, CourseBasketParams>((ref, params) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.addCourse(
    params.courseId,
    isTaster: params.isTaster,
    sessionId: params.sessionId,
  );
});

/// Provider for removing course from basket
final removeCourseFromBasketProvider = FutureProvider.family<bool, String>((ref, courseId) async {
  final basketNotifier = ref.watch(basketNotifierProvider.notifier);
  return basketNotifier.removeCourse(courseId);
});