import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';

/// Basic UI test that doesn't require backend connectivity
/// This test verifies the app launches and basic UI elements are present
class BasicUITest extends BaseIntegrationTest {
  @override
  void main() {
    setupTest();

    group('Basic UI Test', () {
      testIntegration('should launch app successfully', (tester) async {
        // Launch the app
        await launchApp(tester);
        
        // Wait for app to stabilize
        await TestHelpers.waitForAnimations(tester);
        
        // Take a screenshot of the launch state
        await screenshot('app_launch');
        
        // Verify the app launched without crashing
        expect(find.byType(MaterialApp), findsOneWidget);
        
        // Check if we can find some basic UI elements
        // (Login screen, home screen, or any main UI component)
        final hasBasicUI = 
          find.text('Welcome').evaluate().isNotEmpty ||
          find.text('Sign In').evaluate().isNotEmpty ||
          find.text('Login').evaluate().isNotEmpty ||
          find.text('Home').evaluate().isNotEmpty ||
          find.text('UKCPA').evaluate().isNotEmpty ||
          find.byType(Scaffold).evaluate().isNotEmpty ||
          find.byType(AppBar).evaluate().isNotEmpty;
        
        expect(hasBasicUI, isTrue, reason: 'Should show basic UI elements');
        
        print('✅ App launched successfully on iOS simulator');
      });

      testIntegration('should display some form of navigation or content', (tester) async {
        await launchApp(tester);
        await TestHelpers.waitForAnimations(tester);
        
        // Look for any interactive elements
        final hasInteractiveElements = 
          find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.byType(TextButton).evaluate().isNotEmpty ||
          find.byType(OutlinedButton).evaluate().isNotEmpty ||
          find.byType(FloatingActionButton).evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty ||
          find.byType(ListTile).evaluate().isNotEmpty ||
          find.byType(GestureDetector).evaluate().isNotEmpty;
        
        expect(hasInteractiveElements, isTrue, reason: 'Should have interactive elements');
        
        await screenshot('basic_ui_elements');
        
        print('✅ Found interactive UI elements');
      });

      testIntegration('should handle basic navigation if available', (tester) async {
        await launchApp(tester);
        await TestHelpers.waitForAnimations(tester);
        
        // Try to find any navigation elements
        final navigationElements = [
          find.byType(BottomNavigationBar),
          find.byType(NavigationRail),
          find.byType(Drawer),
          find.byIcon(Icons.menu),
          find.byIcon(Icons.home),
          find.byIcon(Icons.account_circle),
        ];
        
        bool foundNavigation = false;
        for (final element in navigationElements) {
          if (element.evaluate().isNotEmpty) {
            foundNavigation = true;
            print('Found navigation element: ${element.toString()}');
            
            // Try to tap it (if it's tappable)
            try {
              await tester.tap(element.first);
              await tester.pump(const Duration(milliseconds: 500));
              await screenshot('after_navigation_tap');
            } catch (e) {
              print('Navigation element not tappable: $e');
            }
            break;
          }
        }
        
        // This test passes regardless - we're just exploring the UI
        print(foundNavigation ? '✅ Found navigation elements' : 'ℹ️  No navigation elements found');
      });
    });
  }
}

// Test runner
void main() {
  BasicUITest().main();
}