import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// End-to-end smoke test that covers the complete user journey
/// This test runs through: Login → Browse → Add to Basket → Checkout
class E2ESmokeTest extends BaseIntegrationTest 
    with AuthenticatedTest, BasketTest, PerformanceTest {
  
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      await BackendHealthCheck.ensureBackendReady();
    });

    group('E2E Smoke Test', () {
      testIntegration(
        'should complete full user journey from login to checkout',
        (tester) async {
          await measurePerformance('full_e2e_journey', () async {
            // Step 1: Launch app
            await launchApp(tester);
            await screenshot('01_app_launch');
            
            // Step 2: Login
            print('🔐 Step 2: Logging in...');
            await loginTestUser(tester);
            await screenshot('02_after_login');
            
            // Step 3: Browse courses
            print('📚 Step 3: Browsing courses...');
            await _browseCourses(tester);
            await screenshot('03_course_browsing');
            
            // Step 4: View course details
            print('🔍 Step 4: Viewing course details...');
            await _viewCourseDetails(tester);
            await screenshot('04_course_details');
            
            // Step 5: Add to basket
            print('🛒 Step 5: Adding to basket...');
            await _addCourseToBasket(tester);
            await screenshot('05_after_add_to_basket');
            
            // Step 6: Go to basket
            print('🛍️ Step 6: Viewing basket...');
            await navigateToBasket(tester);
            await screenshot('06_basket_view');
            
            // Step 7: Proceed to checkout
            print('💳 Step 7: Starting checkout...');
            await _proceedToCheckout(tester);
            await screenshot('07_checkout_started');
            
            // Step 8: Complete checkout (mock)
            print('✅ Step 8: Completing order...');
            await _completeCheckout(tester);
            await screenshot('08_order_complete');
          });
          
          // Verify final state
          print('🎉 E2E test completed successfully!');
        },
        timeout: const Timeout(Duration(minutes: 5)),
      );
    });

    tearDownAll(() {
      printPerformanceReport();
    });
  }
  
  Future<void> _browseCourses(WidgetTester tester) async {
    // Wait for courses to load
    await TestHelpers.waitForNetworkIdle(tester);
    
    // Should see course groups or navigation
    final courseGroupsScreen = find.byKey(const Key('course-discovery-screen'));
    final browseCoursesButton = find.text('Browse Courses');
    final coursesNavItem = find.text('Courses');
    
    // Navigate to courses if needed
    if (browseCoursesButton.evaluate().isNotEmpty) {
      await tester.tap(browseCoursesButton);
      await TestHelpers.waitForAnimations(tester);
    } else if (coursesNavItem.evaluate().isNotEmpty) {
      await tester.tap(coursesNavItem);
      await TestHelpers.waitForAnimations(tester);
    }
    
    // Wait for course groups to load
    await TestHelpers.waitForNetworkIdle(tester);
    
    // Verify course groups are displayed
    expect(
      find.byKey(const Key('course-group-card')).evaluate().isNotEmpty ||
      find.textContaining('Ballet').evaluate().isNotEmpty ||
      find.textContaining('Dance').evaluate().isNotEmpty,
      isTrue,
      reason: 'Should display course groups',
    );
  }
  
  Future<void> _viewCourseDetails(WidgetTester tester) async {
    // Find and tap first course group
    final courseGroupCards = find.byKey(const Key('course-group-card'));
    
    if (courseGroupCards.evaluate().isEmpty) {
      // Try alternative finders
      final courseCards = find.byType(Card);
      if (courseCards.evaluate().isNotEmpty) {
        await tester.tap(courseCards.first);
      }
    } else {
      await tester.tap(courseGroupCards.first);
    }
    
    await TestHelpers.waitForAnimations(tester);
    await TestHelpers.waitForNetworkIdle(tester);
    
    // Should be on course group detail screen
    expect(
      find.byKey(const Key('course-group-detail-screen')).evaluate().isNotEmpty ||
      find.text('Course Details').evaluate().isNotEmpty ||
      find.text('Add to Basket').evaluate().isNotEmpty,
      isTrue,
      reason: 'Should show course details',
    );
  }
  
  Future<void> _addCourseToBasket(WidgetTester tester) async {
    // Find add to basket button
    final addToBasketButtons = find.text('Add to Basket');
    
    if (addToBasketButtons.evaluate().isEmpty) {
      // Try alternative text
      final bookNowButtons = find.text('Book Now');
      if (bookNowButtons.evaluate().isNotEmpty) {
        await tester.tap(bookNowButtons.first);
      }
    } else {
      await tester.tap(addToBasketButtons.first);
    }
    
    await tester.pump();
    
    // Handle any dialogs (payment options, etc.)
    await _handlePaymentOptionsDialog(tester);
    
    // Wait for basket update
    await TestHelpers.waitForAnimations(tester);
    
    // Verify basket count updated
    final basketCount = await getBasketItemCount(tester);
    expect(basketCount, greaterThan(0), reason: 'Basket should have items');
  }
  
  Future<void> _handlePaymentOptionsDialog(WidgetTester tester) async {
    // Check if payment options dialog appears
    await tester.pump(const Duration(milliseconds: 500));
    
    final fullPriceOption = find.text('Full Price');
    final confirmButton = find.text('Confirm');
    final addButton = find.text('Add');
    
    if (fullPriceOption.evaluate().isNotEmpty) {
      await tester.tap(fullPriceOption);
      await tester.pump();
    }
    
    if (confirmButton.evaluate().isNotEmpty) {
      await tester.tap(confirmButton);
    } else if (addButton.evaluate().isNotEmpty) {
      await tester.tap(addButton);
    }
    
    await TestHelpers.waitForAnimations(tester);
  }
  
  Future<void> _proceedToCheckout(WidgetTester tester) async {
    // Should be on basket screen
    expect(
      find.byKey(const Key('basket-screen')),
      findsOneWidget,
      reason: 'Should be on basket screen',
    );
    
    // Find checkout button
    final checkoutButton = find.text('Checkout');
    final proceedButton = find.text('Proceed to Checkout');
    
    if (checkoutButton.evaluate().isNotEmpty) {
      await tester.tap(checkoutButton);
    } else if (proceedButton.evaluate().isNotEmpty) {
      await tester.tap(proceedButton);
    }
    
    await TestHelpers.waitForAnimations(tester);
    
    // Should be on checkout screen
    expect(
      find.byKey(const Key('checkout-screen')).evaluate().isNotEmpty ||
      find.text('Review Order').evaluate().isNotEmpty ||
      find.text('Order Summary').evaluate().isNotEmpty,
      isTrue,
      reason: 'Should be on checkout screen',
    );
  }
  
  Future<void> _completeCheckout(WidgetTester tester) async {
    // This is a mock checkout - just verify we can navigate through steps
    
    // Step 1: Review order (usually automatic)
    await tester.pump(const Duration(seconds: 1));
    
    // Step 2: Payment method
    final continueButton = find.text('Continue');
    final nextButton = find.text('Next');
    
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton);
      await TestHelpers.waitForAnimations(tester);
    } else if (nextButton.evaluate().isNotEmpty) {
      await tester.tap(nextButton);
      await TestHelpers.waitForAnimations(tester);
    }
    
    // Select payment method if needed
    final paymentMethodOption = find.text('Credit Card');
    if (paymentMethodOption.evaluate().isNotEmpty) {
      await tester.tap(paymentMethodOption);
      await tester.pump();
    }
    
    // Continue to next step
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton);
      await TestHelpers.waitForAnimations(tester);
    }
    
    // Step 3: Billing address (might be pre-filled)
    // Continue if button available
    if (continueButton.evaluate().isNotEmpty) {
      await tester.tap(continueButton);
      await TestHelpers.waitForAnimations(tester);
    }
    
    // Final: Place order (mock)
    final placeOrderButton = find.text('Place Order');
    final completeButton = find.text('Complete Order');
    
    if (placeOrderButton.evaluate().isNotEmpty) {
      print('📦 Placing order (mock)...');
      // Don't actually place order in test
    } else if (completeButton.evaluate().isNotEmpty) {
      print('📦 Completing order (mock)...');
      // Don't actually complete order in test
    }
    
    // For now, just verify we reached the final step
    expect(
      placeOrderButton.evaluate().isNotEmpty ||
      completeButton.evaluate().isNotEmpty ||
      find.text('Order Confirmation').evaluate().isNotEmpty,
      isTrue,
      reason: 'Should reach order placement step',
    );
  }
}

// Test runner
void main() {
  E2ESmokeTest().main();
}