# Quick Start: Ultra-Fast Integration Tests

**🎯 Goal:** Create integration tests that run in 2-4 seconds instead of 60+ seconds while testing real functionality.

## 🚀 Copy-Paste Template

### 1. Basic Ultra-Fast Test Structure

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/mock_fast_test_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  MockedFastTestManager.createMockedTestBatch(
    'Ultra-Fast [Your Feature] Tests',
    {
      'should test your feature quickly': (tester) async {
        // Log page information for reports
        await AutomatedTestTemplate.logPageInfo(tester, '[Target Page Name]');
        
        // Your test code here - focuses on UI behavior
        expect(find.text('Expected Text'), findsOneWidget);
        
        await FastAutomatedTestTemplate.tapButton(tester, 'Button Text');
        await FastAutomatedTestTemplate.waitForUI(tester);
        
        expect(find.text('Result Text'), findsOneWidget);
        
        // Capture screenshot for documentation
        await AutomatedTestTemplate.takeUXScreenshot(tester, 'feature_name_screenshot');
        
        print('✅ Your test complete (mocked)');
      },
    },
    requiresAuth: false, // Set to true if testing post-login features
  );
}
```

### 2. Running Your Test

```bash
flutter test integration_test/flows/your_test_name.dart -d emulator-5554
```

## ⚡ Key Patterns

### Authentication Test
```dart
'should handle login flow': (tester) async {
  await FastAutomatedTestTemplate.enterText(tester, key: const Key('email-field'), text: 'test@example.com');
  await FastAutomatedTestTemplate.enterText(tester, key: const Key('password-field'), text: 'password');
  await FastAutomatedTestTemplate.tapButton(tester, 'Sign In');
  await FastAutomatedTestTemplate.waitForUI(tester);
  
  // Should navigate away from login
  expect(find.text('Sign in to your account'), findsNothing);
},
```

### Navigation Test
```dart
'should navigate to feature screen': (tester) async {
  // Check current screen
  final indicators = [find.text('Feature Screen'), find.text('Dashboard'), find.text('Home')];
  
  bool foundScreen = false;
  for (final indicator in indicators) {
    if (indicator.evaluate().isNotEmpty) {
      foundScreen = true;
      print('✅ Found screen: ${indicator.description}');
      break;
    }
  }
  expect(foundScreen, isTrue);
},
```

### Interaction Test
```dart
'should handle user interactions': (tester) async {
  final interactiveElements = [find.byType(Card), find.byType(ListTile), find.byType(ElevatedButton)];
  
  for (final element in interactiveElements) {
    if (element.evaluate().isNotEmpty) {
      await tester.tap(element.first);
      await FastAutomatedTestTemplate.waitForUI(tester);
      print('✅ Interaction successful');
      break;
    }
  }
},
```

## 🎯 Speed Tips

### ✅ DO
- Use `FastAutomatedTestTemplate` methods (100ms delays)
- Test UI behavior and navigation
- Mock backend dependencies
- Focus on user interactions
- Keep assertions flexible but meaningful

### ❌ DON'T  
- Use long `Duration(seconds: 3)` waits
- Make real GraphQL/API calls
- Test backend business logic
- Use rigid assertions that break easily
- Test authentication server validation

## 🔧 Common Fixes

### "Test finds login screen instead of feature screen"
```dart
// Problem: Mock auth returns null (unauthenticated)
Future<User?> getCurrentUser() async => null; // ❌

// Solution: Return authenticated user
Future<User?> getCurrentUser() async => User(id: '123', email: 'test@example.com'); // ✅
```

### "Test takes too long"
```dart
// Problem: Long waits
await tester.pumpAndSettle(const Duration(seconds: 3)); // ❌

// Solution: Minimal waits
await FastAutomatedTestTemplate.waitForUI(tester); // ✅ (200ms)
```

### "Test is flaky"
```dart
// Problem: Rigid assertions
expect(find.text('Exact Text'), findsOneWidget); // ❌

// Solution: Flexible assertions
final indicators = [find.text('Option 1'), find.text('Option 2'), find.text('Option 3')];
bool found = indicators.any((i) => i.evaluate().isNotEmpty);
expect(found, isTrue); // ✅
```

## 📊 Success Metrics

- **Target Speed:** 2-4 seconds per test
- **Target Suite:** <30 seconds for 7 tests  
- **Functionality:** Tests reach correct screens and test real interactions
- **Reliability:** Consistent pass/fail results

## 🎉 Examples That Work

- **Authentication:** `ultra_fast_auth_test.dart` (30s for 7 tests)
- **Course Discovery:** `ultra_fast_course_discovery_test.dart` (27s for 7 tests)
- **Pattern:** Works for any feature requiring backend data

## 📸 Page Detection & Screenshots (NEW!)

### Automatic Page Detection
```dart
// Automatically logs current page and route
await AutomatedTestTemplate.logPageInfo(tester, 'Target Page Name');
// Output:
// 📋 TEST TARGET: Target Page Name
// 🕐 TIMESTAMP: 2024-01-15 10:30:45
// 📱 PLATFORM: Flutter Integration Test
// 📍 ACTUAL PAGE: Course Groups
// 🔗 Route: /courses
```

### Screenshot Capture
```dart
// For UX/UI documentation (always captures)
await AutomatedTestTemplate.takeUXScreenshot(tester, 'screenshot_name');
// Screenshots saved to: build/screenshots/

// For regular tests (respects fast mode)
await AutomatedTestTemplate.takeScreenshot(tester, 'screenshot_name', inFastMode: false);
```

## 🆘 When You Need Help

1. **Check existing examples** in `integration_test/flows/ultra_fast_*.dart`
2. **Read full guide** in `ULTRA_FAST_TESTING_GUIDE.md`  
3. **Debug with logging:**
   ```dart
   print('🔍 Current screen elements:');
   final allText = find.byType(Text);
   for (int i = 0; i < allText.evaluate().length && i < 5; i++) {
     final widget = tester.widget<Text>(allText.at(i));
     print('   - "${widget.data}"');
   }
   ```

---

**Remember:** Ultra-fast tests trade backend validation for speed and UI behavior testing. Use them for rapid development feedback, not for backend integration validation.