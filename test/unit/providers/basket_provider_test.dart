import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukcpa_flutter/presentation/providers/basket_provider.dart';
import 'package:ukcpa_flutter/domain/repositories/basket_repository.dart';
import 'package:ukcpa_flutter/domain/entities/basket.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';

// Use centralized mocks for consistency
import '../../../integration_test/mocks/mock_repositories.dart';
import '../../../integration_test/mocks/mock_data_factory.dart';

void main() {
  late MockBasketRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockRepositoryFactory.getBasketRepository();
    MockConfig.configureForSpeed(); // Fast tests
    container = ProviderContainer(
      overrides: [
        basketRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BasketState', () {
    test('should create empty state correctly', () {
      const state = BasketState();
      
      expect(state.basket, null);
      expect(state.isLoading, false);
      expect(state.error, null);
      expect(state.hasError, false);
    });

    test('should create loading state correctly', () {
      const state = BasketState();
      final loadingState = state.loading();
      
      expect(loadingState.isLoading, true);
      expect(loadingState.error, null);
      expect(loadingState.hasError, false);
    });

    test('should create success state correctly', () {
      const state = BasketState();
      final basket = Basket(id: 'test-basket');
      final successState = state.success(basket);
      
      expect(successState.basket, basket);
      expect(successState.isLoading, false);
      expect(successState.error, null);
      expect(successState.hasError, false);
    });

    test('should create failure state correctly', () {
      const state = BasketState();
      final failureState = state.failure('Test error');
      
      expect(failureState.basket, null);
      expect(failureState.isLoading, false);
      expect(failureState.error, 'Test error');
      expect(failureState.hasError, true);
    });

    test('copyWith should update only specified fields', () {
      final basket = Basket(id: 'test-basket');
      const initialState = BasketState(isLoading: true);
      
      final updatedState = initialState.copyWith(
        basket: basket,
        error: 'Test error',
      );
      
      expect(updatedState.basket, basket);
      expect(updatedState.isLoading, true); // Unchanged
      expect(updatedState.error, 'Test error');
    });

    test('toString should format correctly', () {
      final basket = Basket(id: 'test-basket');
      final state = BasketState(basket: basket, isLoading: true, error: 'Test error');
      
      expect(state.toString(), contains('test-basket'));
      expect(state.toString(), contains('true')); // isLoading
      expect(state.toString(), contains('Test error'));
    });
  });

  group('BasketNotifier', () {
    group('initialization', () {
      test('should initialize with existing basket', () async {
        // Arrange
        final existingBasket = Basket(
          id: 'existing-basket',
          items: [],
          total: 0,
        );
        when(mockRepository.getBasket()).thenAnswer((_) async => existingBasket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.id, 'existing-basket');
        expect(state.isLoading, false);
        expect(state.hasError, false);
        verify(mockRepository.getBasket()).called(1);
      });

      test('should create new basket when none exists', () async {
        // Arrange
        final newBasket = Basket(id: 'new-basket', total: 0);
        when(mockRepository.getBasket()).thenAnswer((_) async => null);
        when(mockRepository.initBasket()).thenAnswer((_) async => newBasket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.id, 'new-basket');
        expect(state.isLoading, false);
        expect(state.hasError, false);
        verify(mockRepository.getBasket()).called(1);
        verify(mockRepository.initBasket()).called(1);
      });

      test('should handle initialization error', () async {
        // Arrange
        when(mockRepository.getBasket()).thenThrow(const BasketException('Network error'));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final state = container.read(basketNotifierProvider);
        expect(state.basket, null);
        expect(state.hasError, true);
        expect(state.error, contains('Network error'));
      });
    });

    group('refreshBasket', () {
      test('should refresh basket successfully', () async {
        // Arrange
        final refreshedBasket = Basket(id: 'refreshed-basket', total: 5000);
        when(mockRepository.getBasket())
            .thenAnswer((_) async => Basket(id: 'initial', total: 0));
        when(mockRepository.getBasket())
            .thenAnswer((_) async => refreshedBasket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        await notifier.refreshBasket();

        // Assert
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.id, 'refreshed-basket');
        expect(state.basket?.total, 5000);
        expect(state.hasError, false);
        verify(mockRepository.getBasket()).called(2);
      });

      test('should create new basket if refresh returns null', () async {
        // Arrange
        final newBasket = Basket(id: 'new-basket', total: 0);
        when(mockRepository.getBasket())
            .thenAnswer((_) async => Basket(id: 'initial', total: 0));
        when(mockRepository.getBasket())
            .thenAnswer((_) async => null);
        when(mockRepository.initBasket()).thenAnswer((_) async => newBasket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        await notifier.refreshBasket();

        // Assert
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.id, 'new-basket');
        verify(mockRepository.initBasket()).called(1);
      });
    });

    group('addItem', () {
      test('should add item successfully', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', items: [], total: 0);
        final mockCourse = Course(
          id: '1',
          name: 'Test Course',
          shortDescription: 'A test course',
          type: 'StudioCourse',
          price: 5000,
          displayStatus: DisplayStatus.live,
        );
        final basketItem = BasketItem(
          id: 'item-1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        );
        final updatedBasket = Basket(
          id: 'basket',
          items: [basketItem],
          total: 5000,
        );

        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.addItem('course-1', itemType: 'course'))
            .thenAnswer((_) async => BasketOperationResult(
              success: true,
              basket: updatedBasket,
              message: 'Item added',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.addItem('course-1', itemType: 'course');

        // Assert
        expect(result, true);
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.items.length, 1);
        expect(state.basket?.total, 5000);
        expect(state.hasError, false);
      });

      test('should handle add item failure', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', items: [], total: 0);
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.addItem('course-1', itemType: 'course'))
            .thenAnswer((_) async => BasketOperationResult(
              success: false,
              basket: initialBasket,
              message: 'Course is full',
              errorCode: 'COURSE_FULL',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.addItem('course-1', itemType: 'course');

        // Assert
        expect(result, false);
        final state = container.read(basketNotifierProvider);
        expect(state.hasError, true);
        expect(state.error, contains('Course is full'));
      });

      test('should handle add item with all parameters', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', items: [], total: 0);
        final updatedBasket = Basket(id: 'basket', total: 2500, payLater: 2500);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.addItem(
          'course-1',
          itemType: 'taster',
          payDeposit: true,
          assignToUserId: 'user-123',
          chargeFromDate: DateTime(2024, 6, 1),
        )).thenAnswer((_) async => BasketOperationResult(
          success: true,
          basket: updatedBasket,
          message: 'Taster added with deposit',
        ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.addItem(
          'course-1',
          itemType: 'taster',
          payDeposit: true,
          assignToUserId: 'user-123',
          chargeFromDate: DateTime(2024, 6, 1),
        );

        // Assert
        expect(result, true);
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.payLater, 2500);
      });
    });

    group('addCourse', () {
      test('should add regular course successfully', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', items: [], total: 0);
        final updatedBasket = Basket(id: 'basket', total: 5000);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.addItem('course-1', itemType: 'course'))
            .thenAnswer((_) async => BasketOperationResult(
              success: true,
              basket: updatedBasket,
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.addCourse('course-1');

        // Assert
        expect(result, true);
        verify(mockRepository.addItem('course-1', itemType: 'course')).called(1);
      });

      test('should add taster course successfully', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', items: [], total: 0);
        final updatedBasket = Basket(id: 'basket', total: 3000);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.addItem('course-1', itemType: 'taster'))
            .thenAnswer((_) async => BasketOperationResult(
              success: true,
              basket: updatedBasket,
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.addCourse('course-1', isTaster: true);

        // Assert
        expect(result, true);
        verify(mockRepository.addItem('course-1', itemType: 'taster')).called(1);
      });
    });

    group('removeItem', () {
      test('should remove item successfully', () async {
        // Arrange
        final mockCourse = Course(
          id: '1',
          name: 'Test Course',
          shortDescription: 'A test course',
          type: 'StudioCourse',
          price: 5000,
          displayStatus: DisplayStatus.live,
        );
        final basketItem = BasketItem(
          id: 'item-1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        );
        final initialBasket = Basket(id: 'basket', items: [basketItem], total: 5000);
        final emptyBasket = Basket(id: 'basket', items: [], total: 0);

        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.removeItem('course-1', 'course'))
            .thenAnswer((_) async => BasketOperationResult(
              success: true,
              basket: emptyBasket,
              message: 'Item removed',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.removeItem('course-1', 'course');

        // Assert
        expect(result, true);
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.items.length, 0);
        expect(state.basket?.total, 0);
      });

      test('should handle remove item failure', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', items: [], total: 0);
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.removeItem('course-1', 'course'))
            .thenAnswer((_) async => BasketOperationResult(
              success: false,
              basket: initialBasket,
              message: 'Item not found',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.removeItem('course-1', 'course');

        // Assert
        expect(result, false);
        final state = container.read(basketNotifierProvider);
        expect(state.hasError, true);
        expect(state.error, contains('Item not found'));
      });
    });

    group('clearBasket', () {
      test('should clear basket successfully', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', total: 5000);
        final newBasket = Basket(id: 'new-basket', total: 0);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.destroyBasket()).thenAnswer((_) async => true);
        when(mockRepository.initBasket()).thenAnswer((_) async => newBasket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.clearBasket();

        // Assert
        expect(result, true);
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.id, 'new-basket');
        expect(state.basket?.total, 0);
        verify(mockRepository.destroyBasket()).called(1);
        verify(mockRepository.initBasket()).called(1);
      });

      test('should handle clear basket failure', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', total: 5000);
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.destroyBasket()).thenAnswer((_) async => false);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.clearBasket();

        // Assert
        expect(result, false);
        final state = container.read(basketNotifierProvider);
        expect(state.hasError, true);
        expect(state.error, contains('Failed to clear basket'));
      });
    });

    group('toggleCreditUsage', () {
      test('should enable credit usage successfully', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', total: 5000, creditTotal: 0);
        final updatedBasket = Basket(id: 'basket', total: 4500, creditTotal: 500);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.useCreditForBasket(true))
            .thenAnswer((_) async => BasketOperationResult(
              success: true,
              basket: updatedBasket,
              message: 'Credit applied',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.toggleCreditUsage(true);

        // Assert
        expect(result, true);
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.creditTotal, 500);
        expect(state.basket?.total, 4500);
      });

      test('should disable credit usage successfully', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', total: 4500, creditTotal: 500);
        final updatedBasket = Basket(id: 'basket', total: 5000, creditTotal: 0);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.useCreditForBasket(false))
            .thenAnswer((_) async => BasketOperationResult(
              success: true,
              basket: updatedBasket,
              message: 'Credit removed',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.toggleCreditUsage(false);

        // Assert
        expect(result, true);
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.creditTotal, 0);
        expect(state.basket?.total, 5000);
      });
    });

    group('applyPromoCode', () {
      test('should apply promo code successfully', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', total: 5000, promoCodeDiscountValue: 0);
        final updatedBasket = Basket(id: 'basket', total: 4750, promoCodeDiscountValue: 250);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.applyPromoCode('SAVE10'))
            .thenAnswer((_) async => BasketOperationResult(
              success: true,
              basket: updatedBasket,
              message: 'Promo code applied',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.applyPromoCode('SAVE10');

        // Assert
        expect(result, true);
        final state = container.read(basketNotifierProvider);
        expect(state.basket?.promoCodeDiscountValue, 250);
        expect(state.basket?.total, 4750);
      });

      test('should handle invalid promo code', () async {
        // Arrange
        final initialBasket = Basket(id: 'basket', total: 5000);
        when(mockRepository.getBasket()).thenAnswer((_) async => initialBasket);
        when(mockRepository.applyPromoCode('INVALID'))
            .thenAnswer((_) async => BasketOperationResult(
              success: false,
              basket: initialBasket,
              message: 'Invalid promo code',
              errorCode: 'INVALID_PROMO',
            ));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await notifier.applyPromoCode('INVALID');

        // Assert
        expect(result, false);
        final state = container.read(basketNotifierProvider);
        expect(state.hasError, true);
        expect(state.error, contains('Invalid promo code'));
      });
    });

    group('utility methods', () {
      test('isCourseInBasket should return true when course exists', () async {
        // Arrange
        final mockCourse = Course(
          id: 'course-1',
          name: 'Test Course',
          shortDescription: 'A test course',
          type: 'StudioCourse',
          price: 5000,
          displayStatus: DisplayStatus.live,
        );
        final basketItem = BasketItem(
          id: 'item-1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        );
        final basket = Basket(id: 'basket', items: [basketItem], total: 5000);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => basket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = notifier.isCourseInBasket('course-1');

        // Assert
        expect(result, true);
      });

      test('isCourseInBasket should return false when course does not exist', () async {
        // Arrange
        final basket = Basket(id: 'basket', items: [], total: 0);
        when(mockRepository.getBasket()).thenAnswer((_) async => basket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = notifier.isCourseInBasket('course-1');

        // Assert
        expect(result, false);
      });

      test('getBasketItemForCourse should return item when course exists', () async {
        // Arrange
        final mockCourse = Course(
          id: 'course-1',
          name: 'Test Course',
          shortDescription: 'A test course',
          type: 'StudioCourse',
          price: 5000,
          displayStatus: DisplayStatus.live,
        );
        final basketItem = BasketItem(
          id: 'item-1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        );
        final basket = Basket(id: 'basket', items: [basketItem], total: 5000);
        
        when(mockRepository.getBasket()).thenAnswer((_) async => basket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = notifier.getBasketItemForCourse('course-1');

        // Assert
        expect(result, isNotNull);
        expect(result?.course.id, 'course-1');
      });

      test('getBasketItemForCourse should return null when course does not exist', () async {
        // Arrange
        final basket = Basket(id: 'basket', items: [], total: 0);
        when(mockRepository.getBasket()).thenAnswer((_) async => basket);

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        final result = notifier.getBasketItemForCourse('course-1');

        // Assert
        expect(result, null);
      });

      test('clearError should clear error state', () async {
        // Arrange
        final basket = Basket(id: 'basket', items: [], total: 0);
        when(mockRepository.getBasket()).thenThrow(const BasketException('Test error'));

        // Act
        final notifier = container.read(basketNotifierProvider.notifier);
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify error state
        expect(container.read(basketNotifierProvider).hasError, true);
        
        // Clear error
        notifier.clearError();

        // Assert
        expect(container.read(basketNotifierProvider).hasError, false);
        expect(container.read(basketNotifierProvider).error, null);
      });
    });
  });

  group('Convenience Providers', () {
    test('currentBasketProvider should return current basket', () async {
      // Arrange
      final basket = Basket(id: 'test-basket', total: 5000);
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      // Act
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final currentBasket = container.read(currentBasketProvider);

      // Assert
      expect(currentBasket?.id, 'test-basket');
      expect(currentBasket?.total, 5000);
    });

    test('basketItemCountProvider should return item count', () async {
      // Arrange
      final mockCourse = Course(
        id: '1',
        name: 'Test Course',
        shortDescription: 'A test course',
        type: 'StudioCourse',
        price: 5000,
        displayStatus: DisplayStatus.live,
      );
      final basketItem = BasketItem(
        id: 'item-1',
        course: mockCourse,
        price: 5000,
        totalPrice: 5000,
      );
      final basket = Basket(id: 'basket', items: [basketItem, basketItem], total: 10000);
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      // Act
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final itemCount = container.read(basketItemCountProvider);

      // Assert
      expect(itemCount, 2);
    });

    test('basketIsEmptyProvider should return true for empty basket', () async {
      // Arrange
      final basket = Basket(id: 'basket', items: [], total: 0);
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      // Act
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final isEmpty = container.read(basketIsEmptyProvider);

      // Assert
      expect(isEmpty, true);
    });

    test('basketTotalProvider should return total amount', () async {
      // Arrange
      final basket = Basket(id: 'basket', total: 7500);
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      // Act
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final total = container.read(basketTotalProvider);

      // Assert
      expect(total, 7500);
    });

    test('basketChargeTotalProvider should return charge total', () async {
      // Arrange
      final basket = Basket(id: 'basket', total: 7500, chargeTotal: 5000);
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      // Act
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final chargeTotal = container.read(basketChargeTotalProvider);

      // Assert
      expect(chargeTotal, 5000);
    });

    test('basketPayLaterProvider should return pay later amount', () async {
      // Arrange
      final basket = Basket(id: 'basket', total: 7500, payLater: 2500);
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      // Act
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final payLater = container.read(basketPayLaterProvider);

      // Assert
      expect(payLater, 2500);
    });

    test('courseInBasketProvider should return true when course in basket', () async {
      // Arrange
      final mockCourse = Course(
        id: 'course-1',
        name: 'Test Course',
        shortDescription: 'A test course',
        type: 'StudioCourse',
        price: 5000,
        displayStatus: DisplayStatus.live,
      );
      final basketItem = BasketItem(
        id: 'item-1',
        course: mockCourse,
        price: 5000,
        totalPrice: 5000,
      );
      final basket = Basket(id: 'basket', items: [basketItem], total: 5000);
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      // Act
      // Wait for initialization to complete
      await Future.delayed(const Duration(milliseconds: 100));
      final isInBasket = container.read(courseInBasketProvider('course-1'));

      // Assert
      expect(isInBasket, true);
    });
  });

  group('BasketItemParams and CourseBasketParams', () {
    test('BasketItemParams equality should work correctly', () {
      const params1 = BasketItemParams(
        itemId: 'course-1',
        itemType: 'course',
        payDeposit: true,
      );
      const params2 = BasketItemParams(
        itemId: 'course-1',
        itemType: 'course',
        payDeposit: true,
      );
      const params3 = BasketItemParams(
        itemId: 'course-2',
        itemType: 'course',
        payDeposit: true,
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
      expect(params1.hashCode, equals(params2.hashCode));
    });

    test('CourseBasketParams equality should work correctly', () {
      const params1 = CourseBasketParams(
        courseId: 'course-1',
        isTaster: true,
        payDeposit: false,
      );
      const params2 = CourseBasketParams(
        courseId: 'course-1',
        isTaster: true,
        payDeposit: false,
      );
      const params3 = CourseBasketParams(
        courseId: 'course-1',
        isTaster: false,
        payDeposit: false,
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
      expect(params1.hashCode, equals(params2.hashCode));
    });
  });
}