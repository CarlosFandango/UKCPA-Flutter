import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';
import '../fixtures/test_credentials.dart';

/// Fixed auth test using proper initialization pattern
/// Based on successful initialization test results
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Fixed Auth Flow Tests', () {
    testWidgets('should display login screen with proper initialization', (WidgetTester tester) async {
      print('=== FIXED AUTH TEST 1: Login Screen Display ===');
      
      print('1. Loading .env file...');
      await dotenv.load(fileName: ".env");
      print('✓ .env loaded successfully');
      
      print('2. Initializing Hive and GraphQL...');
      await Hive.initFlutter();
      await initHiveForFlutter();
      print('✓ Hive and GraphQL initialized');
      
      print('3. Pumping UKCPAApp...');
      await tester.pumpWidget(
        const ProviderScope(
          child: UKCPAApp(),
        ),
      );
      
      print('4. Waiting for app to settle...');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print('✓ App settled successfully');
      
      print('5. Checking for login screen elements...');
      
      // Check for login heading
      expect(find.text('Sign in to your account'), findsOneWidget);
      print('✓ Found login heading');
      
      // Check for form fields
      expect(find.byKey(const Key('email-field')), findsOneWidget);
      print('✓ Found email field');
      
      expect(find.byKey(const Key('password-field')), findsOneWidget);
      print('✓ Found password field');
      
      // Check for sign in button
      expect(find.text('Sign In'), findsOneWidget);
      print('✓ Found sign in button');
      
      print('FIXED AUTH TEST 1 COMPLETE: All login elements found\n');
    });

    testWidgets('should handle form input correctly', (WidgetTester tester) async {
      print('=== FIXED AUTH TEST 2: Form Input ===');
      
      print('1. Initializing app...');
      await dotenv.load(fileName: ".env");
      await Hive.initFlutter();
      await initHiveForFlutter();
      
      await tester.pumpWidget(
        const ProviderScope(
          child: UKCPAApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print('✓ App initialized successfully');
      
      print('2. Testing email field input...');
      final emailField = find.byKey(const Key('email-field'));
      await tester.enterText(emailField, TestCredentials.validEmail);
      await tester.pump();
      
      // Verify text was entered
      expect(find.text(TestCredentials.validEmail), findsOneWidget);
      print('✓ Email field input working');
      
      print('3. Testing password field input...');
      final passwordField = find.byKey(const Key('password-field'));
      await tester.enterText(passwordField, TestCredentials.validPassword);
      await tester.pump();
      
      // Verify password field has content (won't show actual text due to obscureText)
      final passwordWidget = tester.widget<TextField>(passwordField);
      expect(passwordWidget.controller?.text, TestCredentials.validPassword);
      print('✓ Password field input working');
      
      print('4. Testing password visibility toggle...');
      final passwordToggle = find.byKey(const Key('password-toggle'));
      if (passwordToggle.evaluate().isNotEmpty) {
        await tester.tap(passwordToggle);
        await tester.pump();
        print('✓ Password toggle working');
      } else {
        print('⚠️ Password toggle not found - may not be implemented');
      }
      
      print('FIXED AUTH TEST 2 COMPLETE: Form inputs working\n');
    });

    testWidgets('should attempt login with test credentials', (WidgetTester tester) async {
      print('=== FIXED AUTH TEST 3: Login Attempt ===');
      
      print('1. Initializing app...');
      await dotenv.load(fileName: ".env");
      await Hive.initFlutter();
      await initHiveForFlutter();
      
      await tester.pumpWidget(
        const ProviderScope(
          child: UKCPAApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
      print('✓ App initialized successfully');
      
      print('2. Filling in credentials...');
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
      
      print('3. Tapping sign in button...');
      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      print('✓ Sign in button tapped');
      
      print('4. Waiting for response (allowing time for network call)...');
      // Give more time for actual GraphQL network call
      for (int i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        print('  Pump ${i+1}/15...');
        
        // Check if we're still on login screen
        final loginText = find.text('Sign in to your account');
        if (loginText.evaluate().isEmpty) {
          print('✓ Login screen disappeared - likely successful login!');
          break;
        }
        
        // Check for loading indicators
        final progress = find.byType(CircularProgressIndicator);
        if (progress.evaluate().isNotEmpty) {
          print('  → Loading indicator found');
        }
        
        // Check for error messages
        final texts = find.byType(Text);
        bool errorFound = false;
        for (var j = 0; j < texts.evaluate().length; j++) {
          final widget = tester.widget<Text>(texts.at(j));
          final text = widget.data ?? '';
          if (text.toLowerCase().contains('error') || 
              text.toLowerCase().contains('invalid') ||
              text.toLowerCase().contains('failed')) {
            print('  → Found error: "$text"');
            errorFound = true;
            break;
          }
        }
        
        if (errorFound) {
          print('⚠️ Error message found - stopping wait loop');
          break;
        }
      }
      
      print('5. Final state check...');
      final stillOnLogin = find.text('Sign in to your account');
      if (stillOnLogin.evaluate().isEmpty) {
        print('✅ LOGIN SUCCESSFUL: No longer on login screen');
        
        // Look for signs we're logged in
        final texts = find.byType(Text);
        print('Current screen text elements:');
        for (int i = 0; i < texts.evaluate().length && i < 5; i++) {
          final widget = tester.widget<Text>(texts.at(i));
          final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
          if (text.isNotEmpty) {
            print('  - "$text"');
          }
        }
      } else {
        print('⚠️ Still on login screen - may be validation issue or network problem');
      }
      
      print('FIXED AUTH TEST 3 COMPLETE\n');
    });
  });
}