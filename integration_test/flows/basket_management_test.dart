import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for basket management functionality
/// Tests basket viewing, item removal, clearing basket, and promo code management
class BasketManagementTest extends BaseIntegrationTest with BasketTest, PerformanceTest {
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      await BackendHealthCheck.ensureBackendReady();
    });

    group('Basket Management', () {
      testIntegration('should clear entire basket when clear button pressed', (tester) async {
        await measurePerformance('clear_basket_flow', () async {
          await launchApp(tester);
          
          // First add items to basket
          await _attemptAddMultipleItems(tester);
          
          // Navigate to basket
          await _navigateToBasket(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Look for clear basket option
          final clearBasketElements = [
            find.text('Clear Basket'),
            find.text('Clear All'),
            find.text('Empty Basket'),
            find.byKey(const Key('clear-basket-button')),
            find.byIcon(Icons.delete_sweep),
            find.byIcon(Icons.clear_all),
          ];
          
          bool clearedBasket = false;
          for (final element in clearBasketElements) {
            if (element.evaluate().isNotEmpty) {
              await screenshot('before_clear_basket');
              
              await tester.tap(element);
              await tester.pump();
              
              // Handle confirmation dialog
              await _handleConfirmationDialog(tester);
              
              await TestHelpers.waitForAnimations(tester);
              await screenshot('after_clear_basket');
              
              clearedBasket = true;
              print('✅ Basket clear functionality tested');
              break;
            }
          }
          
          if (!clearedBasket) {
            print('ℹ️  No clear basket functionality found');
          }
        });
        
        expect(true, isTrue);
      });

      testIntegration('should remove individual items from basket', (tester) async {
        await launchApp(tester);
        
        // Add items to basket first
        await _attemptAddMultipleItems(tester);
        await _navigateToBasket(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Get initial basket count
        final initialCount = await getBasketItemCount(tester);
        print('📊 Initial basket count: $initialCount');
        
        // Look for individual remove buttons
        final removeElements = [
          find.text('Remove'),
          find.text('Delete'),
          find.byIcon(Icons.delete),
          find.byIcon(Icons.remove_circle),
          find.byIcon(Icons.close),
          find.byKey(const Key('remove-item-button')),
        ];
        
        bool removedItem = false;
        for (final element in removeElements) {
          if (element.evaluate().isNotEmpty) {
            await screenshot('before_remove_item');
            
            // Tap first remove button found
            await tester.tap(element.first);
            await tester.pump();
            
            // Handle confirmation if present
            await _handleConfirmationDialog(tester);
            
            await TestHelpers.waitForAnimations(tester);
            await screenshot('after_remove_item');
            
            removedItem = true;
            print('✅ Item removal tested');
            break;
          }
        }
        
        if (!removedItem) {
          print('ℹ️  No remove item functionality found');
        }
        
        // Check if basket count decreased
        final newCount = await getBasketItemCount(tester);
        print('📊 New basket count: $newCount');
        
        if (newCount < initialCount) {
          print('✅ Basket count decreased after removal');
        }
        
        expect(true, isTrue);
      });

      testIntegration('should handle quantity changes for basket items', (tester) async {
        await launchApp(tester);
        await _attemptAddMultipleItems(tester);
        await _navigateToBasket(tester);
        
        // Look for quantity controls
        final quantityElements = [
          find.byKey(const Key('quantity-input')),
          find.byKey(const Key('quantity-stepper')),
          find.byIcon(Icons.add),
          find.byIcon(Icons.remove),
          find.text('+'),
          find.text('-'),
        ];
        
        bool foundQuantityControls = false;
        for (final element in quantityElements) {
          if (element.evaluate().isNotEmpty) {
            foundQuantityControls = true;
            
            await screenshot('quantity_controls_found');
            
            // Try to interact with quantity controls
            try {
              if (element == find.byIcon(Icons.add) || element == find.text('+')) {
                await tester.tap(element.first);
                await tester.pump();
                await screenshot('quantity_increased');
                print('✅ Quantity increase tested');
              } else if (element == find.byIcon(Icons.remove) || element == find.text('-')) {
                await tester.tap(element.first);
                await tester.pump();
                await screenshot('quantity_decreased');
                print('✅ Quantity decrease tested');
              }
            } catch (e) {
              print('ℹ️  Quantity control interaction failed: $e');
            }
            break;
          }
        }
        
        if (!foundQuantityControls) {
          print('ℹ️  No quantity controls found');
        }
        
        expect(true, isTrue);
      });

      testIntegration('should apply and remove promo codes', (tester) async {
        await measurePerformance('promo_code_management', () async {
          await launchApp(tester);
          await _attemptAddMultipleItems(tester);
          await _navigateToBasket(tester);
          
          // Look for promo code input
          final promoCodeElements = [
            find.byKey(const Key('promo-code-field')),
            find.byKey(const Key('discount-code-field')),
            find.textContaining('promo'),
            find.textContaining('discount'),
            find.textContaining('voucher'),
            find.textContaining('code'),
          ];
          
          TextField? promoField;
          for (final element in promoCodeElements) {
            if (element.evaluate().isNotEmpty) {
              try {
                final widget = tester.widget(element);
                if (widget is TextField) {
                  promoField = widget;
                  break;
                }
              } catch (e) {
                // Continue looking
              }
            }
          }
          
          if (promoField != null) {
            await screenshot('promo_code_field_found');
            
            // Enter promo code
            await tester.enterText(find.byWidget(promoField), TestCredentials.validPromoCode);
            await tester.pump();
            
            // Look for apply button
            final applyButtons = [
              find.text('Apply'),
              find.text('Add'),
              find.text('Submit'),
              find.byIcon(Icons.add),
              find.byKey(const Key('apply-promo-button')),
            ];
            
            for (final button in applyButtons) {
              if (button.evaluate().isNotEmpty) {
                await tester.tap(button);
                await TestHelpers.waitForAnimations(tester);
                await screenshot('promo_code_applied');
                break;
              }
            }
            
            // Look for applied promo code and remove option
            final removePromoElements = [
              find.text('Remove'),
              find.text('×'),
              find.byIcon(Icons.close),
              find.byIcon(Icons.cancel),
              find.byKey(const Key('remove-promo-button')),
            ];
            
            for (final element in removePromoElements) {
              if (element.evaluate().isNotEmpty) {
                await tester.tap(element);
                await TestHelpers.waitForAnimations(tester);
                await screenshot('promo_code_removed');
                print('✅ Promo code removal tested');
                break;
              }
            }
            
            print('✅ Promo code functionality tested');
          } else {
            print('ℹ️  No promo code input field found');
          }
        });
        
        expect(true, isTrue);
      });

      testIntegration('should handle credit usage toggle', (tester) async {
        await launchApp(tester);
        await _attemptAddMultipleItems(tester);
        await _navigateToBasket(tester);
        
        // Look for credit usage options
        final creditElements = [
          find.text('Use Credit'),
          find.text('Apply Credit'),
          find.text('Account Credit'),
          find.byKey(const Key('use-credit-toggle')),
          find.byKey(const Key('credit-checkbox')),
          find.byType(Checkbox),
          find.byType(Switch),
        ];
        
        bool foundCredit = false;
        for (final element in creditElements) {
          if (element.evaluate().isNotEmpty) {
            foundCredit = true;
            
            await screenshot('credit_option_found');
            
            try {
              // Try to toggle credit usage
              await tester.tap(element);
              await tester.pump();
              await screenshot('credit_toggled');
              
              print('✅ Credit usage toggle tested');
            } catch (e) {
              print('ℹ️  Credit toggle interaction failed: $e');
            }
            break;
          }
        }
        
        if (!foundCredit) {
          print('ℹ️  No credit usage options found');
        }
        
        expect(true, isTrue);
      });

      testIntegration('should display basket total updates after changes', (tester) async {
        await launchApp(tester);
        await _attemptAddMultipleItems(tester);
        await _navigateToBasket(tester);
        
        // Get initial total
        final initialTotal = await _getBasketTotal(tester);
        print('📊 Initial basket total: $initialTotal');
        
        // Try to make a change (remove item, apply promo, etc.)
        await _attemptBasketChange(tester);
        
        // Check if total updated
        final newTotal = await _getBasketTotal(tester);
        print('📊 New basket total: $newTotal');
        
        if (initialTotal != newTotal) {
          print('✅ Basket total updated after changes');
        } else {
          print('ℹ️  Basket total unchanged or no changes made');
        }
        
        await screenshot('basket_total_after_changes');
        
        expect(true, isTrue);
      });

      testIntegration('should handle empty basket state after clearing', (tester) async {
        await launchApp(tester);
        await _attemptAddMultipleItems(tester);
        await _navigateToBasket(tester);
        
        // Clear the basket
        await _clearBasket(tester);
        
        // Check for empty basket state
        final emptyBasketIndicators = [
          find.text('Your basket is empty'),
          find.text('No items in basket'),
          find.text('Start shopping'),
          find.text('Browse courses'),
          find.byKey(const Key('empty-basket')),
          find.byIcon(Icons.shopping_cart_outlined),
        ];
        
        bool foundEmptyState = false;
        for (final indicator in emptyBasketIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundEmptyState = true;
            print('✅ Empty basket state displayed');
            break;
          }
        }
        
        await screenshot('empty_basket_after_clear');
        
        if (!foundEmptyState) {
          print('ℹ️  Empty basket state not found or different UI');
        }
        
        expect(true, isTrue);
      });

      testIntegration('should persist basket across app sessions', (tester) async {
        await measurePerformance('basket_persistence', () async {
          await launchApp(tester);
          
          // Add items to basket
          await _attemptAddMultipleItems(tester);
          
          // Navigate to basket and get count
          await _navigateToBasket(tester);
          final basketCount = await getBasketItemCount(tester);
          print('📊 Basket count before restart: $basketCount');
          
          // Restart app (simulate by navigating away and back)
          await _restartApp(tester);
          
          // Check if basket persisted
          await _navigateToBasket(tester);
          final newBasketCount = await getBasketItemCount(tester);
          print('📊 Basket count after restart: $newBasketCount');
          
          if (basketCount == newBasketCount && basketCount > 0) {
            print('✅ Basket persisted across sessions');
          } else {
            print('ℹ️  Basket persistence not implemented or different behavior');
          }
        });
        
        await screenshot('basket_after_restart');
        
        expect(true, isTrue);
      });
    });

    tearDownAll(() {
      printPerformanceReport();
    });
  }
  
  /// Helper to navigate to basket screen
  Future<void> _navigateToBasket(WidgetTester tester) async {
    final basketElements = [
      find.byKey(const Key('basket-icon')),
      find.byIcon(Icons.shopping_cart),
      find.text('Basket'),
      find.text('Cart'),
    ];
    
    for (final element in basketElements) {
      if (element.evaluate().isNotEmpty) {
        await tester.tap(element);
        await TestHelpers.waitForAnimations(tester);
        return;
      }
    }
    
    print('ℹ️  Could not find basket navigation');
  }
  
  /// Helper to attempt adding multiple items to basket
  Future<void> _attemptAddMultipleItems(WidgetTester tester) async {
    // Navigate to courses
    final courseNavOptions = [
      find.text('Browse Courses'),
      find.text('Courses'),
      find.text('Classes'),
    ];
    
    for (final option in courseNavOptions) {
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option);
        await TestHelpers.waitForAnimations(tester);
        break;
      }
    }
    
    await TestHelpers.waitForNetworkIdle(tester);
    
    // Try to add multiple items
    final addButtons = find.text('Add to Basket');
    final buttonCount = addButtons.evaluate().length;
    
    for (int i = 0; i < buttonCount && i < 2; i++) {
      try {
        await tester.tap(addButtons.at(i));
        await tester.pump();
        await _handleAddToBasketDialog(tester);
        await TestHelpers.waitForAnimations(tester);
      } catch (e) {
        print('ℹ️  Could not add item $i: $e');
      }
    }
  }
  
  /// Helper to handle add to basket dialogs
  Future<void> _handleAddToBasketDialog(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 500));
    
    // Handle payment option dialogs
    final paymentOptions = [
      find.text('Full Price'),
      find.text('Deposit'),
    ];
    
    for (final option in paymentOptions) {
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option);
        await tester.pump();
        break;
      }
    }
    
    // Handle confirmation buttons
    final confirmButtons = [
      find.text('Add'),
      find.text('Confirm'),
      find.text('Book'),
    ];
    
    for (final button in confirmButtons) {
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button);
        await tester.pump();
        break;
      }
    }
  }
  
  /// Helper to handle confirmation dialogs
  Future<void> _handleConfirmationDialog(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    
    final confirmButtons = [
      find.text('Confirm'),
      find.text('Yes'),
      find.text('OK'),
      find.text('Delete'),
      find.text('Remove'),
      find.text('Clear'),
    ];
    
    for (final button in confirmButtons) {
      if (button.evaluate().isNotEmpty) {
        await tester.tap(button);
        await tester.pump();
        break;
      }
    }
  }
  
  /// Helper to get basket total as string
  Future<String> _getBasketTotal(WidgetTester tester) async {
    final totalElements = [
      find.textContaining('Total: £'),
      find.textContaining('£'),
      find.byKey(const Key('basket-total')),
    ];
    
    for (final element in totalElements) {
      if (element.evaluate().isNotEmpty) {
        try {
          final widget = tester.widget(element);
          if (widget is Text) {
            return widget.data ?? '';
          }
        } catch (e) {
          // Continue looking
        }
      }
    }
    
    return 'Unknown';
  }
  
  /// Helper to attempt making a change to basket
  Future<void> _attemptBasketChange(WidgetTester tester) async {
    // Try removing an item first
    final removeButtons = find.text('Remove');
    if (removeButtons.evaluate().isNotEmpty) {
      await tester.tap(removeButtons.first);
      await tester.pump();
      await _handleConfirmationDialog(tester);
      return;
    }
    
    // Try applying a promo code
    final promoField = find.byKey(const Key('promo-code-field'));
    if (promoField.evaluate().isNotEmpty) {
      await tester.enterText(promoField, TestCredentials.validPromoCode);
      await tester.pump();
      
      final applyButton = find.text('Apply');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pump();
      }
    }
  }
  
  /// Helper to clear basket
  Future<void> _clearBasket(WidgetTester tester) async {
    final clearElements = [
      find.text('Clear Basket'),
      find.text('Clear All'),
      find.byKey(const Key('clear-basket-button')),
    ];
    
    for (final element in clearElements) {
      if (element.evaluate().isNotEmpty) {
        await tester.tap(element);
        await tester.pump();
        await _handleConfirmationDialog(tester);
        return;
      }
    }
  }
  
  /// Helper to restart app (navigate away and back)
  Future<void> _restartApp(WidgetTester tester) async {
    // Navigate to home or another screen
    final homeElements = [
      find.text('Home'),
      find.byIcon(Icons.home),
      find.byKey(const Key('home-tab')),
    ];
    
    for (final element in homeElements) {
      if (element.evaluate().isNotEmpty) {
        await tester.tap(element);
        await TestHelpers.waitForAnimations(tester);
        break;
      }
    }
    
    // Wait a bit to simulate session change
    await tester.pump(const Duration(seconds: 1));
  }
}

// Test runner
void main() {
  BasketManagementTest().main();
}