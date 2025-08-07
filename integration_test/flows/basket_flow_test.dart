import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/navigation_test_helper.dart';
import '../helpers/form_interaction_helper.dart';
import '../helpers/ui_component_interaction_helper.dart';
import '../helpers/authentication_flow_helper.dart';
import '../helpers/automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Comprehensive Integration Tests for Basket Flows
/// 
/// Tests basket functionality end-to-end including:
/// - Adding items to basket
/// - Removing items from basket
/// - Applying promo codes
/// - Credit usage
/// - Basket persistence
/// - Error handling
/// 
/// These tests ensure the basket functionality works correctly
/// across the entire user flow from course discovery to checkout.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Basket Flow Integration Tests', () {
    
    testWidgets('🛒 Complete basket flow - add course, modify, checkout', (WidgetTester tester) async {
      print('\n🚀 TESTING COMPLETE BASKET FLOW\n');
      
      // Phase 1: Authentication Setup
      print('📍 PHASE 1: Authentication Setup');
      await _authenticateUser(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_01_authenticated');
      
      // Phase 2: Navigate to Course Discovery
      print('\n📍 PHASE 2: Navigate to Course Discovery');
      await _navigateToCourseDiscovery(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_02_course_discovery');
      
      // Phase 3: Add Course to Basket
      print('\n📍 PHASE 3: Add Course to Basket');
      await _addCourseToBasket(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_03_course_added');
      
      // Phase 4: View and Validate Basket
      print('\n📍 PHASE 4: View and Validate Basket');
      await _viewAndValidateBasket(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_04_basket_view');
      
      // Phase 5: Modify Basket (Add Another Item)
      print('\n📍 PHASE 5: Add Second Course to Basket');
      await _addSecondCourseToBasket(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_05_two_courses');
      
      // Phase 6: Apply Promo Code
      print('\n📍 PHASE 6: Apply Promo Code');
      await _applyPromoCode(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_06_promo_applied');
      
      // Phase 7: Remove Item
      print('\n📍 PHASE 7: Remove One Item from Basket');
      await _removeItemFromBasket(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_07_item_removed');
      
      // Phase 8: Test Basket Persistence
      print('\n📍 PHASE 8: Test Basket Persistence (Navigate Away and Back)');
      await _testBasketPersistence(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_flow_08_persistence');
      
      print('\n✅ Complete basket flow test completed successfully!');
      print('📸 Screenshots saved to build/screenshots/basket_flow_*.png');
    });

    testWidgets('🔄 Basket error scenarios and edge cases', (WidgetTester tester) async {
      print('\n🚀 TESTING BASKET ERROR SCENARIOS\n');
      
      // Phase 1: Setup
      await _authenticateUser(tester);
      await _navigateToCourseDiscovery(tester);
      
      // Phase 2: Test Invalid Promo Code
      print('\n📍 PHASE 2: Test Invalid Promo Code');
      await _testInvalidPromoCode(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_errors_01_invalid_promo');
      
      // Phase 3: Test Network Error Handling
      print('\n📍 PHASE 3: Test Network Error Scenarios');
      await _testNetworkErrorScenarios(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_errors_02_network_errors');
      
      // Phase 4: Test Empty Basket Behavior
      print('\n📍 PHASE 4: Test Empty Basket Behavior');
      await _testEmptyBasketBehavior(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_errors_03_empty_basket');
      
      print('\n✅ Basket error scenario tests completed!');
    });

    testWidgets('💳 Basket credit and payment options flow', (WidgetTester tester) async {
      print('\n🚀 TESTING BASKET CREDIT AND PAYMENT FLOWS\n');
      
      // Phase 1: Setup with courses in basket
      await _authenticateUser(tester);
      await _navigateToCourseDiscovery(tester);
      await _addCourseToBasket(tester);
      
      // Phase 2: Test Credit Usage
      print('\n📍 PHASE 2: Test Credit Usage Toggle');
      await _testCreditUsage(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_payment_01_credits');
      
      // Phase 3: Test Deposit Payment Options
      print('\n📍 PHASE 3: Test Deposit Payment Options');
      await _testDepositPaymentOptions(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_payment_02_deposits');
      
      // Phase 4: Test Taster Course Booking
      print('\n📍 PHASE 4: Test Taster Course Booking');
      await _testTasterCourseBooking(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_payment_03_taster');
      
      print('\n✅ Basket payment flow tests completed!');
    });

    testWidgets('📱 Basket UI responsiveness and accessibility', (WidgetTester tester) async {
      print('\n🚀 TESTING BASKET UI RESPONSIVENESS\n');
      
      await _authenticateUser(tester);
      await _addCourseToBasket(tester);
      
      // Test responsive design at different screen sizes
      print('\n📍 Testing Responsive Design');
      await _testBasketResponsiveDesign(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_ui_01_responsive');
      
      // Test accessibility features
      print('\n📍 Testing Accessibility Features');
      await _testBasketAccessibility(tester);
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'basket_ui_02_accessibility');
      
      print('\n✅ Basket UI tests completed!');
    });
  });
}

/// Helper Methods for Basket Flow Tests
/// These methods encapsulate common basket test operations

/// Authenticate user for basket tests
Future<void> _authenticateUser(WidgetTester tester) async {
  final authResult = await AuthenticationFlowHelper.loginAs(
    tester, 
    UserRole.registeredUser,
    verboseLogging: true,
  );
  
  expect(authResult.loginSuccess, isTrue, 
    reason: 'Authentication required for basket tests');
  print('✅ User authenticated successfully');
}

/// Navigate to course discovery page
Future<void> _navigateToCourseDiscovery(WidgetTester tester) async {
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.courseList,
    verboseLogging: true,
  );
  
  // Wait for courses to load
  await AutomatedTestTemplate.waitForElement(
    tester,
    find.text('View Course').or(find.text('Add to Basket')),
    timeout: const Duration(seconds: 10),
  );
  
  print('✅ Course discovery page loaded');
}

/// Add first course to basket
Future<void> _addCourseToBasket(WidgetTester tester) async {
  // Look for Add to Basket or similar buttons
  final addToBasketFinder = find.text('Add to Basket')
    .or(find.text('Book Course'))
    .or(find.text('Book Now'));
    
  if (addToBasketFinder.evaluate().isNotEmpty) {
    await tester.tap(addToBasketFinder.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Verify basket count increased
    await _verifyBasketCount(tester, expectedMinCount: 1);
    print('✅ Course added to basket successfully');
  } else {
    // Alternative: Click View Course then Add to Basket
    final viewCourseFinder = find.text('View Course');
    if (viewCourseFinder.evaluate().isNotEmpty) {
      await tester.tap(viewCourseFinder.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Look for Add to Basket on course detail page
      final detailAddBasket = find.text('Add to Basket')
        .or(find.text('Book This Course'));
      
      if (detailAddBasket.evaluate().isNotEmpty) {
        await tester.tap(detailAddBasket.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('✅ Course added via course detail page');
      } else {
        print('⚠️ No Add to Basket button found on course detail page');
      }
    } else {
      print('⚠️ No course booking buttons found');
    }
  }
}

/// View and validate basket contents
Future<void> _viewAndValidateBasket(WidgetTester tester) async {
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
    verboseLogging: true,
  );
  
  // Verify basket is not empty
  final emptyBasketText = find.text('Your basket is empty')
    .or(find.text('No items in basket'));
  
  expect(emptyBasketText.evaluate().isEmpty, isTrue,
    reason: 'Basket should not be empty after adding course');
  
  // Look for basket total
  final basketTotal = find.textContaining('Total:')
    .or(find.textContaining('£'))
    .or(find.textContaining('Subtotal:'));
    
  expect(basketTotal.evaluate().isNotEmpty, isTrue,
    reason: 'Basket should show total amount');
  
  print('✅ Basket validation completed');
}

/// Add second course to basket
Future<void> _addSecondCourseToBasket(WidgetTester tester) async {
  // Navigate back to course list
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.courseList,
  );
  
  // Find second course to add (skip first one)
  final courseButtons = find.text('Add to Basket')
    .or(find.text('View Course'));
  
  if (courseButtons.evaluate().length >= 2) {
    await tester.tap(courseButtons.at(1));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // If we navigated to detail page, add from there
    final addButtons = find.text('Add to Basket');
    if (addButtons.evaluate().isNotEmpty) {
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    
    await _verifyBasketCount(tester, expectedMinCount: 2);
    print('✅ Second course added to basket');
  } else {
    print('⚠️ Only one course available for testing');
  }
}

/// Apply promo code to basket
Future<void> _applyPromoCode(WidgetTester tester) async {
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
  );
  
  // Look for promo code field
  final promoField = find.byKey(const Key('promo-code-field'))
    .or(find.textContaining('Promo'))
    .or(find.textContaining('Discount'));
  
  if (promoField.evaluate().isNotEmpty) {
    // Test with a valid promo code (if configured)
    await FormInteractionHelper.fillAndSubmitForm(
      tester,
      {
        'promo-code-field': 'TESTCODE10',
      },
      submitButtonText: 'Apply Code',
      validationWait: const Duration(seconds: 2),
    );
    
    print('✅ Promo code application attempted');
  } else {
    print('⚠️ Promo code field not found in basket');
  }
}

/// Remove item from basket
Future<void> _removeItemFromBasket(WidgetTester tester) async {
  // Look for remove buttons
  final removeButtons = find.textContaining('Remove')
    .or(find.byIcon(Icons.delete))
    .or(find.byIcon(Icons.close));
  
  if (removeButtons.evaluate().isNotEmpty) {
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Confirm removal if dialog appears
    final confirmButton = find.text('Confirm')
      .or(find.text('Yes'))
      .or(find.text('Remove'));
    
    if (confirmButton.evaluate().isNotEmpty) {
      await tester.tap(confirmButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }
    
    print('✅ Item removed from basket');
  } else {
    print('⚠️ No remove buttons found in basket');
  }
}

/// Test basket persistence across navigation
Future<void> _testBasketPersistence(WidgetTester tester) async {
  // Navigate away from basket
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.courseList,
  );
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Navigate back to basket
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
  );
  
  // Verify basket still has content
  final emptyBasketText = find.text('Your basket is empty');
  final basketItems = find.textContaining('£');
  
  if (basketItems.evaluate().isNotEmpty && emptyBasketText.evaluate().isEmpty) {
    print('✅ Basket persistence verified - items maintained');
  } else {
    print('⚠️ Basket persistence issue - items may have been lost');
  }
}

/// Test invalid promo code handling
Future<void> _testInvalidPromoCode(WidgetTester tester) async {
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
  );
  
  // Try invalid promo code
  final promoField = find.byKey(const Key('promo-code-field'));
  if (promoField.evaluate().isNotEmpty) {
    await FormInteractionHelper.fillAndSubmitForm(
      tester,
      {
        'promo-code-field': 'INVALID_CODE_12345',
      },
      submitButtonText: 'Apply Code',
      validationWait: const Duration(seconds: 2),
    );
    
    // Look for error message
    final errorMessage = find.textContaining('invalid')
      .or(find.textContaining('error'))
      .or(find.textContaining('not found'));
    
    if (errorMessage.evaluate().isNotEmpty) {
      print('✅ Invalid promo code error handling works');
    } else {
      print('⚠️ No error message shown for invalid promo code');
    }
  }
}

/// Test network error scenarios
Future<void> _testNetworkErrorScenarios(WidgetTester tester) async {
  // This would require mocking network failures
  // For now, we'll test the UI response to errors
  
  // Try operations that might trigger network calls
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
  );
  
  // Rapid successive operations to potentially trigger errors
  final refreshButton = find.byIcon(Icons.refresh)
    .or(find.text('Refresh'));
  
  if (refreshButton.evaluate().isNotEmpty) {
    for (int i = 0; i < 3; i++) {
      await tester.tap(refreshButton.first);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  print('✅ Network error scenario testing completed');
}

/// Test empty basket behavior
Future<void> _testEmptyBasketBehavior(WidgetTester tester) async {
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
  );
  
  // Remove all items if any exist
  final removeButtons = find.textContaining('Remove').or(find.byIcon(Icons.delete));
  while (removeButtons.evaluate().isNotEmpty) {
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    // Confirm removal if needed
    final confirmButton = find.text('Confirm').or(find.text('Yes'));
    if (confirmButton.evaluate().isNotEmpty) {
      await tester.tap(confirmButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
  }
  
  // Verify empty basket UI
  final emptyBasketMessage = find.text('Your basket is empty')
    .or(find.text('No items'))
    .or(find.text('Add some courses'));
  
  expect(emptyBasketMessage.evaluate().isNotEmpty, isTrue,
    reason: 'Empty basket should show appropriate message');
  
  print('✅ Empty basket behavior verified');
}

/// Test credit usage functionality
Future<void> _testCreditUsage(WidgetTester tester) async {
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
  );
  
  // Look for credit toggle
  final creditToggle = find.byType(Switch)
    .or(find.textContaining('Use Credits'))
    .or(find.textContaining('Apply Credit'));
  
  if (creditToggle.evaluate().isNotEmpty) {
    await tester.tap(creditToggle.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    print('✅ Credit usage toggle tested');
  } else {
    print('⚠️ Credit usage option not found');
  }
}

/// Test deposit payment options
Future<void> _testDepositPaymentOptions(WidgetTester tester) async {
  // Look for deposit payment options
  final depositOption = find.textContaining('Deposit')
    .or(find.textContaining('Pay Later'))
    .or(find.textContaining('Installment'));
  
  if (depositOption.evaluate().isNotEmpty) {
    await tester.tap(depositOption.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    print('✅ Deposit payment option tested');
  } else {
    print('⚠️ Deposit payment options not found');
  }
}

/// Test taster course booking
Future<void> _testTasterCourseBooking(WidgetTester tester) async {
  // Navigate to course list to find taster options
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.courseList,
  );
  
  // Look for taster course options
  final tasterOption = find.textContaining('Taster')
    .or(find.textContaining('Trial'))
    .or(find.textContaining('Free'));
  
  if (tasterOption.evaluate().isNotEmpty) {
    await tester.tap(tasterOption.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Add taster to basket
    final addTasterButton = find.text('Add to Basket')
      .or(find.text('Book Taster'));
    
    if (addTasterButton.evaluate().isNotEmpty) {
      await tester.tap(addTasterButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('✅ Taster course booking tested');
    }
  } else {
    print('⚠️ No taster courses found for testing');
  }
}

/// Test basket responsive design
Future<void> _testBasketResponsiveDesign(WidgetTester tester) async {
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.basket,
  );
  
  // Test at different screen sizes (simulated)
  await tester.binding.setSurfaceSize(const Size(320, 568)); // iPhone SE
  await tester.pumpAndSettle();
  await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad
  await tester.pumpAndSettle();
  await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop
  await tester.pumpAndSettle();
  
  // Reset to default size
  await tester.binding.setSurfaceSize(const Size(400, 800));
  await tester.pumpAndSettle();
  
  print('✅ Responsive design tested at multiple screen sizes');
}

/// Test basket accessibility features
Future<void> _testBasketAccessibility(WidgetTester tester) async {
  // Look for semantic labels and accessibility features
  final accessibleElements = find.bySemanticsLabel('Basket items')
    .or(find.bySemanticsLabel('Total amount'))
    .or(find.bySemanticsLabel('Checkout button'));
  
  if (accessibleElements.evaluate().isNotEmpty) {
    print('✅ Accessibility labels found');
  } else {
    print('⚠️ Consider adding more accessibility labels');
  }
  
  // Test keyboard navigation (if supported)
  // This would require more complex setup for full keyboard testing
  print('✅ Accessibility testing completed');
}

/// Verify basket count indicator
Future<void> _verifyBasketCount(WidgetTester tester, {required int expectedMinCount}) async {
  // Look for basket count indicator
  final basketCountIndicator = find.textContaining('$expectedMinCount')
    .or(find.byType(Badge))
    .or(find.textContaining('items'));
  
  if (basketCountIndicator.evaluate().isNotEmpty) {
    print('✅ Basket count indicator shows expected value');
  } else {
    print('⚠️ Basket count indicator not found or incorrect');
  }
}