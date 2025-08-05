# UKCPA Flutter - Integration Test Automation Flows

This document contains predefined automation flows for testing and debugging the UKCPA Flutter app using Flutter's integration testing framework.

## Integration Test Commands

### 1. Run Complete Smoke Tests
```bash
# Run comprehensive integration tests
cd ukcpa_flutter
./test/integration/scripts/run_smoke_tests.sh

# Or run specific integration tests
flutter test test/integration/tests/comprehensive_smoke_test.dart

# Run with device (for real device testing)
flutter test test/integration/tests/ -d chrome
flutter test test/integration/tests/ -d macos
```

### 2. Login Flow Testing (Flutter Integration Test Code)
```dart
// Start the app
app.main();
await tester.pumpAndSettle();

// Find and fill email field
await tester.enterText(find.byKey(const Key('email-field')), 'test@ukcpa.com');

// Find and fill password field  
await tester.enterText(find.byKey(const Key('password-field')), 'testpassword');

// Tap login button
await tester.tap(find.text('Sign In'));
await tester.pumpAndSettle();

// Take screenshot
await binding.convertFlutterSurfaceToImage();
```

### 3. Responsive Design Testing
```dart
// Test different screen sizes
final screenSizes = [
  {'name': 'Mobile', 'size': const Size(375, 667)},
  {'name': 'Tablet', 'size': const Size(768, 1024)},
  {'name': 'Desktop', 'size': const Size(1200, 800)},
];

for (final screen in screenSizes) {
  // Set screen size
  binding.window.physicalSizeTestValue = screen['size'] as Size;
  await tester.pumpAndSettle();
  
  // Take screenshot
  await binding.convertFlutterSurfaceToImage();
  
  // Test that UI elements are still visible
  expect(find.byType(MaterialApp), findsOneWidget);
}
```

### 4. Form Validation Testing
```dart
// Test empty form submission
app.main();
await tester.pumpAndSettle();

// Try to submit without filling fields
await tester.tap(find.text('Sign In'));
await tester.pumpAndSettle();

// Should still be on login screen
expect(find.text('Welcome Back'), findsOneWidget);

// Test invalid email
await tester.enterText(find.byKey(const Key('email-field')), 'invalid-email');
await tester.tap(find.text('Sign In'));
await tester.pumpAndSettle();

// Should show validation error or stay on screen
expect(find.text('Welcome Back'), findsOneWidget);
```

### 5. Navigation Testing
```dart
// Test navigation between screens
app.main();
await tester.pumpAndSettle();

// Navigate to different screens if available
final navigationItems = [
  find.text('Home'),
  find.text('Courses'),
  find.text('Account'),
  find.byIcon(Icons.home),
  find.byIcon(Icons.school),
];

for (final item in navigationItems) {
  if (item.evaluate().isNotEmpty) {
    await tester.tap(item);
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
  }
}
```

### 6. Performance Testing
```dart
// Measure app startup time
final startTime = DateTime.now();

app.main();
await tester.pumpAndSettle();

final loadTime = DateTime.now().difference(startTime).inMilliseconds;
print('App loaded in ${loadTime}ms');

// Test rapid interactions
for (int i = 0; i < 10; i++) {
  final buttons = find.byType(ElevatedButton);
  if (buttons.evaluate().isNotEmpty) {
    await tester.tap(buttons.first);
    await tester.pump(); // Single pump for immediate response
  }
}
```

### 7. Real User Journey Testing
```dart
// Complete user flow test
app.main();
await tester.pumpAndSettle();

// Step 1: App launch
await binding.convertFlutterSurfaceToImage(); // Screenshot: app_launch

// Step 2: Login attempt
await tester.enterText(find.byType(TextField).first, 'test@example.com');
await binding.convertFlutterSurfaceToImage(); // Screenshot: email_entered

// Step 3: Password entry
if (find.byType(TextField).evaluate().length > 1) {
  await tester.enterText(find.byType(TextField).at(1), 'password');
  await binding.convertFlutterSurfaceToImage(); // Screenshot: password_entered
}

// Step 4: Submit form
final submitButton = find.byType(ElevatedButton);
if (submitButton.evaluate().isNotEmpty) {
  await tester.tap(submitButton.first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
  await binding.convertFlutterSurfaceToImage(); // Screenshot: form_submitted
}

// Step 5: Final state
await binding.convertFlutterSurfaceToImage(); // Screenshot: final_state
```

## Test Configuration

### Test Credentials
- **Email**: `test@ukcpa.com`
- **Password**: `testpassword`
- **Alternative**: `info@carl-stanley.com` / `password`

### Screenshot Configuration
- Screenshots are automatically saved to `test/integration/results/screenshots/`
- Each test step captures the current UI state
- Multiple screen sizes tested for responsive design

### Integration Test Best Practices

1. **Use `pumpAndSettle()`** - Wait for animations to complete
2. **Add delays for async operations** - `pumpAndSettle(Duration(seconds: 2))`
3. **Use widget keys** - Add `Key('widget-name')` to important widgets
4. **Test multiple strategies** - Use different finder methods as fallbacks
5. **Capture screenshots** - Document the UI state at each step
6. **Test error scenarios** - Empty forms, invalid input, network errors

### Common Integration Test Issues

1. **Widget not found** - Add proper keys to widgets in the app code
2. **Async operations** - Use appropriate waiting strategies
3. **State management** - Ensure providers are properly initialized
4. **Navigation** - Test that routing works correctly
5. **Form validation** - Verify error messages and behavior

### Running Tests in Different Environments

```bash
# Desktop testing
flutter test test/integration/tests/ -d chrome
flutter test test/integration/tests/ -d macos

# Mobile device testing (requires connected device)
flutter test test/integration/tests/ -d android
flutter test test/integration/tests/ -d ios

# Specific test file
flutter test test/integration/tests/comprehensive_smoke_test.dart -d chrome
```

This integration testing approach provides real UI validation with actual Flutter widget interactions, proper screenshot capture, and comprehensive user journey testing.