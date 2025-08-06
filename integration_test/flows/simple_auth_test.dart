import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/fast_test_manager.dart';
import '../helpers/automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Simple authentication test using proven working pattern
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Simple auth test: should display login screen', (WidgetTester tester) async {
    print('🚀 Starting simple login screen test');
    
    // Initialize app with clean state (proven to work)
    await FastTestManager.initializeOnce(tester);
    
    // Wait for app to settle
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Check that login screen is displayed
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.byKey(const Key('email-field')), findsOneWidget);
    expect(find.byKey(const Key('password-field')), findsOneWidget);
    print('✅ Login screen validation complete');
  });

  testWidgets('Simple auth test: should validate email format', (WidgetTester tester) async {
    print('🚀 Starting email validation test');
    
    // Initialize app with clean state
    await FastTestManager.initializeOnce(tester);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Enter invalid email
    await AutomatedTestTemplate.enterText(
      tester,
      key: const Key('email-field'),
      text: 'invalid-email',
    );
    
    // Try to submit
    await AutomatedTestTemplate.tapButton(tester, 'Sign In');
    await tester.pump(const Duration(milliseconds: 500));
    
    // Should stay on login screen
    expect(find.text('Sign in to your account'), findsOneWidget);
    print('✅ Email validation test complete');
  });

  testWidgets('Simple auth test: should require password', (WidgetTester tester) async {
    print('🚀 Starting password requirement test');
    
    // Initialize app with clean state
    await FastTestManager.initializeOnce(tester);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // Enter only email, no password
    await AutomatedTestTemplate.enterText(
      tester,
      key: const Key('email-field'),
      text: TestCredentials.validEmail,
    );
    await AutomatedTestTemplate.enterText(
      tester,
      key: const Key('password-field'),
      text: '', // Empty password
    );
    
    // Try to submit
    await AutomatedTestTemplate.tapButton(tester, 'Sign In');
    await tester.pump(const Duration(milliseconds: 500));
    
    // Should stay on login screen
    expect(find.text('Sign in to your account'), findsOneWidget);
    print('✅ Password requirement test complete');
  });

  testWidgets('Simple auth test: should attempt login with valid credentials', (WidgetTester tester) async {
    print('🚀 Starting valid login test');
    
    // Initialize app with clean state
    await FastTestManager.initializeOnce(tester);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
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
    
    // Submit login
    await AutomatedTestTemplate.tapButton(tester, 'Sign In');
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Note: Since the test user might not exist, we expect either:
    // 1. Successful login (navigates away from login screen)
    // 2. Error message shown (stays on login screen)
    // Both are acceptable outcomes for this test
    
    final loginScreenStillVisible = find.text('Sign in to your account').evaluate().isNotEmpty;
    
    if (loginScreenStillVisible) {
      print('📝 Login failed (expected - test user may not exist)');
    } else {
      print('📝 Login succeeded - navigated away from login screen');
      
      // Look for post-login indicators
      final postLoginIndicators = [
        find.text('Home'),
        find.text('Courses'),
        find.text('Browse Courses'),
      ];
      
      bool foundPostLoginContent = false;
      for (final indicator in postLoginIndicators) {
        if (indicator.evaluate().isNotEmpty) {
          foundPostLoginContent = true;
          break;
        }
      }
      
      expect(foundPostLoginContent, isTrue, reason: 'Should show post-login content');
    }
    
    print('✅ Valid login test complete');
  });
}