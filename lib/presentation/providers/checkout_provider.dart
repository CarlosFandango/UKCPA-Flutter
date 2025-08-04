import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/entities/basket.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../data/repositories/checkout_repository_impl.dart';
import '../providers/graphql_provider.dart'; 
import '../providers/basket_provider.dart';

/// Checkout state definition
@immutable
sealed class CheckoutState {
  const CheckoutState();
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

class CheckoutLoaded extends CheckoutState {
  final CheckoutSession session;
  
  const CheckoutLoaded(this.session);
}

class CheckoutError extends CheckoutState {
  final String message;
  final String? errorCode;
  
  const CheckoutError(this.message, {this.errorCode});
}

class CheckoutProcessing extends CheckoutState {
  final String message;
  
  const CheckoutProcessing(this.message);
}

class CheckoutSuccess extends CheckoutState {
  final Order order;
  
  const CheckoutSuccess(this.order);
}

/// Checkout repository provider
final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return CheckoutRepositoryImpl(client);
});

/// Checkout state notifier
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final CheckoutRepository _checkoutRepository;
  final Logger _logger = Logger();

  CheckoutNotifier(this._checkoutRepository) : super(const CheckoutInitial());

  /// Initialize checkout session with basket
  Future<void> initializeCheckout(Basket basket) async {
    if (basket.isEmpty) {
      state = const CheckoutError('Basket is empty');
      return;
    }

    state = const CheckoutLoading();

    try {
      // Get available payment methods
      final paymentMethods = await _checkoutRepository.getPaymentMethods();
      
      // Create checkout session
      final session = CheckoutSession(
        basket: basket,
        availablePaymentMethods: paymentMethods,
        selectedPaymentMethod: paymentMethods.isNotEmpty 
            ? paymentMethods.firstWhere(
                (pm) => pm.isDefault == true, 
                orElse: () => paymentMethods.first,
              )
            : null,
        currentStep: 1,
      );

      state = CheckoutLoaded(session);
      _logger.d('Checkout session initialized with ${paymentMethods.length} payment methods');
    } catch (e, stackTrace) {
      _logger.e('Error initializing checkout: $e');
      _logger.e('Stack trace: $stackTrace');
      state = CheckoutError('Failed to initialize checkout: ${e.toString()}');
    }
  }

  /// Move to next step in checkout flow
  void nextStep() {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      final newStep = (currentState.session.currentStep + 1).clamp(1, 4);
      final updatedSession = currentState.session.copyWith(currentStep: newStep);
      state = CheckoutLoaded(updatedSession);
      _logger.d('Moved to checkout step $newStep');
    }
  }

  /// Move to previous step in checkout flow
  void previousStep() {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      final newStep = (currentState.session.currentStep - 1).clamp(1, 4);
      final updatedSession = currentState.session.copyWith(currentStep: newStep);
      state = CheckoutLoaded(updatedSession);
      _logger.d('Moved to checkout step $newStep');
    }
  }

  /// Select a payment method
  void selectPaymentMethod(PaymentMethod paymentMethod) {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      final updatedSession = currentState.session.copyWith(
        selectedPaymentMethod: paymentMethod,
      );
      state = CheckoutLoaded(updatedSession);
      _logger.d('Selected payment method: ${paymentMethod.id}');
    }
  }

  /// Update billing address
  void updateBillingAddress(Address address) {
    final currentState = state;
    if (currentState is CheckoutLoaded) {
      final updatedSession = currentState.session.copyWith(
        billingAddress: address,
      );
      state = CheckoutLoaded(updatedSession);
      _logger.d('Updated billing address: ${address.shortDisplay}');
    }
  }

  /// Add a new payment method
  Future<bool> addPaymentMethod({
    required String stripePaymentMethodId,
    required Address billingAddress,
    bool setAsDefault = false,
  }) async {
    try {
      state = const CheckoutProcessing('Adding payment method...');
      
      final paymentMethod = await _checkoutRepository.createPaymentMethod(
        stripePaymentMethodId: stripePaymentMethodId,
        billingAddress: billingAddress,
        setAsDefault: setAsDefault,
      );

      final currentState = state;
      if (currentState is CheckoutLoaded) {
        final updatedMethods = [
          ...currentState.session.availablePaymentMethods,
          paymentMethod,
        ];
        
        final updatedSession = currentState.session.copyWith(
          availablePaymentMethods: updatedMethods,
          selectedPaymentMethod: setAsDefault ? paymentMethod : currentState.session.selectedPaymentMethod,
          billingAddress: billingAddress,
        );
        
        state = CheckoutLoaded(updatedSession);
        _logger.d('Added payment method: ${paymentMethod.id}');
        return true;
      }
      
      return false;
    } catch (e, stackTrace) {
      _logger.e('Error adding payment method: $e');
      _logger.e('Stack trace: $stackTrace');
      state = CheckoutError('Failed to add payment method: ${e.toString()}');
      return false;
    }
  }

  /// Process payment and place order
  Future<bool> processPayment({
    String? paymentMethodId,
    String paymentMethodType = 'card',
    Address? billingAddress,
    Map<String, dynamic>? lineItemInfo,
  }) async {
    final currentState = state;
    if (currentState is! CheckoutLoaded) {
      state = const CheckoutError('Invalid checkout state');
      return false;
    }

    final basket = currentState.session.basket;
    if (basket == null || basket.isEmpty) {
      state = const CheckoutError('Basket is empty');
      return false;
    }

    try {
      state = const CheckoutProcessing('Processing payment...');

      final result = await _checkoutRepository.placeOrder(
        basket: basket,
        paymentMethodId: paymentMethodId,
        paymentMethodType: paymentMethodType,
        billingAddress: billingAddress,
        lineItemInfo: lineItemInfo,
      );

      if (!result.success) {
        state = CheckoutError(
          result.error ?? 'Payment failed',
          errorCode: result.errorCode,
        );
        return false;
      }

      if (result.order == null) {
        state = const CheckoutError('No order created');
        return false;
      }

      // Handle different payment scenarios
      if (result.nextAction == 'requires_action' && result.clientSecret != null) {
        // Update session with client secret for 3DS
        final updatedSession = currentState.session.copyWith(
          clientSecret: result.clientSecret,
          currentStep: 3,
          isProcessing: true,
        );
        state = CheckoutLoaded(updatedSession);
        return true; // Return true to indicate 3DS is needed
      } else {
        // Payment completed successfully
        state = CheckoutSuccess(result.order!);
        _logger.d('Order placed successfully: ${result.order!.id}');
        return true;
      }
    } catch (e, stackTrace) {
      _logger.e('Error processing payment: $e');
      _logger.e('Stack trace: $stackTrace');
      state = CheckoutError('Payment processing failed: ${e.toString()}');
      return false;
    }
  }

  /// Handle 3DS authentication completion
  Future<bool> complete3DSAuthentication(String paymentIntentId) async {
    try {
      state = const CheckoutProcessing('Completing authentication...');

      final success = await _checkoutRepository.updatePaymentIntent(paymentIntentId);
      
      if (success) {
        // Payment completed - we should refresh the order status
        // For now, we'll assume success and let the UI handle navigation
        _logger.d('3DS authentication completed successfully');
        return true;
      } else {
        state = const CheckoutError('Authentication failed');
        return false;
      }
    } catch (e, stackTrace) {
      _logger.e('Error completing 3DS authentication: $e');
      _logger.e('Stack trace: $stackTrace');
      state = CheckoutError('Authentication failed: ${e.toString()}');
      return false;
    }
  }

  /// Refresh payment methods
  Future<void> refreshPaymentMethods() async {
    final currentState = state;
    if (currentState is! CheckoutLoaded) return;

    try {
      final paymentMethods = await _checkoutRepository.getPaymentMethods();
      
      final updatedSession = currentState.session.copyWith(
        availablePaymentMethods: paymentMethods,
        selectedPaymentMethod: paymentMethods.isNotEmpty 
            ? paymentMethods.firstWhere(
                (pm) => pm.isDefault == true, 
                orElse: () => paymentMethods.first,
              )
            : null,
      );
      
      state = CheckoutLoaded(updatedSession);
      _logger.d('Refreshed ${paymentMethods.length} payment methods');
    } catch (e, stackTrace) {
      _logger.e('Error refreshing payment methods: $e');
      _logger.e('Stack trace: $stackTrace');
      // Don't change state on refresh error, just log it
    }
  }

  /// Reset checkout state
  void reset() {
    state = const CheckoutInitial();
    _logger.d('Checkout state reset');
  }
}

/// Main checkout provider
final checkoutNotifierProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  final repository = ref.watch(checkoutRepositoryProvider);
  return CheckoutNotifier(repository);
});

/// Convenience providers for UI consumption
final currentCheckoutSessionProvider = Provider<CheckoutSession?>((ref) {
  final state = ref.watch(checkoutNotifierProvider);
  return state is CheckoutLoaded ? state.session : null;
});

final checkoutLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(checkoutNotifierProvider);
  return state is CheckoutLoading || state is CheckoutProcessing;
});

final checkoutErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(checkoutNotifierProvider);
  return state is CheckoutError ? state.message : null;
});

final checkoutSuccessOrderProvider = Provider<Order?>((ref) {
  final state = ref.watch(checkoutNotifierProvider);
  return state is CheckoutSuccess ? state.order : null;
});

final availablePaymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  final session = ref.watch(currentCheckoutSessionProvider);
  return session?.availablePaymentMethods ?? [];
});

final selectedPaymentMethodProvider = Provider<PaymentMethod?>((ref) {
  final session = ref.watch(currentCheckoutSessionProvider);
  return session?.selectedPaymentMethod;
});

final currentCheckoutStepProvider = Provider<int>((ref) {
  final session = ref.watch(currentCheckoutSessionProvider);
  return session?.currentStep ?? 1;
});

final canProceedToPaymentProvider = Provider<bool>((ref) {
  final session = ref.watch(currentCheckoutSessionProvider);
  return session?.canProceedToPayment ?? false;
});

final requiresPaymentProvider = Provider<bool>((ref) {
  final session = ref.watch(currentCheckoutSessionProvider);
  return session?.requiresPayment ?? false;
});

/// Stripe publishable key provider
final stripePublishableKeyProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(checkoutRepositoryProvider);
  return repository.getStripePublishableKey();
});

/// Order history provider
final orderHistoryProvider = FutureProvider.family<List<Order>, ({int limit, int offset})>((ref, params) async {
  final repository = ref.watch(checkoutRepositoryProvider);
  return repository.getOrderHistory(
    limit: params.limit,
    offset: params.offset,
  );
});

/// Single order provider
final orderProvider = FutureProvider.family<Order?, String>((ref, orderId) async {
  final repository = ref.watch(checkoutRepositoryProvider);
  return repository.getOrder(orderId);
});