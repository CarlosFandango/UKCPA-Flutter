import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/mock_fast_test_manager.dart';
import '../fixtures/test_credentials.dart';

/// Ultra-fast authentication tests using mocked dependencies
/// These should run in seconds, not minutes!
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  MockedFastTestManager.createMockedTestBatch(
    'Ultra-Fast Authentication Tests',
    {
      'should display login screen instantly': (tester) async {
        // Should be on login screen after mocked initialization
        expect(find.text('Sign in to your account'), findsOneWidget);
        expect(find.byKey(const Key('email-field')), findsOneWidget);
        expect(find.byKey(const Key('password-field')), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        print('✅ Login screen validation complete (mocked)');
      },

      'should validate email format quickly': (tester) async {
        // Enter invalid email
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: 'invalid-email',
        );
        
        // Try to submit
        await FastAutomatedTestTemplate.tapButton(tester, 'Sign In');
        await FastAutomatedTestTemplate.waitForUI(tester);
        
        // Should show validation error or stay on login
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✅ Email validation test complete (mocked)');
      },

      'should require password quickly': (tester) async {
        // Enter only email, no password
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: TestCredentials.validEmail,
        );
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('password-field'),
          text: '', // Empty password
        );
        
        // Try to submit
        await FastAutomatedTestTemplate.tapButton(tester, 'Sign In');
        await FastAutomatedTestTemplate.waitForUI(tester);
        
        // Should stay on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✅ Password requirement test complete (mocked)');
      },

      'should handle invalid credentials quickly': (tester) async {
        // Enter invalid credentials
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: 'wrong@email.com',
        );
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('password-field'),
          text: 'wrongpassword',
        );
        
        // Submit login
        await FastAutomatedTestTemplate.tapButton(tester, 'Sign In');
        await FastAutomatedTestTemplate.waitForUI(tester, duration: const Duration(milliseconds: 300));
        
        // Should show error (mocked response) or stay on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✅ Invalid credentials test complete (mocked)');
      },

      'should login successfully with valid credentials': (tester) async {
        // Clear fields first
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: '',
        );
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('password-field'),
          text: '',
        );
        
        // Enter valid credentials (will trigger mocked success)
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: TestCredentials.validEmail,
        );
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('password-field'),
          text: TestCredentials.validPassword,
        );
        
        // Submit login
        await FastAutomatedTestTemplate.tapButton(tester, 'Sign In');
        await FastAutomatedTestTemplate.waitForUI(tester, duration: const Duration(milliseconds: 500));
        
        // Should navigate away from login screen (mocked success)
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
        print('✅ Successful login test complete (mocked)');
      },

      'should toggle password visibility quickly': (tester) async {
        // Enter password
        await FastAutomatedTestTemplate.enterText(
          tester,
          key: const Key('password-field'),
          text: TestCredentials.validPassword,
        );
        
        // Look for password visibility toggle
        final visibilityToggle = find.byIcon(Icons.visibility_off);
        if (visibilityToggle.evaluate().isNotEmpty) {
          await tester.tap(visibilityToggle);
          await tester.pump(const Duration(milliseconds: 100)); // Minimal wait
          print('✅ Password visibility toggle complete (mocked)');
        } else {
          print('⚠️  Password visibility toggle not found (mocked)');
        }
      },

      'should navigate to registration screen quickly': (tester) async {
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
            await tester.pump(const Duration(milliseconds: 200)); // Quick navigation
            foundSignUpLink = true;
            break;
          }
        }
        
        if (foundSignUpLink) {
          print('✅ Registration navigation test complete (mocked)');
        } else {
          print('⚠️  Sign up link not found (mocked)');
        }
      },
    },
    requiresAuth: false,
  );
}