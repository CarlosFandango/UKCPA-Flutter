import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';
import '../fixtures/test_credentials.dart';
import 'test_helpers.dart';

/// Base configuration for all integration tests
/// This reduces boilerplate and ensures consistent test setup
abstract class BaseIntegrationTest {
  late IntegrationTestWidgetsFlutterBinding binding;
  
  /// Set up the test environment
  void setupTest() {
    binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    
    // Configure test settings for optimal performance
    if (TestFeatureFlags.skipAnimations) {
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
    }
    
    // Set up test failure handlers
    tearDownAll(() async {
      // Clean up any test data
      await _cleanupTestData();
    });
  }
  
  /// Launch the app with test configuration
  Future<void> launchApp(WidgetTester tester) async {
    // Initialize test environment
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Load test environment variables
    await dotenv.load(fileName: ".env");
    
    // Initialize Hive for test
    await Hive.initFlutter();
    await initHiveForFlutter();
    
    // Launch the app with ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: UKCPAApp(),
      ),
    );
    
    // Wait for app initialization
    await TestHelpers.waitForAnimations(tester);
    
    // Check if app launched successfully
    TestHelpers.expectNoErrors();
  }
  
  /// Take a screenshot if enabled
  Future<void> screenshot(String name) async {
    if (TestEnvironment.shouldTakeScreenshots) {
      await TestHelpers.takeScreenshot(binding, name);
    }
  }
  
  /// Common test teardown
  Future<void> _cleanupTestData() async {
    // This would clean up any test data created during tests
    // For now, it's a placeholder
  }
  
  /// Run a test with proper setup and teardown
  void testIntegration(
    String description,
    Future<void> Function(WidgetTester tester) test, {
    bool skip = false,
    Timeout? timeout,
  }) {
    testWidgets(
      description,
      (WidgetTester tester) async {
        try {
          await test(tester);
        } catch (e) {
          // Take a screenshot on failure
          await screenshot('error_${description.replaceAll(' ', '_')}');
          rethrow;
        }
      },
      skip: skip,
      timeout: timeout ?? const Timeout(Duration(minutes: 2)),
    );
  }
}

/// Mixin for tests that require authentication
mixin AuthenticatedTest on BaseIntegrationTest {
  /// Login with default test credentials
  Future<void> loginTestUser(WidgetTester tester) async {
    await TestHelpers.loginUser(
      tester,
      email: TestCredentials.validEmail,
      password: TestCredentials.validPassword,
    );
    
    // Wait for navigation after login
    await TestHelpers.waitForAnimations(tester);
    
    // Verify we're logged in by checking for logout button or user menu
    expect(
      find.byKey(const Key('user-menu')).evaluate().isNotEmpty ||
      find.text('Logout').evaluate().isNotEmpty,
      isTrue,
      reason: 'User should be logged in',
    );
  }
  
  /// Logout the current user
  Future<void> logoutUser(WidgetTester tester) async {
    // Find and tap user menu or logout button
    final userMenu = find.byKey(const Key('user-menu'));
    if (userMenu.evaluate().isNotEmpty) {
      await tester.tap(userMenu);
      await tester.pumpAndSettle();
    }
    
    final logoutButton = find.text('Logout');
    if (logoutButton.evaluate().isNotEmpty) {
      await tester.tap(logoutButton);
      await TestHelpers.waitForAnimations(tester);
    }
  }
}

/// Mixin for tests that interact with the basket
mixin BasketTest on BaseIntegrationTest {
  /// Get current basket item count
  Future<int> getBasketItemCount(WidgetTester tester) async {
    final basketIcon = find.byKey(const Key('basket-icon'));
    if (basketIcon.evaluate().isEmpty) return 0;
    
    // Look for badge text
    final badgeText = find.descendant(
      of: basketIcon,
      matching: find.byType(Text),
    );
    
    if (badgeText.evaluate().isNotEmpty) {
      final text = TestHelpers.getTextFromWidget(badgeText);
      return int.tryParse(text ?? '0') ?? 0;
    }
    
    return 0;
  }
  
  /// Navigate to basket screen
  Future<void> navigateToBasket(WidgetTester tester) async {
    final basketIcon = find.byKey(const Key('basket-icon'));
    expect(basketIcon, findsOneWidget, reason: 'Basket icon should be visible');
    
    await tester.tap(basketIcon);
    await TestHelpers.waitForAnimations(tester);
    
    // Verify we're on basket screen
    expect(
      find.byKey(const Key('basket-screen')),
      findsOneWidget,
      reason: 'Should be on basket screen',
    );
  }
  
  /// Clear the basket
  Future<void> clearBasket(WidgetTester tester) async {
    final clearButton = find.text('Clear Basket');
    if (clearButton.evaluate().isNotEmpty) {
      await tester.tap(clearButton);
      await tester.pumpAndSettle();
      
      // Confirm if there's a dialog
      final confirmButton = find.text('Clear');
      if (confirmButton.evaluate().isNotEmpty) {
        await tester.tap(confirmButton);
        await TestHelpers.waitForAnimations(tester);
      }
    }
  }
}

/// Performance monitoring mixin
mixin PerformanceTest on BaseIntegrationTest {
  final Map<String, Duration> _performanceMetrics = {};
  
  /// Measure the time taken for an operation
  Future<T> measurePerformance<T>(
    String metricName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _performanceMetrics[metricName] = stopwatch.elapsed;
      
      // Log performance metric
      print('Performance: $metricName took ${stopwatch.elapsedMilliseconds}ms');
      
      // Fail if operation took too long
      if (stopwatch.elapsed > const Duration(seconds: 30)) {
        fail('$metricName took too long: ${stopwatch.elapsed}');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _performanceMetrics['$metricName (failed)'] = stopwatch.elapsed;
      rethrow;
    }
  }
  
  /// Print all performance metrics
  void printPerformanceReport() {
    print('\n=== Performance Report ===');
    _performanceMetrics.forEach((metric, duration) {
      print('$metric: ${duration.inMilliseconds}ms');
    });
    print('=========================\n');
  }
}