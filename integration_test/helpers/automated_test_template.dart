import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Automated test template providing common test actions
class AutomatedTestTemplate {
  
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
  
  /// Take a screenshot (no-op in fast tests, but kept for compatibility)
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name, {
    bool inFastMode = true,
  }) async {
    if (!inFastMode) {
      // In normal tests, this could capture screenshots
      // For fast tests, we skip this to save time
    }
    print('📸 Screenshot: $name (skipped in fast mode)');
  }
}