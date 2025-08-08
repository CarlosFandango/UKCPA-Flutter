import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukcpa_flutter/presentation/providers/checkout_provider.dart';
import 'package:ukcpa_flutter/presentation/widgets/stripe_card_input_form.dart';
import 'package:ukcpa_flutter/domain/entities/basket.dart';
import 'package:ukcpa_flutter/services/stripe_payment_service.dart';
import 'package:ukcpa_flutter/core/errors/payment_exception.dart';

// Use centralized mocks for consistency with existing test infrastructure
import '../mocks/mock_repositories.dart';
import '../mocks/mock_data_factory.dart';
import '../helpers/test_app_wrapper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Payment Flow Integration Tests', () {
    late MockCheckoutRepository mockCheckoutRepository;
    late MockStripePaymentService mockStripeService;

    setUpAll(() {
      // Configure for integration testing
      MockConfig.configureForSpeed(); // Fast but realistic timing
    });

    setUp(() {
      mockCheckoutRepository = MockRepositoryFactory.getCheckoutRepository();
      mockStripeService = MockRepositoryFactory.getStripePaymentService();
      MockConfig.resetToDefaults();
    });

    group('Successful Payment Flow', () {
      testWidgets('should complete full payment flow successfully', (WidgetTester tester) async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act & Assert: Initialize checkout
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        expect(find.text('Checkout Initialized'), findsOneWidget);
        expect(find.text('Step: 1'), findsOneWidget);
        expect(find.text('Payment Methods: 2'), findsOneWidget);

        // Act & Assert: Move through checkout steps
        await tester.tap(find.byKey(const Key('next_step')));
        await tester.pumpAndSettle();
        expect(find.text('Step: 2'), findsOneWidget);

        // Act & Assert: Enter card details
        await tester.tap(find.byKey(const Key('show_card_form')));
        await tester.pumpAndSettle();

        // Find and interact with card form
        final cardForm = find.byType(StripeCardInputForm);
        expect(cardForm, findsOneWidget);

        // Simulate complete card entry
        final cardFormState = tester.state<_StripeCardInputFormState>(cardForm);
        final completeCardData = {
          'complete': true,
          'validNumber': true,
          'validCVC': true,
          'validExpiryDate': true,
          'last4': '4242',
          'brand': 'visa',
        };
        cardFormState._onCardChanged(completeCardData);
        await tester.pumpAndSettle();

        // Act & Assert: Process payment
        await tester.tap(find.byKey(const Key('process_payment')));
        await tester.pumpAndSettle();

        expect(find.text('Payment Successful'), findsOneWidget);
        expect(find.text('Order ID: order_test123'), findsOneWidget);
      });

      testWidgets('should handle saved payment method selection', (WidgetTester tester) async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize checkout
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        // Act: Select different payment method
        await tester.tap(find.byKey(const Key('select_payment_method')));
        await tester.pumpAndSettle();

        expect(find.text('Payment Method Selected: pm_mastercard'), findsOneWidget);

        // Act: Process payment with saved method
        await tester.tap(find.byKey(const Key('process_saved_payment')));
        await tester.pumpAndSettle();

        expect(find.text('Payment Successful'), findsOneWidget);
      });
    });

    group('3D Secure Authentication Flow', () {
      testWidgets('should handle 3DS authentication successfully', (WidgetTester tester) async {
        // Arrange - Configure for 3DS testing
        MockConfig.configureFor3DSTesting();
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize and process payment
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('process_payment_3ds')));
        await tester.pumpAndSettle();

        // Assert: Should show 3DS required
        expect(find.text('3DS Required'), findsOneWidget);
        expect(find.text('Client Secret: pi_test_client_secret'), findsOneWidget);
        expect(find.text('Step: 3'), findsOneWidget);

        // Act: Complete 3DS authentication
        await tester.tap(find.byKey(const Key('complete_3ds')));
        await tester.pumpAndSettle();

        // Assert: Should complete successfully
        expect(find.text('3DS Completed'), findsOneWidget);
      });

      testWidgets('should handle 3DS cancellation', (WidgetTester tester) async {
        // Arrange - Configure for 3DS cancellation
        MockConfig.configureFor3DSTesting();
        MockConfig.simulate3DSCancellation = true;
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize, process payment, then cancel 3DS
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('process_payment_3ds')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('complete_3ds')));
        await tester.pumpAndSettle();

        // Assert: Should return to checkout flow
        expect(find.text('3DS Cancelled'), findsOneWidget);
        expect(find.text('Step: 2'), findsOneWidget); // Back in checkout flow
      });
    });

    group('Payment Error Scenarios', () {
      testWidgets('should handle card declined error', (WidgetTester tester) async {
        // Arrange - Configure for payment errors
        MockConfig.configureForPaymentErrors();
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize and attempt payment
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('process_payment')));
        await tester.pumpAndSettle();

        // Assert: Should show error
        expect(find.text('Payment Failed'), findsOneWidget);
        expect(find.text('Error: Payment failed'), findsOneWidget);
        expect(find.text('Code: CARD_DECLINED'), findsOneWidget);
      });

      testWidgets('should handle card validation errors', (WidgetTester tester) async {
        // Arrange
        MockConfig.simulateCardError = true;
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize checkout and try invalid card
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('show_card_form')));
        await tester.pumpAndSettle();

        // Simulate invalid card entry
        final cardForm = find.byType(StripeCardInputForm);
        final cardFormState = tester.state<_StripeCardInputFormState>(cardForm);
        final invalidCardData = {
          'complete': false,
          'validNumber': false,
          'validCVC': false,
          'validExpiryDate': false,
        };
        cardFormState._onCardChanged(invalidCardData);
        await tester.pumpAndSettle();

        // Act: Try to create payment method with invalid card
        await tester.tap(find.byKey(const Key('create_payment_method')));
        await tester.pumpAndSettle();

        // Assert: Should show validation error
        expect(find.text('Card Error'), findsOneWidget);
        expect(find.text('Your card was declined'), findsOneWidget);
      });

      testWidgets('should handle network errors', (WidgetTester tester) async {
        // Arrange - Configure for network errors
        MockConfig.configureForErrorTesting();
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Try to initialize with network error
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        // Assert: Should show network error
        expect(find.text('Initialization Error'), findsOneWidget);
        expect(find.text('Network request failed'), findsOneWidget);
      });
    });

    group('Empty Basket Scenarios', () {
      testWidgets('should handle empty basket gracefully', (WidgetTester tester) async {
        // Arrange
        final emptyBasket = MockDataFactory.emptyBasket;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: emptyBasket),
          ),
        );

        // Act: Try to initialize with empty basket
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        // Assert: Should show empty basket error
        expect(find.text('Empty Basket Error'), findsOneWidget);
        expect(find.text('Basket is empty'), findsOneWidget);
      });
    });

    group('Payment Method Management', () {
      testWidgets('should add new payment method successfully', (WidgetTester tester) async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize and add payment method
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        expect(find.text('Payment Methods: 2'), findsOneWidget);

        await tester.tap(find.byKey(const Key('show_card_form')));
        await tester.pumpAndSettle();

        // Enter valid card details
        final cardForm = find.byType(StripeCardInputForm);
        final cardFormState = tester.state<_StripeCardInputFormState>(cardForm);
        final validCardData = {
          'complete': true,
          'validNumber': true,
          'validCVC': true,
          'validExpiryDate': true,
          'last4': '1234',
          'brand': 'mastercard',
        };
        cardFormState._onCardChanged(validCardData);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('create_payment_method')));
        await tester.pumpAndSettle();

        // Assert: Should have added new payment method
        expect(find.text('Payment Method Added'), findsOneWidget);
        expect(find.text('Payment Methods: 3'), findsOneWidget);
      });
    });

    group('User Experience Flows', () {
      testWidgets('should maintain state during step navigation', (WidgetTester tester) async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize and navigate through steps
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        expect(find.text('Step: 1'), findsOneWidget);

        // Navigate forward
        await tester.tap(find.byKey(const Key('next_step')));
        await tester.pumpAndSettle();
        expect(find.text('Step: 2'), findsOneWidget);

        await tester.tap(find.byKey(const Key('next_step')));
        await tester.pumpAndSettle();
        expect(find.text('Step: 3'), findsOneWidget);

        // Navigate backward
        await tester.tap(find.byKey(const Key('previous_step')));
        await tester.pumpAndSettle();
        expect(find.text('Step: 2'), findsOneWidget);

        // Assert: Payment methods should still be available
        expect(find.text('Payment Methods: 2'), findsOneWidget);
      });

      testWidgets('should reset checkout state properly', (WidgetTester tester) async {
        // Arrange
        final basket = MockDataFactory.basketWithItems;
        
        await tester.pumpWidget(
          TestAppWrapper(
            overrides: [
              checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepository),
              stripePaymentServiceProvider.overrideWithValue(mockStripeService),
            ],
            child: PaymentFlowTestScreen(basket: basket),
          ),
        );

        // Act: Initialize, then reset
        await tester.tap(find.byKey(const Key('initialize_checkout')));
        await tester.pumpAndSettle();

        expect(find.text('Checkout Initialized'), findsOneWidget);

        await tester.tap(find.byKey(const Key('reset_checkout')));
        await tester.pumpAndSettle();

        // Assert: Should be back to initial state
        expect(find.text('Initial State'), findsOneWidget);
        expect(find.text('Checkout Initialized'), findsNothing);
      });
    });
  });
}

/// Test screen for payment flow integration tests
class PaymentFlowTestScreen extends ConsumerWidget {
  final Basket basket;

  const PaymentFlowTestScreen({Key? key, required this.basket}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutNotifierProvider);
    final checkoutNotifier = ref.watch(checkoutNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Flow Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // State Display
            _buildStateDisplay(checkoutState),
            const SizedBox(height: 20),
            
            // Action Buttons
            _buildActionButtons(checkoutNotifier, checkoutState),
            
            // Card Form (when visible)
            if (_shouldShowCardForm(checkoutState)) ...[
              const SizedBox(height: 20),
              _buildCardForm(checkoutNotifier),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateDisplay(CheckoutState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State: ${state.runtimeType}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            if (state is CheckoutInitial) 
              const Text('Initial State'),
            
            if (state is CheckoutLoading) 
              const Text('Loading...'),
            
            if (state is CheckoutLoaded) ...[
              const Text('Checkout Initialized'),
              Text('Step: ${state.session.currentStep}'),
              Text('Payment Methods: ${state.session.availablePaymentMethods.length}'),
              if (state.session.selectedPaymentMethod != null)
                Text('Selected: ${state.session.selectedPaymentMethod!.id}'),
              if (state.session.clientSecret != null) ...[
                const Text('3DS Required'),
                Text('Client Secret: ${state.session.clientSecret}'),
              ],
            ],
            
            if (state is CheckoutError) ...[
              if (state.message.contains('empty')) 
                const Text('Empty Basket Error')
              else if (state.message.contains('Network')) 
                const Text('Network Error')
              else if (state.message.contains('Failed to initialize'))
                const Text('Initialization Error')
              else
                const Text('Payment Failed'),
              Text('Error: ${state.message}'),
              if (state.errorCode != null) Text('Code: ${state.errorCode}'),
            ],
            
            if (state is CheckoutProcessing) 
              Text('Processing: ${state.message}'),
            
            if (state is CheckoutSuccess) ...[
              const Text('Payment Successful'),
              Text('Order ID: ${state.order.id}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(CheckoutNotifier notifier, CheckoutState state) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          key: const Key('initialize_checkout'),
          onPressed: () => notifier.initializeCheckout(basket),
          child: const Text('Initialize'),
        ),
        
        if (state is CheckoutLoaded) ...[
          ElevatedButton(
            key: const Key('next_step'),
            onPressed: notifier.nextStep,
            child: const Text('Next Step'),
          ),
          ElevatedButton(
            key: const Key('previous_step'),
            onPressed: notifier.previousStep,
            child: const Text('Previous Step'),
          ),
          ElevatedButton(
            key: const Key('select_payment_method'),
            onPressed: () {
              final secondMethod = state.session.availablePaymentMethods
                  .firstWhere((pm) => pm.id == 'pm_mastercard');
              notifier.selectPaymentMethod(secondMethod);
            },
            child: const Text('Select Mastercard'),
          ),
          ElevatedButton(
            key: const Key('process_payment'),
            onPressed: () => notifier.processPayment(
              paymentMethodId: 'pm_test123',
              paymentMethodType: 'card',
            ),
            child: const Text('Process Payment'),
          ),
          ElevatedButton(
            key: const Key('process_payment_3ds'),
            onPressed: () => notifier.processPayment(
              paymentMethodId: 'pm_3ds_test',
              paymentMethodType: 'card',
            ),
            child: const Text('Process 3DS Payment'),
          ),
          ElevatedButton(
            key: const Key('process_saved_payment'),
            onPressed: () => notifier.processPayment(
              paymentMethodId: state.session.selectedPaymentMethod?.id ?? 'pm_test123',
              paymentMethodType: 'card',
            ),
            child: const Text('Process Saved Payment'),
          ),
          if (state.session.clientSecret != null)
            ElevatedButton(
              key: const Key('complete_3ds'),
              onPressed: () => notifier.handle3DSAuthentication(state.session.clientSecret!),
              child: const Text('Complete 3DS'),
            ),
        ],
        
        ElevatedButton(
          key: const Key('reset_checkout'),
          onPressed: notifier.reset,
          child: const Text('Reset'),
        ),
      ],
    );
  }

  Widget _buildCardForm(CheckoutNotifier notifier) {
    bool _showCardForm = false;
    bool _cardAdded = false;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            ElevatedButton(
              key: const Key('show_card_form'),
              onPressed: () => setState(() => _showCardForm = !_showCardForm),
              child: Text(_showCardForm ? 'Hide Card Form' : 'Show Card Form'),
            ),
            
            if (_showCardForm) ...[
              const SizedBox(height: 16),
              StripeCardInputForm(
                onCardChanged: (cardData) {
                  // Handle card changes
                },
                onCardComplete: (cardData) {
                  // Handle card completion
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('create_payment_method'),
                onPressed: () async {
                  try {
                    final result = await notifier.createPaymentMethodFromCard(
                      cardDetails: {
                        'complete': true,
                        'validNumber': true,
                        'validCVC': true,
                        'validExpiryDate': true,
                        'last4': '1234',
                        'brand': 'mastercard',
                      },
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
                    
                    if (result) {
                      setState(() => _cardAdded = true);
                    }
                  } on PaymentException catch (e) {
                    // Handle payment exception
                    setState(() => _cardAdded = false);
                  }
                },
                child: const Text('Add Payment Method'),
              ),
              
              if (_cardAdded) 
                const Text('Payment Method Added'),
            ],
          ],
        );
      },
    );
  }

  bool _shouldShowCardForm(CheckoutState state) {
    return state is CheckoutLoaded;
  }
}

/// Helper extension for better state handling in tests
extension CheckoutStateTestHelpers on CheckoutState {
  bool get isLoaded => this is CheckoutLoaded;
  bool get isError => this is CheckoutError;
  bool get isSuccess => this is CheckoutSuccess;
  bool get isProcessing => this is CheckoutProcessing;
  
  CheckoutSession? get session => this is CheckoutLoaded ? (this as CheckoutLoaded).session : null;
  String? get errorMessage => this is CheckoutError ? (this as CheckoutError).message : null;
  String? get errorCode => this is CheckoutError ? (this as CheckoutError).errorCode : null;
}