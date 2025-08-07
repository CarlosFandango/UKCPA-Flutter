import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Automated test template providing common test actions
class AutomatedTestTemplate {
  
  /// Detect current page/route based on visible elements
  static Future<String> detectCurrentPage(WidgetTester tester) async {
    // Common page indicators - add more as needed
    final pageIndicators = {
      'Login Page': ['/auth/login', find.text('Sign in to your account')],
      'Home Page': ['/home', find.text('Home')],
      'Course Groups': ['/courses', find.text('Browse Courses')],
      'Course Details': ['/course/:id', find.textContaining('Book Now')],
      'Profile': ['/profile', find.text('My Profile')],
      'Settings': ['/settings', find.text('Settings')],
    };
    
    for (final entry in pageIndicators.entries) {
      final pageName = entry.key;
      final route = entry.value[0] as String;
      final indicator = entry.value[1] as Finder;
      
      if (indicator.evaluate().isNotEmpty) {
        print('📍 Current Page: $pageName');
        print('🔗 Route: $route');
        return pageName;
      }
    }
    
    print('📍 Current Page: Unknown');
    print('🔗 Route: Unable to determine');
    return 'Unknown Page';
  }
  
  /// Log page information for reports
  static Future<void> logPageInfo(WidgetTester tester, String targetPage) async {
    print('\n' + '='*60);
    print('📋 TEST TARGET: $targetPage');
    print('🕐 TIMESTAMP: ${DateTime.now()}');
    print('📱 PLATFORM: Flutter Integration Test');
    
    final currentPage = await detectCurrentPage(tester);
    print('📍 ACTUAL PAGE: $currentPage');
    print('='*60 + '\n');
  }
  
  /// Enter text into a field identified by key
  static Future<void> enterText(
    WidgetTester tester, {
    required Key key,
    required String text,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Field with key $key not found');
    
    await tester.enterText(finder, text);
    await tester.pump(delay);
  }
  
  /// Tap a button by text
  static Future<void> tapButton(
    WidgetTester tester, 
    String buttonText, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    final finder = find.text(buttonText);
    expect(finder, findsOneWidget, reason: 'Button with text "$buttonText" not found');
    
    await tester.tap(finder);
    await tester.pump(delay);
  }
  
  /// Tap an element by key
  static Future<void> tapByKey(
    WidgetTester tester,
    Key key, {
    Duration delay = const Duration(milliseconds: 300),
  }) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Element with key $key not found');
    
    await tester.tap(finder);
    await tester.pump(delay);
  }
  
  /// Wait for an element to appear
  static Future<void> waitForElement(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(pollInterval);
      
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    
    throw Exception('Element not found within timeout: ${timeout.inSeconds}s');
  }
  
  /// Wait for text to appear
  static Future<void> waitForText(
    WidgetTester tester,
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await waitForElement(tester, find.text(text), timeout: timeout);
  }
  
  /// Wait for element by key to appear
  static Future<void> waitForKey(
    WidgetTester tester,
    Key key, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await waitForElement(tester, find.byKey(key), timeout: timeout);
  }
  
  /// Scroll to find an element
  static Future<void> scrollToElement(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
    double delta = -200.0,
    int maxScrolls = 10,
  }) async {
    scrollable ??= find.byType(Scrollable).first;
    
    for (int i = 0; i < maxScrolls; i++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      
      await tester.drag(scrollable, Offset(0, delta));
      await tester.pump(const Duration(milliseconds: 200));
    }
    
    throw Exception('Element not found after scrolling');
  }
  
  /// Take a screenshot with proper integration test support
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name, {
    bool inFastMode = true,
  }) async {
    if (!inFastMode) {
      try {
        final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
        await binding.takeScreenshot(name);
        print('📸 Screenshot saved: $name');
      } catch (e) {
        print('📸 Screenshot failed: $e');
      }
    } else {
      print('📸 Screenshot: $name (skipped in fast mode)');
    }
  }
  
  /// Take a screenshot for UX reports (always captures)
  static Future<void> takeUXScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    try {
      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      await binding.takeScreenshot(name);
      print('📸 UX Screenshot captured: $name');
      print('   Location: build/screenshots/$name.png');
    } catch (e) {
      print('📸 UX Screenshot failed: $e');
    }
  }
}