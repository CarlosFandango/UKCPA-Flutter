import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../fixtures/test_credentials.dart';

/// Simplified auth tests to identify timeout issues
class SimplifiedAuthTest extends BaseIntegrationTest {
  @override
  void main() {
    setupTest();

    group('Simplified Auth Tests', () {
      testIntegration('should display login screen elements', (tester) async {
        print('TEST START: should display login screen elements');
        
        print('1. Launching app...');
        await launchApp(tester);
        print('✓ App launched successfully');
        
        print('2. Waiting for UI to settle...');
        await tester.pumpAndSettle();
        print('✓ UI settled');
        
        print('3. Checking for login screen text...');
        expect(find.text('Sign in to your account'), findsOneWidget);
        print('✓ Found login screen text');
        
        print('4. Checking for email field...');
        expect(find.byKey(const Key('email-field')), findsOneWidget);
        print('✓ Found email field');
        
        print('5. Checking for password field...');
        expect(find.byKey(const Key('password-field')), findsOneWidget);
        print('✓ Found password field');
        
        print('6. Checking for sign in button...');
        expect(find.text('Sign In'), findsOneWidget);
        print('✓ Found sign in button');
        
        print('TEST COMPLETE: should display login screen elements');
      });

      testIntegration('should enter text in email field only', (tester) async {
        print('\nTEST START: should enter text in email field only');
        
        await launchApp(tester);
        await tester.pumpAndSettle();
        print('✓ App ready');
        
        print('1. Finding email field...');
        final emailField = find.byKey(const Key('email-field'));
        expect(emailField, findsOneWidget);
        print('✓ Found email field');
        
        print('2. Entering text in email field...');
        await tester.enterText(emailField, 'test@example.com');
        print('✓ Text entered');
        
        print('3. Waiting for UI update...');
        await tester.pump();
        print('✓ UI pumped');
        
        print('4. Verifying text was entered...');
        expect(find.text('test@example.com'), findsOneWidget);
        print('✓ Text verified in field');
        
        print('TEST COMPLETE: should enter text in email field only');
      });

      testIntegration('should tap sign in button without credentials', (tester) async {
        print('\nTEST START: should tap sign in button without credentials');
        
        await launchApp(tester);
        await tester.pumpAndSettle();
        print('✓ App ready');
        
        print('1. Finding sign in button...');
        final signInButton = find.text('Sign In');
        expect(signInButton, findsOneWidget);
        print('✓ Found sign in button');
        
        print('2. Tapping sign in button...');
        await tester.tap(signInButton);
        print('✓ Button tapped');
        
        print('3. Pumping once...');
        await tester.pump();
        print('✓ First pump complete');
        
        print('4. Pumping with delay...');
        await tester.pump(const Duration(milliseconds: 500));
        print('✓ Second pump complete');
        
        print('5. Looking for any validation messages...');
        final allTexts = find.byType(Text);
        print('Found ${allTexts.evaluate().length} text widgets');
        
        // Print first 10 texts to see what's on screen
        for (var i = 0; i < allTexts.evaluate().length && i < 10; i++) {
          final widget = tester.widget<Text>(allTexts.at(i));
          final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
          print('  Text $i: "$text"');
        }
        
        print('TEST COMPLETE: should tap sign in button without credentials');
      });

      testIntegration('should validate email with single field interaction', (tester) async {
        print('\nTEST START: should validate email with single field interaction');
        
        await launchApp(tester);
        await tester.pumpAndSettle();
        print('✓ App ready');
        
        print('1. Entering invalid email...');
        await tester.enterText(find.byKey(const Key('email-field')), 'notanemail');
        await tester.pump();
        print('✓ Invalid email entered');
        
        print('2. Finding form (if exists)...');
        final forms = find.byType(Form);
        print('Found ${forms.evaluate().length} forms');
        
        print('3. Tapping sign in to trigger validation...');
        await tester.tap(find.text('Sign In'));
        print('✓ Sign in tapped');
        
        print('4. Waiting for validation (multiple pump strategies)...');
        
        print('  4a. Single pump...');
        await tester.pump();
        
        print('  4b. Pump with delay...');
        await tester.pump(const Duration(milliseconds: 100));
        
        print('  4c. Multiple pumps...');
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          print('    Pump ${i+1} complete');
          
          // Check for validation message after each pump
          final validationMessage = find.text('Please enter a valid email address');
          if (validationMessage.evaluate().isNotEmpty) {
            print('✓ Found validation message after ${i+1} pumps!');
            break;
          }
        }
        
        print('5. Final check for validation message...');
        final validationMessage = find.text('Please enter a valid email address');
        print('Validation message found: ${validationMessage.evaluate().isNotEmpty}');
        
        print('TEST COMPLETE: should validate email with single field interaction');
      });

      testIntegration('should attempt login with mock delay', (tester) async {
        print('\nTEST START: should attempt login with mock delay');
        
        await launchApp(tester);
        await tester.pumpAndSettle();
        print('✓ App ready');
        
        print('1. Entering credentials...');
        await tester.enterText(
          find.byKey(const Key('email-field')), 
          TestCredentials.validEmail
        );
        await tester.enterText(
          find.byKey(const Key('password-field')), 
          TestCredentials.validPassword
        );
        await tester.pump();
        print('✓ Credentials entered');
        
        print('2. Tapping sign in...');
        await tester.tap(find.text('Sign In'));
        print('✓ Sign in tapped');
        
        print('3. Simulating network delay with multiple pumps...');
        for (int i = 0; i < 10; i++) {
          print('  Pump ${i+1}/10...');
          await tester.pump(const Duration(milliseconds: 500));
          
          // Check if we're still on login screen
          final loginText = find.text('Sign in to your account');
          if (loginText.evaluate().isEmpty) {
            print('✓ Login screen disappeared after ${i+1} pumps!');
            break;
          }
          
          // Check for loading indicators
          final progress = find.byType(CircularProgressIndicator);
          if (progress.evaluate().isNotEmpty) {
            print('  → Found loading indicator');
          }
          
          // Check for error messages
          final texts = find.byType(Text);
          for (var j = 0; j < texts.evaluate().length; j++) {
            final widget = tester.widget<Text>(texts.at(j));
            final text = widget.data ?? '';
            if (text.toLowerCase().contains('error') || 
                text.toLowerCase().contains('failed')) {
              print('  → Found error: "$text"');
            }
          }
        }
        
        print('4. Final state check...');
        final loginScreen = find.text('Sign in to your account');
        print('Still on login screen: ${loginScreen.evaluate().isNotEmpty}');
        
        print('TEST COMPLETE: should attempt login with mock delay');
      });
    });
  }
}

// Test runner
void main() {
  SimplifiedAuthTest().main();
}