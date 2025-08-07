import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';
import 'package:ukcpa_flutter/presentation/providers/auth_provider.dart';
import 'package:ukcpa_flutter/presentation/providers/terms_provider.dart';
import 'package:ukcpa_flutter/data/repositories/terms_repository_impl.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/mock_data_factory.dart';
import 'automated_test_template.dart';

/// Legacy support for TestCredentials - will be replaced by MockDataFactory
class TestCredentials {
  static const String validEmail = MockDataFactory.defaultTestEmail;
  static const String validPassword = MockDataFactory.defaultTestPassword;
}

/// Ultra-fast test manager using centralized mocked dependencies
class MockedFastTestManager {
  static bool _initialized = false;
  
  /// Initialize app with mocked dependencies for super-fast testing
  static Future<void> initializeMocked(WidgetTester tester) async {
    if (!_initialized) {
      print('🚀 Initializing mocked fast test environment...');
      final startTime = DateTime.now();
      
      // Load environment (only once)
      await dotenv.load(fileName: ".env");
      
      // Initialize storage (minimal setup)
      await Hive.initFlutter();
      await initHiveForFlutter();
      
      // Initialize centralized mock repositories
      MockRepositoryFactory.resetToDefaults();
      _initialized = true;
      
      final duration = DateTime.now().difference(startTime);
      print('⚡ Mocked environment initialized in ${duration.inMilliseconds}ms');
    } else {
      print('⚡ Reusing mocked test environment (ultra-fast)');
    }
    
    // Always pump fresh app with mocked providers for clean state
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override repositories with centralized mocks
          authRepositoryProvider.overrideWithValue(MockRepositoryFactory.getAuthRepository()),
          termsRepositoryProvider.overrideWithValue(MockRepositoryFactory.getTermsRepository()),
        ],
        child: const UKCPAApp(),
      ),
    );
    
    // Minimal wait for app to settle (much faster than real backend calls)
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    
    print('📱 Mocked app ready for testing');
  }
  
  /// Initialize app configured for ultra-fast testing (no delays)
  static Future<void> initializeUltraFast(WidgetTester tester) async {
    MockRepositoryFactory.configureForSpeed();
    await initializeMocked(tester);
    print('⚡ Configured for ultra-fast testing (no delays)');
  }
  
  /// Initialize app configured for error scenario testing
  static Future<void> initializeWithErrors(WidgetTester tester) async {
    MockRepositoryFactory.configureForErrorTesting();
    await initializeMocked(tester);
    print('❌ Configured for error scenario testing');
  }
  
  /// Initialize app configured for empty state testing
  static Future<void> initializeEmpty(WidgetTester tester) async {
    MockRepositoryFactory.configureForEmptyState();
    await initializeMocked(tester);
    print('📭 Configured for empty state testing');
  }
  
  /// Create fast test batch with mocked dependencies
  static void createMockedTestBatch(
    String description,
    Map<String, Future<void> Function(WidgetTester)> tests, {
    bool requiresAuth = false,
  }) {
    group(description, () {
      for (final entry in tests.entries) {
        testWidgets(entry.key, (WidgetTester tester) async {
          print('🏃‍♂️ Running mocked test: ${entry.key}');
          
          // Initialize with mocked dependencies
          await initializeMocked(tester);
          
          // Run the test
          await entry.value(tester);
        });
      }
    });
  }
}

/// Fast automated test template with reduced wait times
class FastAutomatedTestTemplate {
  
  /// Enter text into a field identified by key (fast version)
  static Future<void> enterText(
    WidgetTester tester, {
    required Key key,
    required String text,
    Duration delay = const Duration(milliseconds: 50), // Much faster
  }) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Field with key $key not found');
    
    await tester.enterText(finder, text);
    await tester.pump(delay);
  }
  
  /// Tap a button by text (fast version)
  static Future<void> tapButton(
    WidgetTester tester, 
    String buttonText, {
    Duration delay = const Duration(milliseconds: 100), // Much faster
  }) async {
    final finder = find.text(buttonText);
    expect(finder, findsOneWidget, reason: 'Button with text "$buttonText" not found');
    
    await tester.tap(finder);
    await tester.pump(delay);
  }
  
  /// Wait for UI changes (fast version)
  static Future<void> waitForUI(
    WidgetTester tester, {
    Duration duration = const Duration(milliseconds: 200), // Much faster
  }) async {
    await tester.pumpAndSettle(duration);
  }
}