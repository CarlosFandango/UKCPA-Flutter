import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/basket_provider.dart';
import '../../widgets/widgets.dart';
import 'widgets/basket_item_card.dart';
import 'widgets/basket_summary.dart';
import 'widgets/empty_basket_view.dart';

/// Full basket screen implementation matching UKCPA website functionality
/// Displays itemized basket contents, pricing breakdown, and checkout flow
class BasketScreen extends ConsumerWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final basketState = ref.watch(basketNotifierProvider);
    
    return MainAppScaffold(
      title: 'Basket',
      actions: [
        // Clear basket action (only show if basket has items)
        if (basketState.basket != null && !basketState.basket!.isEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearBasketDialog(context, ref),
            tooltip: 'Clear basket',
          ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          final notifier = ref.read(basketNotifierProvider.notifier);
          await notifier.refreshBasket();
        },
        child: _buildBasketContent(context, ref, basketState),
      ),
    );
  }

  Widget _buildBasketContent(BuildContext context, WidgetRef ref, BasketState basketState) {
    if (basketState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your basket...'),
          ],
        ),
      );
    }

    if (basketState.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading basket',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                basketState.error ?? 'Unknown error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final notifier = ref.read(basketNotifierProvider.notifier);
                  notifier.refreshBasket();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final basket = basketState.basket;
    if (basket == null || basket.isEmpty) {
      return const EmptyBasketView();
    }

    return Column(
      children: [
        // Basket items list
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Basket items header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        '${basket.itemCount} item${basket.itemCount != 1 ? 's' : ''} in your basket',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/courses'),
                        child: const Text('Continue shopping'),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Basket items
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = basket.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BasketItemCard(
                          item: item,
                          onRemove: () => _removeItem(context, ref, item),
                        ),
                      );
                    },
                    childCount: basket.items.length,
                  ),
                ),
              ),
              
              // Spacing before summary
              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
        
        // Basket summary and checkout
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BasketSummary(
                basket: basket,
                onCheckout: () => _proceedToCheckout(context, ref),
                onApplyPromoCode: (code) => _applyPromoCode(context, ref, code),
                onRemovePromoCode: () => _removePromoCode(context, ref),
                onToggleCredit: (useCredit) => _toggleCredit(context, ref, useCredit),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show confirmation dialog for clearing basket
  Future<void> _showClearBasketDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Basket'),
        content: const Text('Are you sure you want to remove all items from your basket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(basketNotifierProvider.notifier);
      final success = await notifier.clearBasket();
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Basket cleared successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to clear basket'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Remove an item from the basket
  Future<void> _removeItem(BuildContext context, WidgetRef ref, item) async {
    final notifier = ref.read(basketNotifierProvider.notifier);
    final success = await notifier.removeItem(
      item.course.id,
      item.isTaster ? 'taster' : 'course',
    );

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.course.name} removed from basket')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove item'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Apply promo code to basket
  Future<void> _applyPromoCode(BuildContext context, WidgetRef ref, String code) async {
    final notifier = ref.read(basketNotifierProvider.notifier);
    final success = await notifier.applyPromoCode(code);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Promo code "$code" applied successfully')),
        );
      } else {
        final error = ref.read(basketErrorProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to apply promo code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Remove promo code from basket
  Future<void> _removePromoCode(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(basketNotifierProvider.notifier);
    final success = await notifier.removePromoCode();

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo code removed')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove promo code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Toggle credit usage for basket
  Future<void> _toggleCredit(BuildContext context, WidgetRef ref, bool useCredit) async {
    final notifier = ref.read(basketNotifierProvider.notifier);
    final success = await notifier.toggleCreditUsage(useCredit);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(useCredit ? 'Credits applied' : 'Credits removed'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update credit usage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Proceed to checkout
  void _proceedToCheckout(BuildContext context, WidgetRef ref) {
    final basket = ref.read(currentBasketProvider);
    
    if (basket == null || basket.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your basket is empty')),
      );
      return;
    }

    // Navigate to checkout screen
    context.go('/checkout');
  }
}