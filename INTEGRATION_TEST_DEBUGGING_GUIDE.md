# 🔧 UKCPA Flutter Integration Test Debugging Guide

**Created:** August 6, 2025  
**Purpose:** Comprehensive guide for debugging Flutter integration test issues  
**Audience:** Claude Code, developers, and QA teams  

---

## 📋 Quick Debugging Checklist

When integration tests fail, follow this systematic approach:

### 1. **Identify the Failure Phase**
```bash
# Check where the test fails
flutter test integration_test/flows/your_test.dart --verbose
```

**Common Failure Phases:**
- ❌ **Loading Phase**: "loading test.dart" - Build/environment issues
- ❌ **Initialization Phase**: "pumping widget" - App setup problems  
- ❌ **Execution Phase**: "test running" - UI/logic issues
- ❌ **Assertion Phase**: "expect() failing" - Test expectation mismatches

### 2. **App Initialization Issues (Most Common)**

**🚨 CRITICAL:** UKCPAApp requires proper initialization before testing:

```dart
// ✅ CORRECT initialization pattern
await dotenv.load(fileName: ".env");
await Hive.initFlutter();
await initHiveForFlutter();
await tester.pumpWidget(ProviderScope(child: UKCPAApp()));
await tester.pumpAndSettle(Duration(seconds: 8));

// ❌ WRONG - will cause NotInitializedError
await tester.pumpWidget(ProviderScope(child: UKCPAApp()));
```

### 3. **Backend Connectivity Check**
```bash
# Ensure UKCPA-Server is running
pgrep -f "UKCPA-Server.*dev"  # Should return a process ID
curl http://localhost:4000/graphql  # Should return GraphQL playground
```

---

## 🕵️ Systematic Investigation Methodology

### Step 1: Create Isolation Tests

When debugging complex test failures, create simple tests to isolate the problem:

#### **Environment Test Template**
```dart
// File: integration_test/flows/debug_environment_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DEBUG: Basic widget pumping', (tester) async {
    print('Testing basic Flutter widget pumping...');
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Text('Debug Test'),
        ),
      ),
    );
    
    await tester.pumpAndSettle();
    expect(find.text('Debug Test'), findsOneWidget);
    print('✅ Basic widget pumping works');
  });
}
```

#### **App Initialization Test Template**
```dart
// File: integration_test/flows/debug_initialization_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DEBUG: App initialization', (tester) async {
    print('Step 1: Loading environment...');
    await dotenv.load(fileName: ".env");
    
    print('Step 2: Initializing Hive...');
    await Hive.initFlutter();
    await initHiveForFlutter();
    
    print('Step 3: Pumping UKCPAApp...');
    await tester.pumpWidget(ProviderScope(child: UKCPAApp()));
    
    print('Step 4: Waiting for settle...');
    await tester.pumpAndSettle(Duration(seconds: 8));
    
    print('Step 5: Checking for errors...');
    final errors = find.byType(ErrorWidget);
    if (errors.evaluate().isNotEmpty) {
      final errorWidget = tester.widget<ErrorWidget>(errors.first);
      print('❌ Error found: ${errorWidget.message}');
      throw Exception('App has errors: ${errorWidget.message}');
    }
    
    print('✅ App initialized successfully');
  });
}
```

### Step 2: Progressive Complexity Testing

Build up test complexity gradually:

1. **Basic Widget** → **App Shell** → **Full App** → **Feature Tests**
2. Test each layer before moving to the next
3. Document what works at each level

---

## 🐛 Common Issues and Solutions

### Issue 1: "NotInitializedError"

**Symptoms:**
- Test shows ErrorWidget with "Instance of 'NotInitializedError'"
- App fails to start properly

**Root Cause:** Missing app initialization (dotenv/Hive)

**Solution:**
```dart
// Add before pumping UKCPAApp
await dotenv.load(fileName: ".env");
await Hive.initFlutter();
await initHiveForFlutter();
```

**Debug Command:**
```bash
# Create environment test to isolate issue
flutter test integration_test/flows/debug_environment_test.dart
```

---

### Issue 2: Test Timeouts During Loading

**Symptoms:**
- Test hangs at "loading test.dart"
- Never reaches actual test execution
- Xcode build completes but test doesn't start

**Root Causes:**
- iOS Simulator issues
- Xcode build cache corruption
- Flutter build artifacts corruption

**Solutions (in order):**

1. **Clean Flutter Environment:**
```bash
flutter clean
flutter pub get
```

2. **Restart iOS Simulator:**
```bash
# Kill simulator processes
killall "Simulator"
# Restart simulator from Xcode or command line
open -a Simulator
```

3. **Reset Flutter Test Environment:**
```bash
flutter clean
rm -rf ios/build
rm -rf build
flutter pub get
```

4. **Check Available Simulators:**
```bash
xcrun simctl list devices available
```

---

### Issue 3: Widget Not Found Errors

**Symptoms:**
- `expect(find.byKey(Key('widget-key')), findsOneWidget)` fails
- "No widget found with key" errors

**Investigation Steps:**

1. **Check if app loaded properly:**
```dart
// Add before widget searches
final allWidgets = find.byType(Widget);
print('Total widgets found: ${allWidgets.evaluate().length}');

if (allWidgets.evaluate().isEmpty) {
  throw Exception('No widgets found - app may not have loaded');
}
```

2. **Debug widget tree:**
```dart
// Find all text widgets to see what's on screen
final texts = find.byType(Text);
print('Text widgets found: ${texts.evaluate().length}');

for (int i = 0; i < texts.evaluate().length && i < 10; i++) {
  final widget = tester.widget<Text>(texts.at(i));
  final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
  print('Text $i: "$text"');
}
```

3. **Check for error states:**
```dart
// Look for error widgets
final errors = find.byType(ErrorWidget);
if (errors.evaluate().isNotEmpty) {
  final errorWidget = tester.widget<ErrorWidget>(errors.first);
  print('Error found: ${errorWidget.message}');
}
```

**Common Solutions:**
- Add missing widget keys to UI components
- Verify widget exists in current app state
- Check if navigation occurred (widget might be on different screen)

---

### Issue 4: GraphQL/Network Issues

**Symptoms:**
- Auth tests fail with network errors
- "No user data returned from server" logs
- Connection refused errors

**Investigation Steps:**

1. **Verify Backend Status:**
```bash
# Check if UKCPA-Server is running
pgrep -f "UKCPA-Server.*dev"

# Test GraphQL endpoint
curl -X POST http://localhost:4000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "query { __typename }"}'
```

2. **Check GraphQL Client Configuration:**
```dart
// Look for GraphQL client debug logs in test output
// Should see: "🐛 Adding UKCPA site ID header to GraphQL request"
// Should see: "🐛 Auth token found for GraphQL request"
```

3. **Test Database Connection:**
```bash
# Connect to development database
psql postgresql://postgres@localhost:5433/dancehub
# Check if test user exists
SELECT id, email FROM users WHERE email = 'test@ukcpa';
```

**Solutions:**
- Start UKCPA-Server: `cd UKCPA-Server && yarn start:dev`
- Create test user if missing (see INTEGRATION_TEST_FIX_SUMMARY.md)
- Verify GraphQL endpoint configuration in .env file

---

## 🛠️ Advanced Debugging Techniques

### Technique 1: Step-by-Step State Logging

```dart
testWidgets('DEBUG: Step-by-step execution', (tester) async {
  print('=== Starting test execution ===');
  
  try {
    print('Step 1: Environment setup');
    await dotenv.load(fileName: ".env");
    print('✓ Environment loaded');
    
    print('Step 2: Hive initialization');  
    await Hive.initFlutter();
    await initHiveForFlutter();
    print('✓ Hive initialized');
    
    print('Step 3: App pumping');
    await tester.pumpWidget(ProviderScope(child: UKCPAApp()));
    print('✓ App pumped');
    
    print('Step 4: First pump');
    await tester.pump();
    print('✓ First pump complete');
    
    print('Step 5: Checking immediate state');
    final immediateWidgets = find.byType(Widget);
    print('Immediate widgets: ${immediateWidgets.evaluate().length}');
    
    print('Step 6: Pump and settle');
    await tester.pumpAndSettle(Duration(seconds: 8));
    print('✓ Pump and settle complete');
    
    print('Step 7: Final state check');
    final finalWidgets = find.byType(Widget);
    print('Final widgets: ${finalWidgets.evaluate().length}');
    
  } catch (e, stackTrace) {
    print('❌ Error at current step: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});
```

### Technique 2: Network Call Monitoring

```dart
// Monitor GraphQL calls during test
testWidgets('DEBUG: Network monitoring', (tester) async {
  // Initialize app
  await initializeApp(tester);
  
  print('Starting network call monitoring...');
  
  // Trigger network call (like login attempt)
  await tester.enterText(find.byKey(Key('email-field')), 'test@ukcpa');
  await tester.enterText(find.byKey(Key('password-field')), 'password123');
  await tester.tap(find.text('Sign In'));
  
  // Monitor network activity over time
  for (int i = 0; i < 10; i++) {
    await tester.pump(Duration(milliseconds: 500));
    
    print('Network check ${i+1}: Looking for loading indicators...');
    final loading = find.byType(CircularProgressIndicator);
    if (loading.evaluate().isNotEmpty) {
      print('  → Network call in progress');
    }
  }
});
```

### Technique 3: Widget Tree Analysis

```dart
void debugWidgetTree(WidgetTester tester) {
  print('\n=== Widget Tree Analysis ===');
  
  // Count widgets by type
  final scaffolds = find.byType(Scaffold);
  final textFields = find.byType(TextField);
  final buttons = find.byType(ElevatedButton);
  final texts = find.byType(Text);
  
  print('Scaffolds: ${scaffolds.evaluate().length}');
  print('TextFields: ${textFields.evaluate().length}');
  print('ElevatedButtons: ${buttons.evaluate().length}');
  print('Text widgets: ${texts.evaluate().length}');
  
  // List first 10 text contents
  print('\nText widget contents:');
  for (int i = 0; i < texts.evaluate().length && i < 10; i++) {
    final widget = tester.widget<Text>(texts.at(i));
    final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    if (text.isNotEmpty && text.length < 100) {
      print('  ${i+1}. "$text"');
    }
  }
  
  print('=========================\n');
}
```

---

## 📐 Test Architecture Best Practices

### Pattern 1: Reliable Initialization Helper

Create a reusable initialization function:

```dart
// File: integration_test/helpers/test_app_initializer.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';

class TestAppInitializer {
  static Future<void> initialize(WidgetTester tester) async {
    print('🔧 Initializing UKCPA app for testing...');
    
    // Load environment
    await dotenv.load(fileName: ".env");
    print('✓ Environment variables loaded');
    
    // Initialize storage
    await Hive.initFlutter();
    await initHiveForFlutter();
    print('✓ Storage initialized');
    
    // Pump app
    await tester.pumpWidget(
      const ProviderScope(child: UKCPAApp()),
    );
    print('✓ App widget pumped');
    
    // Wait for initialization
    await tester.pumpAndSettle(const Duration(seconds: 8));
    print('✓ App initialized and ready');
    
    // Verify no errors
    final errors = find.byType(ErrorWidget);
    if (errors.evaluate().isNotEmpty) {
      final errorWidget = tester.widget<ErrorWidget>(errors.first);
      throw Exception('App initialization failed: ${errorWidget.message}');
    }
    
    print('🎉 App ready for testing!');
  }
}
```

**Usage:**
```dart
testWidgets('My test', (tester) async {
  await TestAppInitializer.initialize(tester);
  
  // Your test logic here
  expect(find.text('Sign in to your account'), findsOneWidget);
});
```

### Pattern 2: Debugging Test Template

```dart
// File: integration_test/flows/debug_template.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/test_app_initializer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DEBUG: [Description of what you\'re testing]', (tester) async {
    print('\n🔍 DEBUG SESSION: [Test Name]');
    print('=====================================');
    
    try {
      // Step 1: Initialize app
      print('Step 1: Initializing app...');
      await TestAppInitializer.initialize(tester);
      
      // Step 2: Debug your specific issue
      print('Step 2: Testing specific functionality...');
      // Add your debug code here
      
      // Step 3: Document findings
      print('✅ Debug session completed successfully');
      
    } catch (e, stackTrace) {
      print('❌ Debug session failed: $e');
      print('Stack trace: $stackTrace');
      
      // Try to capture current state for analysis
      try {
        final allTexts = find.byType(Text);
        print('Current screen text elements:');
        for (int i = 0; i < allTexts.evaluate().length && i < 5; i++) {
          final widget = tester.widget<Text>(allTexts.at(i));
          final text = widget.data ?? '';
          if (text.isNotEmpty) {
            print('  - "$text"');
          }
        }
      } catch (_) {
        print('Could not capture current state');
      }
      
      rethrow;
    }
  });
}
```

---

## 🚀 Environment Setup Checklist

Before running integration tests, verify:

### Backend Requirements
- [ ] UKCPA-Server running on port 4000
- [ ] PostgreSQL running on port 5433
- [ ] Test user exists in database (test@ukcpa / password123)
- [ ] GraphQL playground accessible at http://localhost:4000/graphql

### Flutter Environment
- [ ] .env file exists with required variables
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] iOS Simulator running and accessible
- [ ] No cached build issues (`flutter clean` if needed)

### Quick Environment Check Script
```bash
#!/bin/bash
# File: test/integration/scripts/check_environment.sh

echo "🔍 Checking integration test environment..."

# Check backend server
if pgrep -f "UKCPA-Server.*dev" > /dev/null; then
  echo "✅ UKCPA-Server is running"
else
  echo "❌ UKCPA-Server is not running"
  echo "   Start with: cd UKCPA-Server && yarn start:dev"
fi

# Check GraphQL endpoint
if curl -s http://localhost:4000/graphql > /dev/null; then
  echo "✅ GraphQL endpoint accessible"
else
  echo "❌ GraphQL endpoint not accessible"
fi

# Check PostgreSQL
if pg_isready -h localhost -p 5433 > /dev/null 2>&1; then
  echo "✅ PostgreSQL is running"
else
  echo "❌ PostgreSQL is not running or not accessible"
fi

# Check Flutter environment
if [ -f ".env" ]; then
  echo "✅ .env file exists"
else
  echo "❌ .env file missing"
fi

# Check iOS Simulator
if xcrun simctl list devices available | grep -q "iPhone.*Booted"; then
  echo "✅ iOS Simulator is running"
else
  echo "❌ No iOS Simulator running"
fi

echo "Environment check complete!"
```

---

## 📖 Troubleshooting Quick Reference

| **Symptom** | **Likely Cause** | **Quick Fix** |
|-------------|------------------|---------------|
| Test hangs at "loading" | Build/simulator issue | `flutter clean && flutter pub get` |
| "NotInitializedError" | Missing app initialization | Add dotenv + Hive setup |
| "Widget not found" | Missing widget keys or wrong state | Debug widget tree with `debugWidgetTree()` |
| Network errors | Backend not running | Check `pgrep -f UKCPA-Server` |
| Build errors | Dependency issues | `flutter clean && flutter pub get` |
| Simulator not responding | Simulator problems | Restart simulator |
| GraphQL errors | Server/database issues | Verify backend + database running |

---

## 🎯 Success Metrics

A properly working integration test should:

1. ✅ **Complete initialization in < 15 seconds**
2. ✅ **Find all expected UI elements**
3. ✅ **Successfully connect to GraphQL backend**
4. ✅ **Handle user interactions correctly**
5. ✅ **Provide clear error messages when failing**
6. ✅ **Run consistently (pass 3+ times in a row)**

---

## 📝 Documentation Standards

When documenting test fixes:

1. **Record the symptom** - Exact error message or behavior
2. **Document investigation steps** - What you tried and what worked
3. **Provide the solution** - Working code with explanation
4. **Add prevention measures** - How to avoid this issue in future
5. **Include verification** - How to confirm the fix works

**Template:**
```markdown
## Issue: [Brief description]

**Symptom:** [Exact error/behavior]

**Root Cause:** [Technical explanation]

**Investigation Steps:**
1. [What was tried first]
2. [What led to the discovery]
3. [How the solution was verified]

**Solution:**
```code
[Working solution]
```

**Prevention:** [How to avoid this in future]

**Verification:** [How to test the fix]
```

---

## 🔄 Continuous Improvement

This guide should be updated when:

- ✅ New integration test patterns are discovered
- ✅ Common issues are identified and solved
- ✅ Test architecture improvements are made
- ✅ Environment setup changes occur
- ✅ New debugging techniques prove effective

**Keep this guide as the single source of truth for integration test debugging in the UKCPA Flutter project.**

---

*Last Updated: August 6, 2025*  
*Contributors: Claude Code (Initial comprehensive investigation and documentation)*