# Automated Test Template Guide

## 🎯 **Problem Solved**

**Issue**: Integration tests need common utilities for page detection, screenshot capture, element waiting, and scrolling operations that get repeated across different test files.

**Solution**: The `AutomatedTestTemplate` provides reusable utilities for common test operations with consistent error handling and cross-platform support.

## 🚀 **Quick Start**

### Page Detection and Logging

```dart
import '../helpers/automated_test_template.dart';

testWidgets('UX review with page detection', (tester) async {
  // Log detailed page information for reports
  await AutomatedTestTemplate.logPageInfo(tester, 'Course List Page');
  
  // Detect current page automatically
  final currentPage = await AutomatedTestTemplate.detectCurrentPage(tester);
  print('Current page: $currentPage');
});
```

### Screenshot Capture

```dart
testWidgets('Visual validation test', (tester) async {
  // Take screenshot for UX documentation
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'course_list_initial');
  
  // Perform some actions
  await tester.tap(find.text('Ballet Beginners'));
  await tester.pumpAndSettle();
  
  // Take another screenshot
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'course_details_loaded');
});
```

## 🔧 **Core Methods**

### Page Detection

#### detectCurrentPage()

**Automatically detect current page** based on visible elements:

```dart
final currentPage = await AutomatedTestTemplate.detectCurrentPage(tester);
// Returns: 'Login Page', 'Course Groups', 'Home Page', etc.
```

**Supported Page Detection:**
- **Login Page**: 'Sign in to your account'
- **Home Page**: 'Home'
- **Course Groups**: 'Browse Courses'
- **Course Details**: 'Book Now'
- **Profile**: 'My Profile'
- **Settings**: 'Settings'

#### logPageInfo()

**Comprehensive page information logging** for test reports:

```dart
await AutomatedTestTemplate.logPageInfo(tester, 'Course List Page');
```

**Output Example:**
```
============================================================
📋 TEST TARGET: Course List Page
🕐 TIMESTAMP: 2024-08-07 14:30:25.123
📱 PLATFORM: Flutter Integration Test
📍 ACTUAL PAGE: Course Groups
🔗 Route: /courses
============================================================
```

### Element Interaction

#### enterText()

**Reliable text entry** with field validation:

```dart
await AutomatedTestTemplate.enterText(
  tester,
  key: Key('email-field'),
  text: 'user@example.com',
  delay: Duration(milliseconds: 100),
);
```

#### tapButton()

**Button interaction** with automatic finding:

```dart
await AutomatedTestTemplate.tapButton(
  tester,
  'Sign In',
  delay: Duration(milliseconds: 300),
);
```

#### tapByKey()

**Element interaction** by key:

```dart
await AutomatedTestTemplate.tapByKey(
  tester,
  Key('submit-button'),
  delay: Duration(milliseconds: 300),
);
```

### Element Waiting

#### waitForElement()

**Wait for any element** to appear:

```dart
await AutomatedTestTemplate.waitForElement(
  tester,
  find.text('Course Details'),
  timeout: Duration(seconds: 5),
);
```

#### waitForText()

**Wait for specific text** to appear:

```dart
await AutomatedTestTemplate.waitForText(
  tester,
  'Ballet Beginners',
  timeout: Duration(seconds: 5),
);
```

#### waitForKey()

**Wait for element by key** to appear:

```dart
await AutomatedTestTemplate.waitForKey(
  tester,
  Key('course-list'),
  timeout: Duration(seconds: 5),
);
```

### Scrolling Operations

#### scrollToElement()

**Scroll to find and display element**:

```dart
await AutomatedTestTemplate.scrollToElement(
  tester,
  find.text('Advanced Contemporary'),
  scrollable: find.byType(ListView),
  delta: -200.0,
  maxScrolls: 10,
);
```

### Screenshot Capture

#### takeUXScreenshot()

**Cross-platform screenshot capture** for UX documentation:

```dart
await AutomatedTestTemplate.takeUXScreenshot(tester, 'course_list_page');
```

**Features:**
- **Cross-platform support**: Android, iOS, Web
- **Automatic UI settling**: Ensures UI is stable before capture
- **Proper file naming**: Screenshots saved to `build/screenshots/`
- **Flutter drive integration**: Works with proper screenshot commands

**Usage for UX Documentation:**
```bash
# Take screenshots that actually work
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/flows/course_group_ux_review_test.dart -d emulator-5554
```

#### takeScreenshot()

**Fast mode screenshot** (skips capture in performance tests):

```dart
await AutomatedTestTemplate.takeScreenshot(
  tester,
  'debug_screenshot',
  inFastMode: true, // Skips actual capture for speed
);
```

## 🎯 **Usage Patterns**

### UX Validation Testing

```dart
testWidgets('Complete UX validation', (tester) async {
  // Step 1: Log test start
  await AutomatedTestTemplate.logPageInfo(tester, 'Course List UX Review');
  
  // Step 2: Detect current state
  final currentPage = await AutomatedTestTemplate.detectCurrentPage(tester);
  expect(currentPage, isNot('Unknown Page'));
  
  // Step 3: Take baseline screenshot
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'baseline_state');
  
  // Step 4: Test interactions with waiting
  await AutomatedTestTemplate.waitForText(tester, 'Ballet Beginners');
  await AutomatedTestTemplate.tapButton(tester, 'View Details');
  
  // Step 5: Verify and capture result
  await AutomatedTestTemplate.waitForText(tester, 'Course Details');
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'details_loaded');
});
```

### Form Testing with Utilities

```dart
testWidgets('Registration form with utilities', (tester) async {
  // Navigate and verify page
  final page = await AutomatedTestTemplate.detectCurrentPage(tester);
  expect(page, 'Login Page');
  
  // Fill form using utilities
  await AutomatedTestTemplate.enterText(
    tester,
    key: Key('first-name'),
    text: 'John',
  );
  
  await AutomatedTestTemplate.enterText(
    tester,
    key: Key('last-name'),
    text: 'Doe',
  );
  
  await AutomatedTestTemplate.enterText(
    tester,
    key: Key('email'),
    text: 'john.doe@example.com',
  );
  
  // Submit and wait for response
  await AutomatedTestTemplate.tapButton(tester, 'Create Account');
  await AutomatedTestTemplate.waitForText(tester, 'Registration Successful');
  
  // Document the result
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'registration_complete');
});
```

### Scroll Testing

```dart
testWidgets('Long list interaction', (tester) async {
  await AutomatedTestTemplate.logPageInfo(tester, 'Course List Scrolling');
  
  // Find an element that might require scrolling
  try {
    await AutomatedTestTemplate.scrollToElement(
      tester,
      find.text('Advanced Contemporary'),
      maxScrolls: 15,
    );
    
    // Element found - interact with it
    await AutomatedTestTemplate.tapButton(tester, 'Book Now');
    await AutomatedTestTemplate.takeUXScreenshot(tester, 'advanced_course_booking');
    
  } catch (e) {
    print('Advanced course not found in list: $e');
    await AutomatedTestTemplate.takeUXScreenshot(tester, 'course_list_end');
  }
});
```

### Debug Information Gathering

```dart
testWidgets('Debug test state', (tester) async {
  // Gather comprehensive debug info
  await AutomatedTestTemplate.logPageInfo(tester, 'Debug Analysis');
  
  // Check what page we're actually on
  final currentPage = await AutomatedTestTemplate.detectCurrentPage(tester);
  print('Detected page: $currentPage');
  
  // Take screenshot for visual debugging
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'debug_current_state');
  
  // Try waiting for expected content
  try {
    await AutomatedTestTemplate.waitForText(
      tester,
      'Expected Content',
      timeout: Duration(seconds: 3),
    );
    print('✅ Expected content found');
  } catch (e) {
    print('⚠️  Expected content not found: $e');
    
    // Document what we actually see
    await AutomatedTestTemplate.takeUXScreenshot(tester, 'debug_unexpected_state');
  }
});
```

## 🧪 **Advanced Usage**

### Cross-Platform Screenshot Testing

```dart
testWidgets('Multi-platform visual validation', (tester) async {
  // Works on Android, iOS, and Web
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'platform_baseline');
  
  // Perform actions
  await AutomatedTestTemplate.tapButton(tester, 'Filter Courses');
  await AutomatedTestTemplate.waitForElement(tester, find.byType(DropdownButton));
  
  // Capture result across platforms
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'platform_filtered_state');
});
```

### Performance Testing with Screenshots

```dart
testWidgets('Performance test with visual validation', (tester) async {
  final stopwatch = Stopwatch()..start();
  
  // Fast operations without screenshots
  await AutomatedTestTemplate.takeScreenshot(
    tester,
    'performance_start',
    inFastMode: true, // Skips actual capture for speed
  );
  
  // Perform timed operations
  await AutomatedTestTemplate.tapButton(tester, 'Load Courses');
  await AutomatedTestTemplate.waitForText(tester, 'Ballet Beginners');
  
  stopwatch.stop();
  print('Operation completed in: ${stopwatch.elapsedMilliseconds}ms');
  
  // Take actual screenshot only at end
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'performance_complete');
});
```

## ✅ **Best Practices**

### 1. Use Appropriate Methods

```dart
// ✅ GOOD - Use specific methods for specific needs
await AutomatedTestTemplate.waitForText(tester, 'Course Details');
await AutomatedTestTemplate.tapButton(tester, 'Book Now');

// ❌ AVOID - Manual waiting and tapping
await tester.tap(find.text('Book Now'));
await tester.pumpAndSettle(); // May not wait long enough
```

### 2. Take Screenshots at Key Points

```dart
// ✅ GOOD - Document important test states
await AutomatedTestTemplate.takeUXScreenshot(tester, 'before_action');
// Perform action
await AutomatedTestTemplate.takeUXScreenshot(tester, 'after_action');

// ❌ AVOID - No visual documentation of test progress
```

### 3. Use Page Detection for Verification

```dart
// ✅ GOOD - Verify you're on the expected page
final currentPage = await AutomatedTestTemplate.detectCurrentPage(tester);
expect(currentPage, 'Course Groups');

// ❌ AVOID - Assuming you're on the right page
// Test may run on wrong page without detection
```

### 4. Combine with Other Helpers

```dart
// ✅ GOOD - Use template utilities with main helpers
await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
await AutomatedTestTemplate.logPageInfo(tester, 'Course List Test');
final authResult = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
await AutomatedTestTemplate.takeUXScreenshot(tester, 'authenticated_state');
```

## 📋 **Migration from Manual Operations**

### Before (Manual Operations)

```dart
testWidgets('Manual test operations', (tester) async {
  // Manual screenshot attempt (often fails)
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await binding.takeScreenshot('manual_screenshot');
  
  // Manual waiting (unreliable)
  await tester.pumpAndSettle(Duration(seconds: 3));
  
  // Manual scrolling (complex)
  final scrollable = find.byType(ListView);
  await tester.drag(scrollable, Offset(0, -300));
  await tester.pumpAndSettle();
  
  // Manual element waiting (error-prone)
  for (int i = 0; i < 10; i++) {
    if (find.text('Target').evaluate().isNotEmpty) break;
    await tester.pump(Duration(milliseconds: 100));
  }
});
```

### After (Using AutomatedTestTemplate)

```dart
testWidgets('Template-based test operations', (tester) async {
  // Reliable cross-platform screenshots
  await AutomatedTestTemplate.takeUXScreenshot(tester, 'test_start');
  
  // Smart element waiting
  await AutomatedTestTemplate.waitForText(tester, 'Target');
  
  // Intelligent scrolling
  await AutomatedTestTemplate.scrollToElement(tester, find.text('Target'));
  
  // Comprehensive page detection
  final page = await AutomatedTestTemplate.detectCurrentPage(tester);
  expect(page, isNot('Unknown Page'));
});
```

**Benefits:**
- **90% less code** for common operations
- **Cross-platform compatibility** for screenshots
- **Intelligent waiting** with proper timeouts
- **Automatic error handling** with meaningful messages
- **Comprehensive logging** for debugging

The AutomatedTestTemplate provides essential utilities that make integration tests more reliable, debuggable, and maintainable across all testing scenarios.