import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/test_credentials.dart';

/// Debug version of auth tests to identify specific issues
class DebugAuthTest extends BaseIntegrationTest {
  @override
  void main() {
    setupTest();

    group('Debug Auth Tests', () {
      testIntegration('debug - find all text on login screen', (tester) async {
        await launchApp(tester);
      await tester.pumpAndSettle();
      
      // Find and print all text widgets
      final textWidgets = find.byType(Text);
      print('Found ${textWidgets.evaluate().length} text widgets:');
      
      for (var i = 0; i < textWidgets.evaluate().length; i++) {
        final widget = tester.widget<Text>(textWidgets.at(i));
        print('Text $i: "${widget.data ?? widget.textSpan?.toPlainText()}"');
      }
      
      // Check for specific elements
      print('\nChecking for specific elements:');
      print('Sign in to your account: ${find.text('Sign in to your account').evaluate().length}');
      print('Email field: ${find.byKey(const Key('email-field')).evaluate().length}');
      print('Password field: ${find.byKey(const Key('password-field')).evaluate().length}');
      print('Sign In button: ${find.text('Sign In').evaluate().length}');
      print('Sign Up link: ${find.text('Sign Up').evaluate().length}');
      
      // Take screenshot for manual inspection
      await screenshot('debug_login_screen');
    });

    testIntegration('debug - test form validation', (tester) async {
      await launchApp(tester);
      await tester.pumpAndSettle();
      
      print('\n=== Testing Form Validation ===');
      
      // Find email field and enter invalid email
      final emailField = find.byKey(const Key('email-field'));
      expect(emailField, findsOneWidget, reason: 'Email field should exist');
      
      await tester.enterText(emailField, 'notanemail');
      await tester.pumpAndSettle();
      print('Entered text: notanemail');
      
      // Find and tap sign in button
      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget, reason: 'Sign In button should exist');
      
      await tester.tap(signInButton);
      await tester.pumpAndSettle();
      print('Tapped Sign In button');
      
      // Look for any error messages
      print('\nLooking for error messages:');
      final allTexts = find.byType(Text);
      for (var i = 0; i < allTexts.evaluate().length; i++) {
        final widget = tester.widget<Text>(allTexts.at(i));
        final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
        if (text.toLowerCase().contains('error') || 
            text.toLowerCase().contains('invalid') || 
            text.toLowerCase().contains('valid') ||
            text.toLowerCase().contains('required')) {
          print('Found potential error: "$text"');
        }
      }
      
      await screenshot('debug_validation_error');
    });

    testIntegration('debug - test successful login', (tester) async {
      await launchApp(tester);
      await tester.pumpAndSettle();
      
      print('\n=== Testing Successful Login ===');
      
      // Enter valid credentials
      await tester.enterText(find.byKey(const Key('email-field')), TestCredentials.validEmail);
      await tester.enterText(find.byKey(const Key('password-field')), TestCredentials.validPassword);
      await tester.pumpAndSettle();
      
      print('Entered credentials: ${TestCredentials.validEmail} / ${TestCredentials.validPassword}');
      
      // Tap sign in
      await tester.tap(find.text('Sign In'));
      
      // Wait for any navigation or loading
      print('Waiting for response...');
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        
        // Check if we're still on login screen
        final loginText = find.text('Sign in to your account');
        if (loginText.evaluate().isEmpty) {
          print('Login screen disappeared - likely successful login!');
          break;
        }
        
        // Look for any error messages
        final allTexts = find.byType(Text);
        for (var j = 0; j < allTexts.evaluate().length; j++) {
          final widget = tester.widget<Text>(allTexts.at(j));
          final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
          if (text.toLowerCase().contains('error') || 
              text.toLowerCase().contains('failed') || 
              text.toLowerCase().contains('invalid')) {
            print('Found error after ${i+1} seconds: "$text"');
          }
        }
      }
      
      // Final state check
      print('\nFinal state check:');
      final finalTexts = find.byType(Text);
      print('All visible texts:');
      for (var i = 0; i < finalTexts.evaluate().length && i < 10; i++) {
        final widget = tester.widget<Text>(finalTexts.at(i));
        print('- "${widget.data ?? widget.textSpan?.toPlainText()}"');
      }
      
      await screenshot('debug_final_state');
    });
  });
  }
}

// Test runner
void main() {
  DebugAuthTest().main();
}