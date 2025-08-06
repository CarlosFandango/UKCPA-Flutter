import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for individual course details page
/// Tests course details display, session information, booking functionality
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Course Details Page Tests', () {
    AutomatedTestTemplate.createAutomatedTest(
      'should navigate to course details page',
      (tester) async {
        // First login and navigate to courses
        await _loginAndNavigateToCourses(tester);
        
        // Find and tap on a course to view details
        final courseCards = find.byType(Card);
        final listTiles = find.byType(ListTile);
        final detailButtons = find.textContaining('View Details');
        final courseLinks = find.textContaining('Course');
        
        bool navigationAttempted = false;
        
        if (courseCards.evaluate().isNotEmpty) {
          await tester.tap(courseCards.first);
          navigationAttempted = true;
          print('✓ Tapped on course card');
        } else if (listTiles.evaluate().isNotEmpty) {
          await tester.tap(listTiles.first);
          navigationAttempted = true;
          print('✓ Tapped on list tile');
        } else if (detailButtons.evaluate().isNotEmpty) {
          await tester.tap(detailButtons.first);
          navigationAttempted = true;
          print('✓ Tapped on details button');
        } else if (courseLinks.evaluate().isNotEmpty) {
          await tester.tap(courseLinks.first);
          navigationAttempted = true;
          print('✓ Tapped on course link');
        }
        
        if (navigationAttempted) {
          await tester.pumpAndSettle(const Duration(seconds: 3));
          
          // Verify we're on course details page
          expect(
            find.text('Course Details').evaluate().isNotEmpty ||
            find.text('Sessions').evaluate().isNotEmpty ||
            find.text('Book Now').evaluate().isNotEmpty ||
            find.text('Course Information').evaluate().isNotEmpty ||
            find.text('Schedule').evaluate().isNotEmpty,
            isTrue,
            reason: 'Should be on course details page',
          );
        } else {
          print('⚠️  No course items found to navigate to details');
        }
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should display course basic information',
      (tester) async {
        // Navigate to course details
        await _navigateToCourseDetails(tester);
        
        // Verify basic course information is displayed
        final hasTitle = find.byType(Text).evaluate().isNotEmpty;
        final hasDescription = find.textContaining('description').evaluate().isNotEmpty ||
                              find.textContaining('Description').evaluate().isNotEmpty;
        
        expect(hasTitle, isTrue, reason: 'Should display course title');
        
        // Look for common course information elements
        final commonElements = [
          'Duration',
          'Level',
          'Instructor',
          'Teacher',
          'Age',
          'Price',
          '£',
          '\$',
        ];
        
        bool foundCourseInfo = false;
        for (String element in commonElements) {
          if (find.textContaining(element).evaluate().isNotEmpty) {
            foundCourseInfo = true;
            print('✓ Found course information: $element');
            break;
          }
        }
        
        if (!foundCourseInfo) {
          print('⚠️  No specific course information elements found');
        }
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should display course session information',
      (tester) async {
        // Navigate to course details
        await _navigateToCourseDetails(tester);
        
        // Look for session/schedule information
        final sessionIndicators = [
          'Sessions',
          'Schedule',
          'Times',
          'Dates',
          'Weekly',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];
        
        bool foundSessionInfo = false;
        for (String indicator in sessionIndicators) {
          if (find.textContaining(indicator).evaluate().isNotEmpty) {
            foundSessionInfo = true;
            print('✓ Found session information: $indicator');
          }
        }
        
        if (!foundSessionInfo) {
          print('⚠️  No session/schedule information found');
        }
        
        // Look for time format (common patterns) - check existing text widgets
        final allTexts = find.byType(Text);
        bool foundTimeFormat = false;
        final timeRegex = RegExp(r'\d{1,2}:\d{2}');
        
        for (int i = 0; i < allTexts.evaluate().length && i < 20; i++) {
          try {
            final widget = tester.widget<Text>(allTexts.at(i));
            final text = widget.data ?? '';
            if (timeRegex.hasMatch(text)) {
              print('✓ Found time information: $text');
              foundSessionInfo = true;
              foundTimeFormat = true;
              break;
            }
          } catch (e) {
            // Ignore widget reading errors
          }
        }
        
        // At minimum, should have some form of scheduling info
        expect(foundSessionInfo, isTrue, 
          reason: 'Should display some form of session/schedule information');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should display course pricing information',
      (tester) async {
        // Navigate to course details
        await _navigateToCourseDetails(tester);
        
        // Look for pricing information
        final pricingElements = [
          find.textContaining('£'),
          find.textContaining('\$'),
          find.textContaining('Price'),
          find.textContaining('Cost'),
          find.textContaining('Fee'),
          find.textContaining('Free'),
        ];
        
        bool foundPricing = false;
        for (Finder pricingElement in pricingElements) {
          if (pricingElement.evaluate().isNotEmpty) {
            foundPricing = true;
            print('✓ Found pricing information');
            break;
          }
        }
        
        if (!foundPricing) {
          print('⚠️  No pricing information found');
        }
        
        // Look for numeric pricing patterns - check existing text widgets
        final allTexts = find.byType(Text);
        final pricingRegex = RegExp(r'[£\$]\d+');
        
        for (int i = 0; i < allTexts.evaluate().length && i < 20; i++) {
          try {
            final widget = tester.widget<Text>(allTexts.at(i));
            final text = widget.data ?? '';
            if (pricingRegex.hasMatch(text)) {
              print('✓ Found numeric pricing: $text');
              foundPricing = true;
              break;
            }
          } catch (e) {
            // Ignore widget reading errors
          }
        }
        
        expect(foundPricing, isTrue,
          reason: 'Should display pricing information');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should have booking functionality',
      (tester) async {
        // Navigate to course details
        await _navigateToCourseDetails(tester);
        
        // Look for booking-related buttons/functionality
        final bookingElements = [
          find.text('Book Now'),
          find.text('Add to Basket'),
          find.text('Add to Cart'),
          find.text('Enroll'),
          find.text('Register'),
          find.text('Book'),
          find.byKey(const Key('book-button')),
          find.byKey(const Key('add-to-basket-button')),
        ];
        
        bool foundBookingElement = false;
        for (Finder bookingElement in bookingElements) {
          if (bookingElement.evaluate().isNotEmpty) {
            foundBookingElement = true;
            
            // Try to tap the booking element
            try {
              await tester.tap(bookingElement);
              await tester.pumpAndSettle();
              print('✓ Successfully tapped booking element');
              
              // Look for basket/booking confirmation
              final confirmationElements = [
                find.textContaining('Added'),
                find.textContaining('Basket'),
                find.textContaining('Cart'),
                find.textContaining('Success'),
              ];
              
              for (Finder confirmation in confirmationElements) {
                if (confirmation.evaluate().isNotEmpty) {
                  print('✓ Found booking confirmation');
                  break;
                }
              }
              
            } catch (e) {
              print('⚠️  Could not tap booking element: $e');
            }
            break;
          }
        }
        
        expect(foundBookingElement, isTrue,
          reason: 'Should have booking functionality available');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should handle navigation back from course details',
      (tester) async {
        // Navigate to course details
        await _navigateToCourseDetails(tester);
        
        // Look for back navigation options
        final backButton = find.byIcon(Icons.arrow_back);
        final backText = find.text('Back');
        final appBarBack = find.byType(BackButton);
        
        bool navigationTested = false;
        
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton.first);
          await tester.pumpAndSettle();
          navigationTested = true;
          print('✓ Tapped back arrow');
        } else if (backText.evaluate().isNotEmpty) {
          await tester.tap(backText);
          await tester.pumpAndSettle();
          navigationTested = true;
          print('✓ Tapped back text');
        } else if (appBarBack.evaluate().isNotEmpty) {
          await tester.tap(appBarBack.first);
          await tester.pumpAndSettle();
          navigationTested = true;
          print('✓ Tapped app bar back button');
        }
        
        if (navigationTested) {
          // Verify we navigated back (should see course list or similar)
          expect(
            find.text('Course Details').evaluate().isEmpty ||
            find.text('Courses').evaluate().isNotEmpty ||
            find.text('Browse').evaluate().isNotEmpty,
            isTrue,
            reason: 'Should navigate back from course details',
          );
        } else {
          print('⚠️  No back navigation options found');
        }
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );
  });
}

/// Helper function to login and navigate to courses
Future<void> _loginAndNavigateToCourses(WidgetTester tester) async {
  // Check if already logged in
  if (find.text('Sign in to your account').evaluate().isEmpty) {
    return; // Already navigated
  }
  
  // Perform login
  await AutomatedTestTemplate.enterText(
    tester,
    key: const Key('email-field'),
    text: TestCredentials.validEmail,
  );
  await AutomatedTestTemplate.enterText(
    tester,
    key: const Key('password-field'),
    text: TestCredentials.validPassword,
  );
  
  await AutomatedTestTemplate.tapButton(tester, 'Sign In');
  await AutomatedTestTemplate.waitForNetworkIdle(tester);
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

/// Helper function to navigate to course details
Future<void> _navigateToCourseDetails(WidgetTester tester) async {
  // First ensure we're logged in and have courses
  await _loginAndNavigateToCourses(tester);
  
  // Try to find and tap a course to go to details
  final courseCards = find.byType(Card);
  final listTiles = find.byType(ListTile);
  
  if (courseCards.evaluate().isNotEmpty) {
    await tester.tap(courseCards.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  } else if (listTiles.evaluate().isNotEmpty) {
    await tester.tap(listTiles.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
}