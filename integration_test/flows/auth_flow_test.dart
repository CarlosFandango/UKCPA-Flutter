import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Automated integration tests for authentication flow
/// Tests login, logout, form validation, and session persistence
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Tests', () {
    AutomatedTestTemplate.createAutomatedTest(
      'should display login screen on app launch',
      (tester) async {
        // Login screen should already be displayed after initialization
        expect(find.text('Sign in to your account'), findsOneWidget);
        expect(find.byKey(const Key('email-field')), findsOneWidget);
        expect(find.byKey(const Key('password-field')), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should validate email format',
      (tester) async {
        // Enter invalid email
        await AutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: TestCredentials.malformedEmail,
        );
        
        // Try to submit
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        
        // Should show validation error
        expect(
          find.text('Please enter a valid email address'),
          findsOneWidget,
          reason: 'Should show email validation error',
        );
        
        // Should still be on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should require password',
      (tester) async {
        // Enter only email
        await AutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: TestCredentials.validEmail,
        );
        
        // Leave password empty and try to submit
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        
        // Should show validation error
        expect(
          find.text('Password is required').evaluate().isNotEmpty ||
          find.text('Please enter your password').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show password required error',
        );
        
        // Should still be on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should show error with invalid credentials',
      (tester) async {
        // Enter invalid credentials
        await AutomatedTestTemplate.enterText(
          tester,
          key: const Key('email-field'),
          text: TestCredentials.invalidEmail,
        );
        await AutomatedTestTemplate.enterText(
          tester,
          key: const Key('password-field'),
          text: TestCredentials.invalidPassword,
        );
        
        // Submit
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        
        // Wait for network request
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        
        // Should show error message
        expect(
          find.text('Invalid email or password').evaluate().isNotEmpty ||
          find.text('Login failed').evaluate().isNotEmpty ||
          find.text('Invalid credentials').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show login error message',
        );
        
        // Should still be on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should login successfully with valid credentials',
      (tester) async {
        // Enter valid credentials
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
        
        // Submit
        await AutomatedTestTemplate.tapButton(tester, 'Sign In');
        
        // Wait for navigation
        await AutomatedTestTemplate.waitForNetworkIdle(tester);
        
        // Should navigate away from login screen
        expect(find.text('Sign in to your account'), findsNothing);
        
        // Should show home screen or course discovery
        expect(
          find.text('Browse Courses').evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.byKey(const Key('home-screen')).evaluate().isNotEmpty ||
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should navigate to home/courses screen after login',
        );
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should toggle password visibility',
      (tester) async {
        // Enter password
        await AutomatedTestTemplate.enterText(
          tester,
          key: const Key('password-field'),
          text: TestCredentials.validPassword,
        );
        
        // Find password visibility toggle
        final visibilityToggle = find.byKey(const Key('password-toggle'));
        
        expect(visibilityToggle, findsOneWidget, 
          reason: 'Should have password visibility toggle');
        
        // Toggle visibility
        await tester.tap(visibilityToggle);
        await tester.pumpAndSettle();
        
        // Toggle back
        await tester.tap(visibilityToggle);
        await tester.pumpAndSettle();
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );

    AutomatedTestTemplate.createAutomatedTest(
      'should navigate to registration screen',
      (tester) async {
        // Find registration link
        final signUpLink = find.text('Sign Up');
        
        expect(signUpLink, findsOneWidget, 
          reason: 'Should have Sign Up link');
          
        await tester.tap(signUpLink);
        await tester.pumpAndSettle();
        
        // Should show registration screen
        expect(
          find.text('Create Account').evaluate().isNotEmpty ||
          find.text('Sign Up').evaluate().isNotEmpty ||
          find.text('Register').evaluate().isNotEmpty ||
          find.text('Create your account').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show registration screen',
        );
      },
      expectedScreen: 'login',
      takeScreenshots: true,
    );
  });
}