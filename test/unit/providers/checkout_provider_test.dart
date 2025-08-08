import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukcpa_flutter/presentation/providers/checkout_provider.dart';
import 'package:ukcpa_flutter/domain/repositories/checkout_repository.dart';
import 'package:ukcpa_flutter/domain/entities/checkout.dart';
import 'package:ukcpa_flutter/domain/entities/basket.dart';
import 'package:ukcpa_flutter/services/stripe_payment_service.dart';
import 'package:ukcpa_flutter/core/errors/payment_exception.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

// Use centralized mocks for consistency
import '../../../integration_test/mocks/mock_repositories.dart';
import '../../../integration_test/mocks/mock_data_factory.dart';

void main() {
  late MockCheckoutRepository mockCheckoutRepository;
  late MockStripePaymentService mockStripeService;
  late ProviderContainer container;

  setUp(() {
    mockCheckoutRepository = MockRepositoryFactory.getCheckoutRepository();
    mockStripeService = MockRepositoryFactory.getStripePaymentService();
    MockConfig.configureForSpeed(); // Fast tests
    
    container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
        stripePaymentServiceProvider.overrideWithValue(mockStripeService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    MockConfig.resetToDefaults();
  });

  group('CheckoutState', () {
    test('should create initial state correctly', () {
      const state = CheckoutInitial();
      expect(state, isA<CheckoutInitial>());
    });

    test('should create loading state correctly', () {
      const state = CheckoutLoading();
      expect(state, isA<CheckoutLoading>());
    });

    test('should create loaded state correctly', () {
      final session = CheckoutSession(
        basket: MockDataFactory.basketWithItems,
        availablePaymentMethods: MockDataFactory.createPaymentMethods(),
        currentStep: 1,
      );
      final state = CheckoutLoaded(session);
      
      expect(state, isA<CheckoutLoaded>());
      expect(state.session, session);
    });

    test('should create error state correctly', () {
      const state = CheckoutError('Test error', errorCode: 'TEST_ERROR');
      
      expect(state, isA<CheckoutError>());
      expect(state.message, 'Test error');
      expect(state.errorCode, 'TEST_ERROR');
    });

    test('should create processing state correctly', () {
      const state = CheckoutProcessing('Processing...');
      
      expect(state, isA<CheckoutProcessing>());
      expect(state.message, 'Processing...');
    });

    test('should create success state correctly', () {
      final order = MockDataFactory.createOrder();
      final state = CheckoutSuccess(order);
      
      expect(state, isA<CheckoutSuccess>());
      expect(state.order, order);
    });
  });

  group('CheckoutNotifier', () {
    group('initializeCheckout', () {
      test('should initialize checkout successfully', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);

        // Act
        await notifier.initializeCheckout(basket);

        // Assert
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutLoaded>());
        
        final loadedState = state as CheckoutLoaded;
        expect(loadedState.session.basket, basket);
        expect(loadedState.session.availablePaymentMethods.length, 2);
        expect(loadedState.session.currentStep, 1);
        
        // Verify Stripe was initialized
        verify(mockStripeService.initialize()).called(1);
      });

      test('should handle empty basket error', () async {
        // Arrange
        final emptyBasket = MockDataFactory.emptyBasket;
        final notifier = container.read(checkoutNotifierProvider.notifier);

        // Act
        await notifier.initializeCheckout(emptyBasket);

        // Assert
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutError>());
        expect((state as CheckoutError).message, 'Basket is empty');
      });

      test('should handle initialization error', () async {
        // Arrange
        MockConfig.simulateStripeInitError = true;
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);

        // Act
        await notifier.initializeCheckout(basket);

        // Assert
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutError>());
        expect((state as CheckoutError).message, contains('Failed to initialize'));
      });
    });

    group('step navigation', () {
      test('should move to next step', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);

        // Act
        notifier.nextStep();

        // Assert
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.currentStep, 2);
      });

      test('should move to previous step', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        notifier.nextStep(); // Go to step 2

        // Act
        notifier.previousStep();

        // Assert
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.currentStep, 1);
      });

      test('should clamp step values', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);

        // Act - Try to go below step 1
        notifier.previousStep();

        // Assert
        final state1 = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state1.session.currentStep, 1);

        // Act - Try to go above step 4
        for (int i = 0; i < 10; i++) {
          notifier.nextStep();
        }

        // Assert
        final state2 = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state2.session.currentStep, 4);
      });
    });

    group('payment methods', () {
      test('should select payment method', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        final newPaymentMethod = MockDataFactory.createPaymentMethod(id: 'pm_new');

        // Act
        notifier.selectPaymentMethod(newPaymentMethod);

        // Assert
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.selectedPaymentMethod, newPaymentMethod);
      });

      test('should create payment method from card successfully', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        final cardDetails = {
          'complete': true,
          'validNumber': true,
          'validCVC': true,
          'validExpiryDate': true,
          'last4': '4242',
          'brand': 'visa',
        };
        
        const email = 'test@example.com';
        const name = 'Test User';
        const billingAddress = BillingAddress(
          line1: '123 Test Street',
          city: 'London',
          county: 'Greater London',
          postcode: 'SW1A 1AA',
          countryCode: 'GB',
        );

        // Act
        final result = await notifier.createPaymentMethodFromCard(
          cardDetails: cardDetails,
          email: email,
          name: name,
          billingAddress: billingAddress,
          setAsDefault: true,
        );

        // Assert
        expect(result, true);
        
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.availablePaymentMethods.length, 3); // 2 original + 1 new
        
        // Verify Stripe service was called
        verify(mockStripeService.createPaymentMethod(
          cardDetails: cardDetails,
          billingDetails: any,
        )).called(1);
      });

      test('should handle card error when creating payment method', () async {
        // Arrange
        MockConfig.simulateCardError = true;
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        final cardDetails = {
          'complete': false,
          'validNumber': false,
          'validCVC': false,
          'validExpiryDate': false,
        };

        // Act
        final result = await notifier.createPaymentMethodFromCard(
          cardDetails: cardDetails,
          email: 'test@example.com',
          name: 'Test User',
          billingAddress: const BillingAddress(
            line1: '123 Test Street',
            city: 'London',
            county: 'Greater London',
            postcode: 'SW1A 1AA',
            countryCode: 'GB',
          ),
        );

        // Assert
        expect(result, false);
        
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutError>());
      });
    });

    group('billing address', () {
      test('should update billing address', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        final newAddress = MockDataFactory.createAddress(name: 'New Address');

        // Act
        notifier.updateBillingAddress(newAddress);

        // Assert
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.billingAddress, newAddress);
      });
    });

    group('payment processing', () {
      test('should process payment successfully', () async {
        // Arrange
        MockConfig.resetToDefaults(); // Ensure no errors are simulated
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);

        // Act
        final result = await notifier.processPayment(
          paymentMethodId: 'pm_test123',
          paymentMethodType: 'card',
        );

        // Assert
        expect(result, true);
        
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutSuccess>());
        
        final successState = state as CheckoutSuccess;
        expect(successState.order.id, 'order_test123');
      });

      test('should handle payment requiring 3DS', () async {
        // Arrange
        MockConfig.simulateRequires3DS = true;
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);

        // Act
        final result = await notifier.processPayment(
          paymentMethodId: 'pm_test123',
          paymentMethodType: 'card',
        );

        // Assert
        expect(result, true); // Returns true to indicate 3DS is needed
        
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.clientSecret, 'pi_test_client_secret');
        expect(state.session.currentStep, 3);
        expect(state.session.isProcessing, true);
      });

      test('should handle payment failure', () async {
        // Arrange
        MockConfig.simulatePaymentFailure = true;
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);

        // Act
        final result = await notifier.processPayment(
          paymentMethodId: 'pm_test123',
          paymentMethodType: 'card',
        );

        // Assert
        expect(result, false);
        
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutError>());
        
        final errorState = state as CheckoutError;
        expect(errorState.errorCode, 'CARD_DECLINED');
      });

      test('should handle empty basket during payment', () async {
        // Arrange
        final emptyBasket = MockDataFactory.emptyBasket;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        
        // Manually set a loaded state with empty basket
        final session = CheckoutSession(
          basket: emptyBasket,
          availablePaymentMethods: [],
          currentStep: 1,
        );
        container.read(checkoutNotifierProvider.notifier).state = CheckoutLoaded(session);

        // Act
        final result = await notifier.processPayment(
          paymentMethodId: 'pm_test123',
          paymentMethodType: 'card',
        );

        // Assert
        expect(result, false);
        
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutError>());
        expect((state as CheckoutError).message, 'Basket is empty');
      });
    });

    group('3DS authentication', () {
      test('should handle 3DS authentication successfully', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        // Set up state for 3DS authentication
        final session = CheckoutSession(
          basket: basket,
          availablePaymentMethods: MockDataFactory.createPaymentMethods(),
          clientSecret: 'pi_test_client_secret',
          currentStep: 3,
          isProcessing: true,
        );
        notifier.state = CheckoutLoaded(session);

        // Act
        final result = await notifier.handle3DSAuthentication('pi_test_client_secret');

        // Assert
        expect(result, true);
        
        // Verify Stripe service was called
        verify(mockStripeService.handle3DSAuthentication(
          clientSecret: 'pi_test_client_secret',
        )).called(1);
      });

      test('should handle 3DS authentication failure', () async {
        // Arrange
        MockConfig.simulate3DSFailure = true;
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        // Set up state for 3DS authentication
        final session = CheckoutSession(
          basket: basket,
          availablePaymentMethods: MockDataFactory.createPaymentMethods(),
          clientSecret: 'pi_test_client_secret',
          currentStep: 3,
          isProcessing: true,
        );
        notifier.state = CheckoutLoaded(session);

        // Act
        final result = await notifier.handle3DSAuthentication('pi_test_client_secret');

        // Assert
        expect(result, false);
        
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutError>());
      });

      test('should handle 3DS authentication cancellation', () async {
        // Arrange
        MockConfig.simulate3DSCancellation = true;
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        // Set up state for 3DS authentication
        final session = CheckoutSession(
          basket: basket,
          availablePaymentMethods: MockDataFactory.createPaymentMethods(),
          clientSecret: 'pi_test_client_secret',
          currentStep: 3,
          isProcessing: true,
        );
        notifier.state = CheckoutLoaded(session);

        // Act
        final result = await notifier.handle3DSAuthentication('pi_test_client_secret');

        // Assert
        expect(result, false);
        
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.clientSecret, null);
        expect(state.session.isProcessing, false);
      });

      test('should handle invalid authentication state', () async {
        // Arrange
        final notifier = container.read(checkoutNotifierProvider.notifier);

        // Act
        final result = await notifier.handle3DSAuthentication('invalid_secret');

        // Assert
        expect(result, false);
        
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutError>());
        expect((state as CheckoutError).message, 'Invalid authentication state');
      });
    });

    group('refresh payment methods', () {
      test('should refresh payment methods successfully', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);

        // Act
        await notifier.refreshPaymentMethods();

        // Assert
        final state = container.read(checkoutNotifierProvider) as CheckoutLoaded;
        expect(state.session.availablePaymentMethods.length, 2);
        
        // Verify repository was called
        verify(mockCheckoutRepository.getPaymentMethods()).called(2); // Once in init, once in refresh
      });

      test('should handle refresh error gracefully', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);
        
        // Set up error for refresh
        MockConfig.simulateNetworkErrors = true;

        // Act
        await notifier.refreshPaymentMethods();

        // Assert - State should remain loaded (errors don't change state during refresh)
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutLoaded>());
      });
    });

    group('reset', () {
      test('should reset checkout state', () async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        final notifier = container.read(checkoutNotifierProvider.notifier);
        await notifier.initializeCheckout(basket);

        // Act
        notifier.reset();

        // Assert
        final state = container.read(checkoutNotifierProvider);
        expect(state, isA<CheckoutInitial>());
      });
    });
  });

  group('Convenience Providers', () {
    test('should provide current checkout session', () async {
      // Arrange
      final basket = MockDataFactory.basketWithItems;
      final notifier = container.read(checkoutNotifierProvider.notifier);
      await notifier.initializeCheckout(basket);

      // Act & Assert
      final session = container.read(currentCheckoutSessionProvider);
      expect(session, isNotNull);
      expect(session!.basket, basket);
    });

    test('should provide loading state', () async {
      // Arrange
      container.read(checkoutNotifierProvider.notifier).state = const CheckoutLoading();

      // Act & Assert
      final isLoading = container.read(checkoutLoadingProvider);
      expect(isLoading, true);
    });

    test('should provide error message', () async {
      // Arrange
      container.read(checkoutNotifierProvider.notifier).state = 
          const CheckoutError('Test error');

      // Act & Assert
      final errorMessage = container.read(checkoutErrorProvider);
      expect(errorMessage, 'Test error');
    });

    test('should provide success order', () async {
      // Arrange
      final order = MockDataFactory.createOrder();
      container.read(checkoutNotifierProvider.notifier).state = CheckoutSuccess(order);

      // Act & Assert
      final successOrder = container.read(checkoutSuccessOrderProvider);
      expect(successOrder, order);
    });

    test('should provide available payment methods', () async {
      // Arrange
      final basket = MockDataFactory.basketWithItems;
      final notifier = container.read(checkoutNotifierProvider.notifier);
      await notifier.initializeCheckout(basket);

      // Act & Assert
      final paymentMethods = container.read(availablePaymentMethodsProvider);
      expect(paymentMethods.length, 2);
    });

    test('should provide selected payment method', () async {
      // Arrange
      final basket = MockDataFactory.basketWithItems;
      final notifier = container.read(checkoutNotifierProvider.notifier);
      await notifier.initializeCheckout(basket);

      // Act & Assert
      final selectedMethod = container.read(selectedPaymentMethodProvider);
      expect(selectedMethod, isNotNull);
      expect(selectedMethod!.isDefault, true);
    });

    test('should provide current checkout step', () async {
      // Arrange
      final basket = MockDataFactory.basketWithItems;
      final notifier = container.read(checkoutNotifierProvider.notifier);
      await notifier.initializeCheckout(basket);

      // Act & Assert
      final currentStep = container.read(currentCheckoutStepProvider);
      expect(currentStep, 1);
    });

    test('should provide can proceed to payment', () async {
      // Arrange
      final basket = MockDataFactory.basketWithItems;
      final notifier = container.read(checkoutNotifierProvider.notifier);
      await notifier.initializeCheckout(basket);

      // Act & Assert
      final canProceed = container.read(canProceedToPaymentProvider);
      expect(canProceed, true); // Based on mock session data
    });

    test('should provide requires payment', () async {
      // Arrange
      final basket = MockDataFactory.basketWithItems;
      final notifier = container.read(checkoutNotifierProvider.notifier);
      await notifier.initializeCheckout(basket);

      // Act & Assert
      final requiresPayment = container.read(requiresPaymentProvider);
      expect(requiresPayment, true); // Based on mock session data
    });
  });

  group('Async Providers', () {
    test('should provide Stripe publishable key', () async {
      // Act
      final keyAsync = container.read(stripePublishableKeyProvider);

      // Assert
      expect(keyAsync, isA<AsyncValue<String>>());
      
      await keyAsync.when(
        data: (key) {
          expect(key, 'pk_test_123456789012345678901234');
        },
        loading: () => fail('Should not be loading'),
        error: (error, stack) => fail('Should not have error: $error'),
      );
    });

    test('should provide order history', () async {
      // Act
      final historyAsync = container.read(orderHistoryProvider(
        (limit: 10, offset: 0)
      ));

      // Assert
      expect(historyAsync, isA<AsyncValue<List<Order>>>());
      
      await historyAsync.when(
        data: (orders) {
          expect(orders.length, 10);
          expect(orders.first.id, 'order_1');
        },
        loading: () => fail('Should not be loading'),
        error: (error, stack) => fail('Should not have error: $error'),
      );
    });

    test('should provide single order', () async {
      // Act
      final orderAsync = container.read(orderProvider('order_test123'));

      // Assert
      expect(orderAsync, isA<AsyncValue<Order?>>());
      
      await orderAsync.when(
        data: (order) {
          expect(order, isNotNull);
          expect(order!.id, 'order_test123');
        },
        loading: () => fail('Should not be loading'),
        error: (error, stack) => fail('Should not have error: $error'),
      );
    });
  });
}