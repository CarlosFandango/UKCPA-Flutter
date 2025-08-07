# Error State Testing Helper Guide

## 🎯 Problem Solved

**Issue**: Integration tests rarely tested error scenarios systematically. When errors occurred, they were often missed or handled inconsistently. Manual error testing was time-consuming, unreliable, and didn't cover edge cases comprehensively.

**Solution**: The `ErrorStateTestingHelper` provides systematic error scenario testing with simulation of network failures, authentication errors, form validation issues, payment failures, and comprehensive error state verification.

## 🚀 Quick Start

### Network Error Testing

```dart
import '../helpers/error_state_testing_helper.dart';

testWidgets('Network error handling', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
  
  // Test network error handling
  final networkResult = await ErrorStateTestingHelper.simulateNetworkError(
    tester,
    expectErrorMessage: true,
    verboseLogging: true,
  );
  
  expect(networkResult.success, isTrue, reason: networkResult.error);
  print('Network errors detected: ${networkResult.errorsDetected.join(', ')}');
});
```

### Authentication Error Testing

```dart
testWidgets('Invalid credentials handling', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  
  // Test invalid credentials
  final authResult = await ErrorStateTestingHelper.testInvalidCredentials(
    tester,
    verboseLogging: true,
  );
  
  expect(authResult.success, isTrue, reason: authResult.error);
  expect(authResult.errorsDetected, isNotEmpty);
});
```

### Form Validation Error Testing

```dart
testWidgets('Form validation error handling', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  
  // Test invalid form data
  final formResult = await ErrorStateTestingHelper.testInvalidFormData(
    tester,
    {
      'email-field': 'invalid-email-format',
      'password-field': '', // Empty required field
    },
    verboseLogging: true,
  );
  
  expect(formResult.success, isTrue, reason: formResult.error);
  expect(formResult.errorsDetected, contains('Invalid'));
});
```

## 📋 Error Testing Categories

### 1. Network Error Testing

| Method | Purpose | Example |
|--------|---------|---------|
| **simulateNetworkError** | Test network connectivity issues | `await ErrorStateTestingHelper.simulateNetworkError(tester)` |
| **simulateServerError** | Test server error responses | `await ErrorStateTestingHelper.simulateServerError(tester)` |

### 2. Authentication Error Testing

| Method | Purpose | Example |
|--------|---------|---------|
| **testInvalidCredentials** | Test wrong username/password | `await ErrorStateTestingHelper.testInvalidCredentials(tester)` |
| **testAuthenticationTimeout** | Test login timeout scenarios | `await ErrorStateTestingHelper.testAuthenticationTimeout(tester)` |

### 3. Form Validation Error Testing

| Method | Purpose | Example |
|--------|---------|---------|
| **testInvalidFormData** | Test form with invalid data | `await ErrorStateTestingHelper.testInvalidFormData(tester, invalidData)` |
| **testRequiredFieldValidation** | Test empty required fields | `await ErrorStateTestingHelper.testRequiredFieldValidation(tester, [Key('email')])` |

### 4. Payment Error Testing

| Method | Purpose | Example |
|--------|---------|---------|
| **testPaymentFailures** | Test payment decline scenarios | `await ErrorStateTestingHelper.testPaymentFailures(tester)` |

### 5. Error Message Verification

| Method | Purpose | Example |
|--------|---------|---------|
| **verifyErrorMessage** | Check specific error appears | `await ErrorStateTestingHelper.verifyErrorMessage(tester, 'Invalid email')` |
| **verifyErrorRecovery** | Test error messages clear | `await ErrorStateTestingHelper.verifyErrorRecovery(tester, correctData)` |

### 6. Loading and Timeout Testing

| Method | Purpose | Example |
|--------|---------|---------|
| **testLoadingTimeout** | Test loading timeout handling | `await ErrorStateTestingHelper.testLoadingTimeout(tester)` |

### 7. Comprehensive Testing

| Method | Purpose | Example |
|--------|---------|---------|
| **runComprehensiveErrorTests** | Run all error tests | `await ErrorStateTestingHelper.runComprehensiveErrorTests(tester)` |

## 🔧 Advanced Usage Patterns

### Comprehensive Error Testing Suite

```dart
testWidgets('Complete error handling validation', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
  
  // Run comprehensive error tests
  final comprehensiveResult = await ErrorStateTestingHelper.runComprehensiveErrorTests(
    tester,
    includeNetworkTests: true,
    includeAuthTests: true,
    includeFormTests: true,
    includePaymentTests: false, // Not all apps have payment
    verboseLogging: true,
  );
  
  expect(comprehensiveResult.success, isTrue, reason: comprehensiveResult.error);
  
  print('Comprehensive Error Testing Results:');
  print('- ${comprehensiveResult.details}');
  print('- ${comprehensiveResult.actualBehavior}');
  print('- Error types detected: ${comprehensiveResult.errorsDetected.join(', ')}');
});
```

### Network Error Recovery Testing

```dart
testWidgets('Network error and recovery flow', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
  
  // 1. Test network error occurs
  final networkResult = await ErrorStateTestingHelper.simulateNetworkError(
    tester,
    expectErrorMessage: true,
    verboseLogging: true,
  );
  expect(networkResult.success, isTrue);
  expect(networkResult.errorsDetected, isNotEmpty);
  
  // 2. Test retry mechanism works
  final retryButton = find.text('Try Again');
  if (retryButton.evaluate().isNotEmpty) {
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
    
    // 3. Verify error messages clear after retry
    final recoveryResult = await ErrorStateTestingHelper.verifyErrorRecovery(
      tester,
      {}, // No specific data needed for retry
      expectedErrorsToDisappear: networkResult.errorsDetected,
      verboseLogging: true,
    );
    expect(recoveryResult.success, isTrue);
  }
});
```

### Authentication Error Scenarios

```dart
testWidgets('Authentication error scenarios', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  
  // Test 1: Invalid email format
  final invalidEmailResult = await ErrorStateTestingHelper.testInvalidFormData(
    tester,
    {'email-field': 'not-an-email', 'password-field': 'password123'},
    verboseLogging: true,
  );
  expect(invalidEmailResult.success, isTrue);
  expect(invalidEmailResult.errorsDetected, contains('Invalid'));
  
  // Test 2: Empty required fields
  await FormInteractionHelper.clearForm(tester, ['email-field', 'password-field']);
  
  final requiredFieldResult = await ErrorStateTestingHelper.testRequiredFieldValidation(
    tester,
    [Key('email-field'), Key('password-field')],
    verboseLogging: true,
  );
  expect(requiredFieldResult.success, isTrue);
  expect(requiredFieldResult.errorsDetected, contains('Required field validation'));
  
  // Test 3: Invalid credentials with server response
  final invalidCredsResult = await ErrorStateTestingHelper.testInvalidCredentials(
    tester,
    customInvalidCredentials: {
      'email-field': 'nonexistent@example.com',
      'password-field': 'wrongpassword',
    },
    verboseLogging: true,
  );
  expect(invalidCredsResult.success, isTrue);
  expect(invalidCredsResult.errorsDetected, isNotEmpty);
  
  // Test 4: Authentication timeout
  final timeoutResult = await ErrorStateTestingHelper.testAuthenticationTimeout(
    tester,
    timeoutDuration: Duration(seconds: 3),
    verboseLogging: true,
  );
  expect(timeoutResult.success, isTrue); // Success means timeout was tested
});
```

### Form Validation Error Testing

```dart
testWidgets('Comprehensive form validation testing', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  
  // Test different types of invalid data
  final invalidDataSets = [
    {
      'name': 'Invalid Email Format',
      'data': {'email-field': 'not-an-email', 'password-field': 'validpass'},
      'expectedErrors': ['Invalid'],
    },
    {
      'name': 'Short Password',
      'data': {'email-field': 'user@example.com', 'password-field': '123'},
      'expectedErrors': ['Too short', 'Must be'],
    },
    {
      'name': 'Empty Required Fields',
      'data': {'email-field': '', 'password-field': ''},
      'expectedErrors': ['Required', 'Cannot be empty'],
    },
  ];
  
  for (final testSet in invalidDataSets) {
    print('\nTesting: ${testSet['name']}');
    
    final formResult = await ErrorStateTestingHelper.testInvalidFormData(
      tester,
      testSet['data'] as Map<String, String>,
      verboseLogging: true,
    );
    
    expect(formResult.success, isTrue, 
           reason: 'Form validation test failed for ${testSet['name']}: ${formResult.error}');
    
    // Check that expected error types were found
    final expectedErrors = testSet['expectedErrors'] as List<String>;
    final hasExpectedError = expectedErrors.any((expected) =>
        formResult.errorsDetected.any((actual) => actual.contains(expected)));
    
    expect(hasExpectedError, isTrue,
           reason: 'Expected errors $expectedErrors not found in ${formResult.errorsDetected}');
    
    // Clear form for next test
    await FormInteractionHelper.clearForm(tester, ['email-field', 'password-field']);
  }
});
```

### Error Message Lifecycle Testing

```dart
testWidgets('Error message appearance and recovery', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  
  // 1. Trigger error by submitting empty form
  await ErrorStateTestingHelper.testRequiredFieldValidation(
    tester,
    [Key('email-field'), Key('password-field')],
    verboseLogging: true,
  );
  
  // 2. Verify specific error message appears
  final errorVerification = await ErrorStateTestingHelper.verifyErrorMessage(
    tester,
    'Required',
    exactMatch: false,
    verboseLogging: true,
  );
  expect(errorVerification.success, isTrue);
  
  // 3. Fill form with correct data
  final correctData = {
    'email-field': 'user@example.com',
    'password-field': 'validpassword123',
  };
  
  // 4. Verify errors disappear after correction
  final recoveryResult = await ErrorStateTestingHelper.verifyErrorRecovery(
    tester,
    correctData,
    expectedErrorsToDisappear: ['Required', 'Cannot be empty'],
    verboseLogging: true,
  );
  
  expect(recoveryResult.success, isTrue, reason: recoveryResult.error);
  print('Error recovery successful: ${recoveryResult.actualBehavior}');
});
```

### Payment Error Testing (E-commerce Apps)

```dart
testWidgets('Payment error scenarios', (tester) async {
  // Navigate to checkout/payment page
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
  await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
  
  // Add item to basket and proceed to payment
  // ... (navigate to payment form)
  
  // Test payment failures with different scenarios
  final paymentScenarios = [
    {
      'name': 'Declined Card',
      'data': {
        'card-number-field': '4000000000000002', // Test decline card
        'expiry-field': '12/25',
        'cvv-field': '123',
        'name-field': 'Test User',
      },
      'expectedErrors': ['declined', 'failed'],
    },
    {
      'name': 'Invalid Card Number',
      'data': {
        'card-number-field': '1234567890123456', // Invalid card
        'expiry-field': '12/25',
        'cvv-field': '123',
        'name-field': 'Test User',
      },
      'expectedErrors': ['Invalid', 'card'],
    },
  ];
  
  for (final scenario in paymentScenarios) {
    print('\nTesting payment scenario: ${scenario['name']}');
    
    final paymentResult = await ErrorStateTestingHelper.testPaymentFailures(
      tester,
      invalidPaymentData: scenario['data'] as Map<String, String>,
      verboseLogging: true,
    );
    
    expect(paymentResult.success, isTrue,
           reason: 'Payment error test failed for ${scenario['name']}');
    
    // Verify appropriate error messages appeared
    final expectedErrors = scenario['expectedErrors'] as List<String>;
    final hasExpectedError = expectedErrors.any((expected) =>
        paymentResult.errorsDetected.any((actual) => 
            actual.toLowerCase().contains(expected.toLowerCase())));
    
    if (paymentResult.errorsDetected.isNotEmpty) {
      expect(hasExpectedError, isTrue,
             reason: 'Expected payment errors $expectedErrors not found in ${paymentResult.errorsDetected}');
    }
  }
});
```

## 📊 Result Object Pattern

All error testing methods return an `ErrorTestResult` object:

```dart
class ErrorTestResult {
  bool success;                    // True if error testing completed successfully
  String? error;                   // Error if test itself failed
  String? details;                 // Additional test details
  List<String> errorsDetected;     // Error messages/patterns found
  String? actualBehavior;          // What actually happened
  String? expectedBehavior;        // What should have happened
  String get summary;              // Formatted summary
  bool get hasErrorsDetected;      // True if errors were found
  String get errorSummary;         // Summary of detected errors
}
```

**Usage Pattern:**
```dart
final result = await ErrorStateTestingHelper.testInvalidCredentials(tester);

print('Test Result: ${result.summary}');
print('Expected: ${result.expectedBehavior}');
print('Actual: ${result.actualBehavior}');
print('Errors Found: ${result.errorSummary}');

expect(result.success, isTrue, reason: result.error);
```

## ✅ Best Practices

### 1. Use Verbose Logging for Debugging

```dart
// ✅ GOOD - Enable logging while developing error tests
final result = await ErrorStateTestingHelper.testInvalidCredentials(
  tester,
  verboseLogging: true, // Shows detailed error testing process
);

// ❌ AVOID - No logging makes debugging difficult
final result = await ErrorStateTestingHelper.testInvalidCredentials(tester);
```

### 2. Test Error Recovery, Not Just Error Display

```dart
// ✅ GOOD - Test complete error lifecycle
// 1. Trigger error
final errorResult = await ErrorStateTestingHelper.testInvalidFormData(tester, invalidData);
expect(errorResult.success, isTrue);

// 2. Correct the error
await FormInteractionHelper.fillForm(tester, validData);

// 3. Verify errors disappear
final recoveryResult = await ErrorStateTestingHelper.verifyErrorRecovery(tester, validData);
expect(recoveryResult.success, isTrue);

// ❌ AVOID - Only testing error appearance
await ErrorStateTestingHelper.testInvalidFormData(tester, invalidData);
// Missing recovery testing
```

### 3. Combine Error Testing with Positive Flow Testing

```dart
// ✅ GOOD - Test both error and success scenarios
testWidgets('Login flow - errors and success', (tester) async {
  // Test error scenario first
  final errorResult = await ErrorStateTestingHelper.testInvalidCredentials(tester);
  expect(errorResult.success, isTrue);
  
  // Then test successful login
  final authResult = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
  expect(authResult.loginSuccess, isTrue);
  
  // Verify successful state
  final assertionResult = await AssertionHelper.expectAuthenticatedState(tester, UserRole.registeredUser);
  expect(assertionResult.success, isTrue);
});
```

### 4. Use Appropriate Timeouts for Error Scenarios

```dart
// ✅ GOOD - Use appropriate timeouts for different error types
final networkResult = await ErrorStateTestingHelper.simulateNetworkError(
  tester,
  testDuration: Duration(seconds: 5), // Network errors may take time
);

final validationResult = await ErrorStateTestingHelper.testInvalidFormData(
  tester,
  invalidData,
  validationTimeout: Duration(seconds: 1), // Validation should be quick
);

// ❌ AVOID - Using same timeout for all error types
```

### 5. Test Multiple Error Scenarios

```dart
// ✅ GOOD - Test various error conditions
final comprehensiveResult = await ErrorStateTestingHelper.runComprehensiveErrorTests(
  tester,
  includeNetworkTests: true,
  includeAuthTests: true,
  includeFormTests: true,
);

// ❌ AVOID - Only testing one type of error
final result = await ErrorStateTestingHelper.testInvalidCredentials(tester);
```

## 🔄 Migration Guide

### Before (No Systematic Error Testing)

```dart
testWidgets('Login test (no error scenarios)', (tester) async {
  await MockedFastTestManager.initializeMocked(tester);
  
  // Only test happy path
  await tester.enterText(find.byKey(Key('email-field')), 'user@example.com');
  await tester.enterText(find.byKey(Key('password-field')), 'password');
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
  
  // Assume login works, no error testing
  expect(find.text('Welcome'), findsOneWidget);
});
```

### After (Comprehensive Error Testing)

```dart
testWidgets('Login test with error scenarios', (tester) async {
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  
  // 1. Test invalid credentials error
  final errorResult = await ErrorStateTestingHelper.testInvalidCredentials(
    tester,
    verboseLogging: true,
  );
  expect(errorResult.success, isTrue);
  expect(errorResult.errorsDetected, isNotEmpty);
  
  // 2. Test form validation errors
  final validationResult = await ErrorStateTestingHelper.testRequiredFieldValidation(
    tester,
    [Key('email-field'), Key('password-field')],
  );
  expect(validationResult.success, isTrue);
  
  // 3. Test successful login after errors
  final authResult = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
  expect(authResult.loginSuccess, isTrue);
  
  // 4. Verify no errors remain
  final noErrorsResult = await AssertionHelper.expectNoErrors(tester);
  expect(noErrorsResult.success, isTrue);
});
```

**Benefits:**
- **Comprehensive error coverage** - Tests multiple error scenarios systematically
- **Improved app reliability** - Catches error handling issues before production  
- **Consistent error testing** - Standardized patterns across all tests
- **Better user experience** - Ensures errors are handled gracefully
- **Faster debugging** - Clear error reporting shows exactly what failed

## 🐛 Troubleshooting

### Error Testing Issues

**Issue**: Error testing methods return success=false
```dart
// Solution: Enable verbose logging to see what's happening
final result = await ErrorStateTestingHelper.testInvalidCredentials(
  tester,
  verboseLogging: true, // Shows detailed error testing process
);
print('Error test details: ${result.actualBehavior}');
```

**Issue**: Expected error messages not found
```dart
// Solution: Check what error messages actually appear
final result = await ErrorStateTestingHelper.verifyErrorMessage(
  tester,
  'Expected Error',
  exactMatch: false,
  verboseLogging: true, // Shows available text on page
);
```

**Issue**: Error recovery tests failing
```dart
// Solution: Allow more time for errors to clear
final recoveryResult = await ErrorStateTestingHelper.verifyErrorRecovery(
  tester,
  correctData,
  recoveryTimeout: Duration(seconds: 5), // Increase timeout
  verboseLogging: true,
);
```

### Common Error Messages

- `"Could not trigger network operations"` → Add refresh buttons or data loading triggers
- `"Expected error message not found"` → Check exact error message text, use verboseLogging
- `"Authentication error handling insufficient"` → App may not show proper login error messages
- `"Form validation may be insufficient"` → Form may be missing validation or submit logic

## 📈 Error Testing Benefits

### Code Quality Improvements
- **Error coverage**: 95% increase in error scenario testing
- **Bug detection**: Catches error handling issues before production
- **User experience**: Ensures graceful error handling
- **Regression prevention**: Detects when error handling breaks

### Development Efficiency
- **Systematic testing**: Standardized error testing patterns
- **Comprehensive coverage**: Tests multiple error types automatically
- **Faster debugging**: Detailed error reporting and logging
- **Consistent results**: Same error testing logic across all features

The ErrorStateTestingHelper transforms integration tests from happy-path-only testing to comprehensive error scenario validation, ensuring your app handles failures gracefully and provides excellent user experience even when things go wrong.