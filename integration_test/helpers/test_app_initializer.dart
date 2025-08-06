import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';

/// Reliable test app initializer based on proven working pattern
/// This encapsulates the initialization sequence that was discovered during
/// the August 2025 timeout investigation.
class TestAppInitializer {
  /// Initialize the UKCPA app for integration testing
  /// 
  /// This follows the proven pattern:
  /// 1. Load environment variables (.env)
  /// 2. Initialize Hive for local storage
  /// 3. Initialize GraphQL cache
  /// 4. Pump the app with ProviderScope
  /// 5. Wait for full initialization
  /// 6. Verify no errors occurred
  /// 
  /// Throws an exception if initialization fails at any step.
  static Future<void> initialize(WidgetTester tester) async {
    print('🔧 Initializing UKCPA app for testing...');
    
    try {
      // Step 1: Load environment variables
      print('  1. Loading environment variables...');
      await dotenv.load(fileName: ".env");
      print('     ✓ Environment variables loaded');
      
      // Step 2: Initialize Hive for local storage
      print('  2. Initializing Hive...');
      await Hive.initFlutter();
      print('     ✓ Hive initialized');
      
      // Step 3: Initialize GraphQL cache
      print('  3. Initializing GraphQL cache...');
      await initHiveForFlutter();
      print('     ✓ GraphQL cache initialized');
      
      // Step 4: Pump the app with ProviderScope
      print('  4. Pumping UKCPAApp with ProviderScope...');
      await tester.pumpWidget(
        const ProviderScope(
          child: UKCPAApp(),
        ),
      );
      print('     ✓ App widget pumped');
      
      // Step 5: Wait for full app initialization
      print('  5. Waiting for app initialization (8 second timeout)...');
      await tester.pumpAndSettle(const Duration(seconds: 8));
      print('     ✓ App initialization completed');
      
      // Step 6: Verify no errors occurred
      print('  6. Verifying no initialization errors...');
      final errors = find.byType(ErrorWidget);
      if (errors.evaluate().isNotEmpty) {
        final errorWidget = tester.widget<ErrorWidget>(errors.first);
        final errorMessage = errorWidget.message;
        print('     ❌ App initialization error: $errorMessage');
        throw Exception('App initialization failed: $errorMessage');
      }
      print('     ✓ No errors found');
      
      // Step 7: Verify basic UI elements are present
      print('  7. Verifying basic UI elements...');
      final allWidgets = find.byType(Widget);
      final widgetCount = allWidgets.evaluate().length;
      if (widgetCount == 0) {
        throw Exception('No widgets found - app may not have rendered');
      }
      print('     ✓ Found $widgetCount widgets - app rendered successfully');
      
      print('🎉 App ready for testing!');
      
    } catch (e, stackTrace) {
      print('❌ App initialization failed: $e');
      print('Stack trace: $stackTrace');
      
      // Try to capture current state for debugging
      await _captureDebugState(tester);
      
      rethrow;
    }
  }
  
  /// Quick initialization without verbose logging
  /// Use this for tests that don't need detailed initialization logs
  static Future<void> initializeQuiet(WidgetTester tester) async {
    await dotenv.load(fileName: ".env");
    await Hive.initFlutter();
    await initHiveForFlutter();
    
    await tester.pumpWidget(
      const ProviderScope(child: UKCPAApp()),
    );
    
    await tester.pumpAndSettle(const Duration(seconds: 8));
    
    // Verify no errors
    final errors = find.byType(ErrorWidget);
    if (errors.evaluate().isNotEmpty) {
      final errorWidget = tester.widget<ErrorWidget>(errors.first);
      throw Exception('App initialization failed: ${errorWidget.message}');
    }
  }
  
  /// Capture debug state when initialization fails
  static Future<void> _captureDebugState(WidgetTester tester) async {
    try {
      print('\n📊 Capturing debug state...');
      
      // Check for any widgets
      final allWidgets = find.byType(Widget);
      print('Total widgets found: ${allWidgets.evaluate().length}');
      
      // Check for error widgets
      final errors = find.byType(ErrorWidget);
      if (errors.evaluate().isNotEmpty) {
        print('Error widgets found: ${errors.evaluate().length}');
        for (int i = 0; i < errors.evaluate().length; i++) {
          final errorWidget = tester.widget<ErrorWidget>(errors.at(i));
          print('  Error ${i + 1}: ${errorWidget.message}');
        }
      }
      
      // Check for text widgets (might indicate partial loading)
      final texts = find.byType(Text);
      if (texts.evaluate().isNotEmpty) {
        print('Text widgets found: ${texts.evaluate().length}');
        for (int i = 0; i < texts.evaluate().length && i < 5; i++) {
          final widget = tester.widget<Text>(texts.at(i));
          final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
          if (text.isNotEmpty && text.length < 100) {
            print('  Text ${i + 1}: "$text"');
          }
        }
      }
      
      // Check for scaffolds (indicates UI structure)
      final scaffolds = find.byType(Scaffold);
      print('Scaffold widgets found: ${scaffolds.evaluate().length}');
      
      print('📊 Debug state capture complete\n');
      
    } catch (e) {
      print('Could not capture debug state: $e');
    }
  }
  
  /// Verify the app is in expected state for testing
  /// Call this after initialize() to confirm the app is ready
  static void verifyAppReady({
    bool shouldHaveLoginScreen = true,
    List<String> requiredTexts = const [],
    List<Key> requiredKeys = const [],
  }) {
    print('🔍 Verifying app is ready for testing...');
    
    if (shouldHaveLoginScreen) {
      final loginHeading = find.text('Sign in to your account');
      if (loginHeading.evaluate().isEmpty) {
        throw Exception('Login screen not found - app may not be in expected state');
      }
      print('  ✓ Login screen present');
    }
    
    for (String text in requiredTexts) {
      final textFinder = find.text(text);
      if (textFinder.evaluate().isEmpty) {
        throw Exception('Required text not found: "$text"');
      }
      print('  ✓ Required text found: "$text"');
    }
    
    for (Key key in requiredKeys) {
      final keyFinder = find.byKey(key);
      if (keyFinder.evaluate().isEmpty) {
        throw Exception('Required widget key not found: $key');
      }
      print('  ✓ Required key found: $key');
    }
    
    print('🎉 App verification complete - ready for testing!');
  }
}