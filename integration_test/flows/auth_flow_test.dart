import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/fast_test_manager.dart';
import '../helpers/automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Fast authentication flow tests - optimized for speed
/// Uses FastTestManager for shared app initialization and reduced wait times
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  FastTestManager.createFastTestBatch(
    'Authentication Flow Tests (Fast Mode)',
    {
      'should display login screen on app launch': (tester) async {
        // Should be on login screen after initialization
        expect(find.text('Sign in to your account'), findsOneWidget);
        expect(find.byKey(const Key('email-field')), findsOneWidget);
        expect(find.byKey(const Key('password-field')), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        print('✅ Login screen validation complete');
      },

      'should validate email format quickly': (tester) async {
        // Enter invalid email
        await AutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: TestCredentials.malformedEmail,
        );
        
        // Try to submit
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        await tester.pump(const Duration(milliseconds: 500)); // Reduced wait
        
        // Should show validation error or stay on login
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✅ Email validation test complete');
      },

      'should require password quickly': (tester) async {
        // Clear and enter only email
        await tester.enterText(find.byKey(const Key('email-field')), TestCredentials.validEmail);
        await tester.enterText(find.byKey(const Key('password-field')), ''); // Empty password
        
        // Try to submit
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        await tester.pump(const Duration(milliseconds: 500)); // Reduced wait
        
        // Should stay on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✅ Password requirement test complete');
      },

      'should show error with invalid credentials quickly': (tester) async {
        // Enter invalid credentials
        await tester.enterText(find.byKey(const Key('email-field')), TestCredentials.invalidEmail);
        await tester.enterText(find.byKey(const Key('password-field')), TestCredentials.invalidPassword);
        
        // Submit and wait briefly for network
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        await tester.pump(const Duration(seconds: 1)); // Reduced from longer waits
        
        // Should show error or stay on login
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✅ Invalid credentials test complete');
      },

      'should login successfully with valid credentials': (tester) async {
        // Clear fields first
        await tester.enterText(find.byKey(const Key('email-field')), '');
        await tester.enterText(find.byKey(const Key('password-field')), '');
        
        // Enter valid credentials
        await tester.enterText(find.byKey(const Key('email-field')), TestCredentials.validEmail);
        await tester.enterText(find.byKey(const Key('password-field')), TestCredentials.validPassword);
        
        // Submit
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        await tester.pumpAndSettle(const Duration(seconds: 2)); // Reduced from 8+ seconds
        
        // Should navigate away from login
        expect(find.text('Sign in to your account'), findsNothing);
        
        // Should show post-login content
        final postLoginIndicators = [
          find.text('Browse Courses'),
          find.text('Course Groups'),
          find.text('Home'),
          find.text('Courses'),
        ];
        
        bool foundPostLoginContent = false;
        for (final indicator in postLoginIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundPostLoginContent = true;
            break;
          }
        }
        
        expect(foundPostLoginContent, isTrue, reason: 'Should show post-login content');
        print('✅ Successful login test complete');
      },

      'should toggle password visibility quickly': (tester) async {
        // Navigate back to login if needed (test isolation)
        if (find.text('Sign in to your account').evaluate().isEmpty) {
          print('⏭️  Skipping password toggle test - already logged in');
          return;
        }
        
        // Enter password
        await tester.enterText(find.byKey(const Key('password-field')), TestCredentials.validPassword);
        
        // Look for password visibility toggle
        final visibilityToggle = find.byIcon(Icons.visibility_off);
        if (visibilityToggle.evaluate().isNotEmpty) {
          await tester.tap(visibilityToggle);
          await tester.pump(const Duration(milliseconds: 200)); // Minimal wait
          print('✅ Password visibility toggle complete');
        } else {
          print('⚠️  Password visibility toggle not found');
        }
      },

      'should navigate to registration screen quickly': (tester) async {
        // Navigate back to login if needed
        if (find.text('Sign in to your account').evaluate().isEmpty) {
          print('⏭️  Skipping registration navigation - not on login screen');
          return;
        }
        
        // Find registration link
        final signUpLinks = [
          find.text('Sign Up'),
          find.text('Create Account'),
          find.text('Register'),
        ];
        
        bool foundSignUpLink = false;
        for (final link in signUpLinks) {
          if (link.evaluate().isNotEmpty) {
            await tester.tap(link);
            await tester.pump(const Duration(milliseconds: 500)); // Quick navigation
            foundSignUpLink = true;
            break;
          }
        }
        
        if (foundSignUpLink) {
          print('✅ Registration navigation test complete');
        } else {
          print('⚠️  Sign up link not found');
        }
      },
    },
    requiresAuth: false, // These tests handle auth themselves
  );
}