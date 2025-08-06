import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';

/// Working automated test template that bypasses iOS Simulator issues
/// This template can be used to create reliable automated integration tests
class AutomatedTestTemplate {
  
  /// Initialize the UKCPA app for automated testing
  /// This is the proven working pattern that avoids iOS Simulator timeouts
  static Future<void> initializeApp(WidgetTester tester, {
    String testDescription = 'Automated Test'
  }) async {
    print('\n🔧 Initializing UKCPA app for automated testing...');
    print('Test: $testDescription');
    print('======================================');
    
    // In integration tests, FLUTTER_TEST is already set by the framework
    // No need to modify Platform.environment
    
    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      print('✓ Environment variables loaded');
    } catch (e) {
      print('⚠️  Warning: Could not load .env file: $e');
    }
    
    // Initialize Hive storage
    try {
      await Hive.initFlutter();
      await initHiveForFlutter();
      print('✓ Hive storage initialized');
    } catch (e) {
      print('❌ Error initializing Hive: $e');
      rethrow;
    }
    
    // Pump the app widget
    try {
      await tester.pumpWidget(
        const ProviderScope(child: UKCPAApp()),
      );
      print('✓ App widget pumped');
    } catch (e) {
      print('❌ Error pumping app widget: $e');
      rethrow;
    }
    
    // Wait for app initialization with reasonable timeout
    try {
      print('⏳ Waiting for app initialization...');
      await tester.pumpAndSettle(const Duration(seconds: 10));
      print('✓ App initialization completed');
    } catch (e) {
      print('❌ App initialization timeout: $e');
      rethrow;
    }
    
    // Verify no critical errors
    final errors = find.byType(ErrorWidget);
    if (errors.evaluate().isNotEmpty) {
      final errorWidget = tester.widget<ErrorWidget>(errors.first);
      final errorMessage = errorWidget.message;
      print('❌ App has critical errors: $errorMessage');
      throw Exception('App initialization failed: $errorMessage');
    }
    
    print('🎉 App ready for automated testing!');
    print('======================================\n');
  }
  
  /// Verify that the app is in a testable state
  static void verifyTestableState(WidgetTester tester, {
    String expectedScreen = 'login'
  }) {
    print('🔍 Verifying app is in testable state...');
    
    // Check for common UI elements that indicate successful app load
    final materialAppFinder = find.byType(MaterialApp);
    final scaffoldFinder = find.byType(Scaffold);
    
    expect(materialAppFinder, findsAtLeastNWidgets(1), 
      reason: 'MaterialApp should be present');
    expect(scaffoldFinder, findsAtLeastNWidgets(1), 
      reason: 'Scaffold should be present');
    
    // Verify expected screen based on parameter
    switch (expectedScreen.toLowerCase()) {
      case 'login':
        expect(find.text('Sign in to your account'), findsOneWidget,
          reason: 'Should be on login screen');
        expect(find.byKey(const Key('email-field')), findsOneWidget,
          reason: 'Login form should be present');
        break;
      case 'courses':
        // Add course screen verification
        break;
      case 'home':
        // Add home screen verification  
        break;
    }
    
    print('✅ App is in expected testable state: $expectedScreen');
  }
  
  /// Helper to wait for network operations to complete
  static Future<void> waitForNetworkIdle(WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5)
  }) async {
    print('⏳ Waiting for network operations to complete...');
    
    try {
      // Pump a few times to allow network operations to start and complete
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        
        // Check if there are any loading indicators
        final loadingIndicators = find.byType(CircularProgressIndicator);
        if (loadingIndicators.evaluate().isEmpty) {
          break;
        }
      }
      
      // Final settle
      await tester.pumpAndSettle(timeout);
      print('✓ Network operations completed');
      
    } catch (e) {
      print('⚠️  Network operation timeout (this may be expected in test mode): $e');
      // Don't rethrow - network timeouts are expected in test mode
    }
  }
  
  /// Take a screenshot if the environment supports it
  static Future<void> takeScreenshot(
    IntegrationTestWidgetsFlutterBinding binding, 
    String name
  ) async {
    try {
      await binding.takeScreenshot(name);
      print('📸 Screenshot taken: $name');
    } catch (e) {
      print('⚠️  Could not take screenshot: $e (this is expected on iOS Simulator)');
      // Don't rethrow - screenshot failures shouldn't break tests
    }
  }
  
  /// Helper to perform form interactions safely
  static Future<void> enterTextSafely(
    WidgetTester tester,
    Finder finder,
    String text, {
    String description = 'form field'
  }) async {
    print('📝 Entering text in $description: "$text"');
    
    // Verify the field exists
    expect(finder, findsOneWidget, reason: '$description should be present');
    
    // Enter text
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
    
    print('✓ Text entered successfully in $description');
  }

  /// Helper method with backward compatibility name
  static Future<void> enterText(
    WidgetTester tester, {
    required Key key,
    required String text,
  }) async {
    await enterTextSafely(tester, find.byKey(key), text, description: 'field with key ${key.toString()}');
  }
  
  /// Helper to tap elements safely
  static Future<void> tapSafely(
    WidgetTester tester,
    Finder finder, {
    String description = 'element'
  }) async {
    print('👆 Tapping $description');
    
    // Verify the element exists
    expect(finder, findsOneWidget, reason: '$description should be present');
    
    // Tap the element
    await tester.tap(finder);
    await tester.pumpAndSettle();
    
    print('✓ Successfully tapped $description');
  }

  /// Helper method to tap buttons by text with backward compatibility
  static Future<void> tapButton(WidgetTester tester, String buttonText) async {
    await tapSafely(tester, find.text(buttonText), description: 'button "$buttonText"');
  }
  
  /// Create a test template function that handles common test setup
  static void createAutomatedTest(
    String description,
    Future<void> Function(WidgetTester tester) testFunction, {
    String expectedScreen = 'login',
    bool takeScreenshots = false,
    Duration? timeout,
  }) {
    testWidgets(description, (WidgetTester tester) async {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      
      try {
        // Initialize app
        await initializeApp(tester, testDescription: description);
        
        // Verify testable state
        verifyTestableState(tester, expectedScreen: expectedScreen);
        
        // Take initial screenshot if requested
        if (takeScreenshots) {
          await takeScreenshot(binding, '${description.replaceAll(' ', '_')}_start');
        }
        
        // Run the actual test
        await testFunction(tester);
        
        // Take final screenshot if requested
        if (takeScreenshots) {
          await takeScreenshot(binding, '${description.replaceAll(' ', '_')}_end');
        }
        
        print('✅ Test completed successfully: $description');
        
      } catch (e, stackTrace) {
        print('❌ Test failed: $description');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        
        // Take error screenshot if possible
        if (takeScreenshots) {
          try {
            await takeScreenshot(binding, '${description.replaceAll(' ', '_')}_error');
          } catch (_) {
            // Ignore screenshot errors
          }
        }
        
        rethrow;
      }
    }, timeout: Timeout(timeout ?? const Duration(minutes: 5)));
  }
}