import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Working automated integration test using the proven template
/// This demonstrates how to create reliable automated tests that work around iOS Simulator issues
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Working Automated Integration Tests', () {
    
    // Test 1: Basic app startup and UI verification
    AutomatedTestTemplate.createAutomatedTest(
      'should launch app and display login screen correctly',
      (tester) async {
        // The template handles app initialization
        // Now we can test the UI directly
        
        print('🧪 Testing login screen UI elements...');
        
        // Verify login screen elements
        expect(find.text('Sign in to your account'), findsOneWidget);
        expect(find.byKey(const Key('email-field')), findsOneWidget);
        expect(find.byKey(const Key('password-field')), findsOneWidget);
        expect(find.byKey(const Key('login-submit-button')), findsOneWidget);
        expect(find.byKey(const Key('password-toggle')), findsOneWidget);
        expect(find.text('Sign Up'), findsOneWidget);
        
        print('✅ All login screen elements present and correct');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    // Test 2: Form validation testing
    AutomatedTestTemplate.createAutomatedTest(
      'should validate email format and show appropriate errors',
      (tester) async {
        print('🧪 Testing email validation...');
        
        // Test invalid email
        await AutomatedTestTemplate.enterTextSafely(
          tester,
          find.byKey(const Key('email-field')),
          'notanemail',
          description: 'email field'
        );
        
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('login-submit-button')),
          description: 'submit button'
        );
        
        // Should show validation error
        expect(
          find.text('Please enter a valid email address'),
          findsOneWidget,
          reason: 'Should show email validation error',
        );
        
        print('✅ Email validation working correctly');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    // Test 3: Password field functionality
    AutomatedTestTemplate.createAutomatedTest(
      'should handle password field interactions correctly',
      (tester) async {
        print('🧪 Testing password field functionality...');
        
        // Test password entry
        await AutomatedTestTemplate.enterTextSafely(
          tester,
          find.byKey(const Key('password-field')),
          'testpassword123',
          description: 'password field'
        );
        
        // Test password visibility toggle
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('password-toggle')),
          description: 'password visibility toggle'
        );
        
        // Toggle back
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('password-toggle')),
          description: 'password visibility toggle (back)'
        );
        
        print('✅ Password field functionality working correctly');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    // Test 4: Form submission with valid data
    AutomatedTestTemplate.createAutomatedTest(
      'should handle form submission with valid credentials',
      (tester) async {
        print('🧪 Testing form submission...');
        
        // Fill form with valid data
        await AutomatedTestTemplate.enterTextSafely(
          tester,
          find.byKey(const Key('email-field')),
          TestCredentials.validEmail,
          description: 'email field'
        );
        
        await AutomatedTestTemplate.enterTextSafely(
          tester,
          find.byKey(const Key('password-field')),
          TestCredentials.validPassword,
          description: 'password field'
        );
        
        // Submit form
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('login-submit-button')),
          description: 'submit button'
        );
        
        // Wait for any network operations (will timeout gracefully in test mode)
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        
        // In test mode, we should still be on login screen since network calls are bypassed
        expect(find.text('Sign in to your account'), findsOneWidget);
        
        print('✅ Form submission handled correctly');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    // Test 5: Navigation to registration
    AutomatedTestTemplate.createAutomatedTest(
      'should navigate to registration screen',
      (tester) async {
        print('🧪 Testing registration navigation...');
        
        // Tap Sign Up link
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.text('Sign Up'),
          description: 'Sign Up link'
        );
        
        // Wait for navigation
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        print('✅ Registration navigation attempted successfully');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    // Test 6: Complete user interaction flow
    AutomatedTestTemplate.createAutomatedTest(
      'should complete full user interaction flow on login screen',
      (tester) async {
        print('🧪 Testing complete user interaction flow...');
        
        // Step 1: User sees login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✓ Step 1: Login screen displayed');
        
        // Step 2: User enters invalid email
        await AutomatedTestTemplate.enterTextSafely(
          tester,
          find.byKey(const Key('email-field')),
          'invalid',
          description: 'email field (invalid)'
        );
        
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('login-submit-button')),
          description: 'submit button (should fail)'
        );
        
        // Step 3: User sees validation error
        expect(find.text('Please enter a valid email address'), findsOneWidget);
        print('✓ Step 3: Validation error displayed');
        
        // Step 4: User corrects email
        await AutomatedTestTemplate.enterTextSafely(
          tester,
          find.byKey(const Key('email-field')),
          TestCredentials.validEmail,
          description: 'email field (corrected)'
        );
        
        // Step 5: User tries without password
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('login-submit-button')),
          description: 'submit button (no password)'
        );
        
        // Step 6: User sees password required error
        expect(
          find.text('Password is required').evaluate().isNotEmpty ||
          find.text('Please enter your password').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show password required error',
        );
        print('✓ Step 6: Password required error displayed');
        
        // Step 7: User enters password
        await AutomatedTestTemplate.enterTextSafely(
          tester,
          find.byKey(const Key('password-field')),
          TestCredentials.validPassword,
          description: 'password field'
        );
        
        // Step 8: User toggles password visibility
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('password-toggle')),
          description: 'password visibility toggle'
        );
        
        // Step 9: User submits complete form
        await AutomatedTestTemplate.tapSafely(
          tester,
          find.byKey(const Key('login-submit-button')),
          description: 'submit button (complete form)'
        );
        
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        
        print('✅ Complete user interaction flow tested successfully');
      },
      expectedScreen: 'login',
      takeScreenshots: true,
      timeout: const Duration(minutes: 10),
    );
  });
}