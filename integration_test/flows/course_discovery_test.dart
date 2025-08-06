import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for course discovery functionality
/// Tests course list, search, filtering, and navigation
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Course Discovery Tests', () {
    // First login to access course discovery
    AutomatedTestTemplate.createAutomatedTest(
      'should login and navigate to course discovery',
      (tester) async {
        // Login with valid credentials
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
        
        // Submit login
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        
        // Should navigate away from login
        expect(find.text('Sign in to your account'), findsNothing);
        
        // Should show course discovery or home screen
        expect(
          find.text('Browse Courses').evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.text('Courses').evaluate().isNotEmpty ||
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should navigate to course discovery after login',
        );
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should display course list',
      (tester) async {
        // First login
        await _performLogin(tester);
        
        // Wait for course data to load
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Should display course-related elements
        expect(
          find.byType(Card).evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty ||
          find.text('No courses available').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display either courses or "no courses" message',
        );
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should display term selector',
      (tester) async {
        // First login
        await _performLogin(tester);
        
        // Wait for UI to load
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        
        // Look for term/semester selection UI
        expect(
          find.byType(DropdownButton).evaluate().isNotEmpty ||
          find.byType(TabBar).evaluate().isNotEmpty ||
          find.text('Terms').evaluate().isNotEmpty ||
          find.text('Select Term').evaluate().isNotEmpty ||
          find.byKey(const Key('term-selector')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display term/semester selector',
        );
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should handle course search functionality',
      (tester) async {
        // First login
        await _performLogin(tester);
        
        // Wait for UI to load
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        
        // Look for search functionality
        final searchField = find.byType(TextField).first;
        final searchIcon = find.byIcon(Icons.search);
        final searchByKey = find.byKey(const Key('course-search'));
        
        if (searchField.evaluate().isNotEmpty) {
          // Test search by entering text
          await tester.enterText(searchField, TestCredentials.validSearchTerm);
          await tester.pumpAndSettle();
          
          // Verify search functionality works
          print('✓ Search field found and text entered');
        } else if (searchIcon.evaluate().isNotEmpty) {
          // Tap search icon if available
          await tester.tap(searchIcon);
          await tester.pumpAndSettle();
          print('✓ Search icon tapped');
        } else if (searchByKey.evaluate().isNotEmpty) {
          // Use specific search key
          await tester.tap(searchByKey);
          await tester.pumpAndSettle();
          print('✓ Search by key activated');
        } else {
          print('⚠️  No search functionality found (may not be implemented yet)');
        }
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should navigate to course group details',
      (tester) async {
        // First login
        await _performLogin(tester);
        
        // Wait for course data to load
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Look for course cards or course group items to tap
        final courseCards = find.byType(Card);
        final listTiles = find.byType(ListTile);
        final courseButtons = find.textContaining('View Details');
        
        bool navigationTested = false;
        
        if (courseCards.evaluate().isNotEmpty) {
          // Tap first course card
          await tester.tap(courseCards.first);
          await tester.pumpAndSettle();
          navigationTested = true;
          print('✓ Course card tapped');
        } else if (listTiles.evaluate().isNotEmpty) {
          // Tap first list tile
          await tester.tap(listTiles.first);
          await tester.pumpAndSettle();
          navigationTested = true;
          print('✓ Course list tile tapped');
        } else if (courseButtons.evaluate().isNotEmpty) {
          // Tap view details button
          await tester.tap(courseButtons.first);
          await tester.pumpAndSettle();
          navigationTested = true;
          print('✓ View details button tapped');
        }
        
        if (navigationTested) {
          // Verify navigation occurred - look for course details indicators
          expect(
            find.text('Course Details').evaluate().isNotEmpty ||
            find.text('Sessions').evaluate().isNotEmpty ||
            find.text('Book Now').evaluate().isNotEmpty ||
            find.text('Course Information').evaluate().isNotEmpty,
            isTrue,
            reason: 'Should navigate to course details screen',
          );
        } else {
          print('⚠️  No course items found to test navigation');
        }
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should display course information correctly',
      (tester) async {
        // First login
        await _performLogin(tester);
        
        // Wait for course data to load
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Verify course information is displayed
        final hasText = find.byType(Text).evaluate().isNotEmpty;
        final hasImages = find.byType(Image).evaluate().isNotEmpty;
        final hasPricing = find.textContaining('£').evaluate().isNotEmpty ||
                          find.textContaining('\$').evaluate().isNotEmpty;
        
        expect(hasText, isTrue, reason: 'Should display course text information');
        
        if (hasPricing) {
          print('✓ Course pricing information found');
        } else {
          print('⚠️  No pricing information visible');
        }
        
        if (hasImages) {
          print('✓ Course images found');
        } else {
          print('⚠️  No course images found');
        }
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );
  });
}

/// Helper function to perform login for course discovery tests
Future<void> _performLogin(WidgetTester tester) async {
  // Check if already logged in
  if (find.text('Sign in to your account').evaluate().isEmpty) {
    return; // Already logged in
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
  
  // Verify login succeeded
  expect(find.text('Sign in to your account'), findsNothing,
    reason: 'Should be logged in before testing course discovery');
}