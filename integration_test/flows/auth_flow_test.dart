import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for authentication flow
/// Tests login, logout, form validation, and session persistence
class AuthFlowTest extends BaseIntegrationTest with PerformanceTest {
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      // Ensure backend is ready before running tests
      await BackendHealthCheck.ensureBackendReady();
    });

    group('Authentication Flow', () {
      testIntegration('should display login screen on app launch', (tester) async {
        await measurePerformance('app_launch', () async {
          await launchApp(tester);
        });
        
        // Verify we're on the login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        expect(find.byKey(const Key('email-field')), findsOneWidget);
        expect(find.byKey(const Key('password-field')), findsOneWidget);
        expect(find.text('Sign In'), findsOneWidget);
        
        await screenshot('login_screen');
      });

      testIntegration('should validate email format', (tester) async {
        await launchApp(tester);
        
        // Enter invalid email
        await tester.enterText(
          find.byKey(const Key('email-field')), 
          TestCredentials.malformedEmail,
        );
        await tester.pump();
        
        // Try to submit
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        
        // Should show validation error
        expect(
          find.text('Please enter a valid email address'),
          findsOneWidget,
          reason: 'Should show email validation error',
        );
        
        // Should still be on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        
        await screenshot('email_validation_error');
      });

      testIntegration('should require password', (tester) async {
        await launchApp(tester);
        
        // Enter only email
        await tester.enterText(
          find.byKey(const Key('email-field')), 
          TestCredentials.validEmail,
        );
        await tester.pump();
        
        // Leave password empty and try to submit
        await tester.tap(find.text('Sign In'));
        await tester.pump();
        
        // Should show validation error
        expect(
          find.text('Password is required')
            .evaluate().isNotEmpty ||
          find.text('Please enter your password')
            .evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show password required error',
        );
        
        // Should still be on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
      });

      testIntegration('should show error with invalid credentials', (tester) async {
        await launchApp(tester);
        
        // Enter invalid credentials
        await tester.enterText(
          find.byKey(const Key('email-field')), 
          TestCredentials.invalidEmail,
        );
        await tester.enterText(
          find.byKey(const Key('password-field')), 
          TestCredentials.invalidPassword,
        );
        await tester.pump();
        
        // Submit
        await tester.tap(find.text('Sign In'));
        
        // Wait for network request
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Should show error message
        expect(
          find.text('Invalid email or password')
            .evaluate().isNotEmpty ||
          find.text('Login failed')
            .evaluate().isNotEmpty ||
          find.text('Invalid credentials')
            .evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show login error message',
        );
        
        // Should still be on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        
        await screenshot('login_error');
      });

      testIntegration('should login successfully with valid credentials', (tester) async {
        await measurePerformance('successful_login', () async {
          await launchApp(tester);
          
          // Enter valid credentials
          await tester.enterText(
            find.byKey(const Key('email-field')), 
            TestCredentials.validEmail,
          );
          await tester.enterText(
            find.byKey(const Key('password-field')), 
            TestCredentials.validPassword,
          );
          await tester.pump();
          
          await screenshot('login_filled');
          
          // Submit
          await tester.tap(find.text('Sign In'));
          
          // Wait for navigation
          await TestHelpers.waitForAnimations(tester);
          await TestHelpers.waitForNetworkIdle(tester);
        });
        
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
        
        // Should show user menu or logout option
        expect(
          find.byKey(const Key('user-menu')).evaluate().isNotEmpty ||
          find.byIcon(Icons.account_circle).evaluate().isNotEmpty ||
          find.text('Logout').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show user menu after login',
        );
        
        await screenshot('home_after_login');
      });

      testIntegration('should logout successfully', (tester) async {
        await launchApp(tester);
        
        // Login first
        await TestHelpers.loginUser(
          tester,
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );
        
        // Find and tap user menu
        final userMenu = find.byKey(const Key('user-menu'));
        final accountIcon = find.byIcon(Icons.account_circle);
        
        if (userMenu.evaluate().isNotEmpty) {
          await tester.tap(userMenu);
        } else if (accountIcon.evaluate().isNotEmpty) {
          await tester.tap(accountIcon);
        }
        await tester.pumpAndSettle();
        
        // Find and tap logout
        final logoutButton = find.text('Logout');
        final signOutButton = find.text('Sign Out');
        
        if (logoutButton.evaluate().isNotEmpty) {
          await tester.tap(logoutButton);
        } else if (signOutButton.evaluate().isNotEmpty) {
          await tester.tap(signOutButton);
        }
        
        await TestHelpers.waitForAnimations(tester);
        
        // Should be back on login screen
        expect(find.text('Sign in to your account'), findsOneWidget);
        expect(find.byKey(const Key('email-field')), findsOneWidget);
        
        await screenshot('login_after_logout');
      });

      testIntegration('should toggle password visibility', (tester) async {
        await launchApp(tester);
        
        // Enter password
        await tester.enterText(
          find.byKey(const Key('password-field')), 
          TestCredentials.validPassword,
        );
        await tester.pump();
        
        // Find password visibility toggle using the key we added
        final visibilityToggle = find.byKey(const Key('password-toggle'));
        
        expect(visibilityToggle, findsOneWidget, 
          reason: 'Should have password visibility toggle');
        
        // Toggle visibility
        await tester.tap(visibilityToggle);
        await tester.pump();
        
        await screenshot('password_visible');
        
        // Toggle back
        await tester.tap(visibilityToggle);
        await tester.pump();
        
        await screenshot('password_hidden');
      });

      testIntegration('should navigate to registration screen', (tester) async {
        await launchApp(tester);
        
        // Find registration link - it's "Sign Up" (with capital U)
        final signUpLink = find.text('Sign Up');
        
        expect(signUpLink, findsOneWidget, 
          reason: 'Should have Sign Up link');
          
        await tester.tap(signUpLink);
        await TestHelpers.waitForAnimations(tester);
        
        // Should show registration screen
        expect(
          find.text('Create Account').evaluate().isNotEmpty ||
          find.text('Sign Up').evaluate().isNotEmpty ||
          find.text('Register').evaluate().isNotEmpty ||
          find.text('Create your account').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show registration screen',
        );
        
        // Should have additional fields
        expect(
          find.byKey(const Key('first-name-field')).evaluate().isNotEmpty ||
          find.byKey(const Key('firstName-field')).evaluate().isNotEmpty ||
          find.byKey(const Key('name-field')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should have name field on registration',
        );
        
        await screenshot('registration_screen');
      });
    });

    tearDownAll(() async {
      printPerformanceReport();
      await generateFailureAnalysisReport();
    });
  }
}

// Test runner
void main() {
  AuthFlowTest().main();
}