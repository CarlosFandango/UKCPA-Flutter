import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/basket.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/basket_provider.dart';
import '../../widgets/widgets.dart';
import 'widgets/checkout_progress_indicator.dart';
import 'widgets/order_summary_card.dart';
import 'widgets/payment_method_selection.dart';
import 'widgets/billing_address_form.dart';
import 'widgets/order_confirmation_card.dart';
import '../../../domain/entities/checkout.dart';

/// Main checkout screen implementing multi-step checkout flow
/// Based on UKCPA website checkout functionality with Flutter Material 3 design
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    // Initialize checkout when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCheckout();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeCheckout() {
    final basket = ref.read(currentBasketProvider);
    if (basket != null && !basket.isEmpty) {
      ref.read(checkoutNotifierProvider.notifier).initializeCheckout(basket);
    } else {
      // Redirect to basket if empty
      context.go('/basket');
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutNotifierProvider);
    final currentStep = ref.watch(currentCheckoutStepProvider);

    return MainAppScaffold(
      title: 'Checkout',
      body: _buildCheckoutContent(context, checkoutState, currentStep),
    );
  }

  Widget _buildCheckoutContent(BuildContext context, CheckoutState state, int currentStep) {
    switch (state) {
      case CheckoutInitial():
        return const Center(
          child: CircularProgressIndicator(),
        );
        
      case CheckoutLoading():
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing checkout...'),
            ],
          ),
        );

      case CheckoutError():
        return _buildErrorView(context, state.message);

      case CheckoutProcessing():
        return _buildProcessingView(context, state.message);

      case CheckoutSuccess():
        return _buildSuccessView(context, state.order);

      case CheckoutLoaded():
        return _buildCheckoutFlow(context, state.session, currentStep);
    }
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Checkout Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => context.go('/basket'),
                  child: const Text('Back to Basket'),
                ),
                ElevatedButton(
                  onPressed: _initializeCheckout,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingView(BuildContext context, String message) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Processing Payment',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.security,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Secure payment processing',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, Order order) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your order has been placed successfully.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Order #${order.id}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/my-account/orders/${order.id}'),
                    child: const Text('View Order Details'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/courses'),
                    child: const Text('Continue Shopping'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutFlow(BuildContext context, CheckoutSession session, int currentStep) {
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: CheckoutProgressIndicator(
            currentStep: currentStep,
            totalSteps: 3,
          ),
        ),
        
        // Checkout content
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
            children: [
              _buildOrderReviewStep(context, session),
              _buildPaymentDetailsStep(context, session),
              _buildConfirmationStep(context, session),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderReviewStep(BuildContext context, CheckoutSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order summary
          OrderSummaryCard(
            basket: session.basket!,
            showEditButton: true,
            onEdit: () => context.go('/basket'),
          ),
          
          const SizedBox(height: 24),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _moveToNextStep(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Continue to Payment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailsStep(BuildContext context, CheckoutSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment method selection
          PaymentMethodSelection(
            availablePaymentMethods: session.availablePaymentMethods,
            selectedPaymentMethod: session.selectedPaymentMethod,
            onPaymentMethodSelected: (paymentMethod) {
              ref.read(checkoutNotifierProvider.notifier).selectPaymentMethod(paymentMethod);
            },
            onAddPaymentMethod: () => _showAddPaymentMethodDialog(context),
          ),
          
          const SizedBox(height: 24),
          
          // Billing address form (if needed)
          if (session.selectedPaymentMethod == null || session.billingAddress == null)
            BillingAddressForm(
              initialAddress: session.billingAddress,
              onAddressChanged: (address) {
                ref.read(checkoutNotifierProvider.notifier).updateBillingAddress(address);
              },
            ),
          
          const SizedBox(height: 24),
          
          // Navigation buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _moveToPreviousStep(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Back'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: session.canProceedToPayment 
                      ? () => _processPayment(context, session)
                      : null,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Place Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(BuildContext context, CheckoutSession session) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderConfirmationCard(
            basket: session.basket!,
            paymentMethod: session.selectedPaymentMethod,
            billingAddress: session.billingAddress,
          ),
          
          const SizedBox(height: 24),
          
          // Terms and conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'By placing this order, you agree to our Terms and Conditions and Privacy Policy.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Final confirmation button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _finalizeOrder(context, session),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Confirm & Pay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _moveToNextStep() {
    final currentStep = ref.read(currentCheckoutStepProvider);
    if (currentStep < 3) {
      ref.read(checkoutNotifierProvider.notifier).nextStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _moveToPreviousStep() {
    final currentStep = ref.read(currentCheckoutStepProvider);
    if (currentStep > 1) {
      ref.read(checkoutNotifierProvider.notifier).previousStep();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _processPayment(BuildContext context, CheckoutSession session) async {
    // Move to confirmation step first
    _moveToNextStep();
  }

  Future<void> _finalizeOrder(BuildContext context, CheckoutSession session) async {
    final notifier = ref.read(checkoutNotifierProvider.notifier);
    
    final success = await notifier.processPayment(
      paymentMethodId: session.selectedPaymentMethod?.id,
      paymentMethodType: session.selectedPaymentMethod != null ? 'card' : 'credit',
      billingAddress: session.billingAddress,
      lineItemInfo: session.formData?.lineItemInfo,
    );

    if (success && mounted) {
      // Handle 3DS or success - the provider will manage state transitions
      final newState = ref.read(checkoutNotifierProvider);
      if (newState is CheckoutLoaded && newState.session.clientSecret != null) {
        // 3DS authentication required
        _handle3DSAuthentication(context, newState.session.clientSecret!);
      }
    }
  }

  Future<void> _handle3DSAuthentication(BuildContext context, String clientSecret) async {
    // TODO: Integrate with Stripe 3DS authentication
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Authenticating your payment...'),
            SizedBox(height: 8),
            Text(
              '3D Secure authentication would be handled here.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simulate successful authentication
              ref.read(checkoutNotifierProvider.notifier).complete3DSAuthentication(clientSecret);
            },
            child: const Text('Simulate Success'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPaymentMethodDialog(BuildContext context) async {
    // TODO: Implement add payment method dialog with Stripe integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add payment method functionality will be implemented with Stripe integration'),
      ),
    );
  }
}