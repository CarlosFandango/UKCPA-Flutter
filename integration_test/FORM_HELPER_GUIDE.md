# Form Interaction Helper Guide

## 🎯 **Problem Solved**

**Issue**: Form testing in integration tests involves repetitive, error-prone code with inconsistent validation handling, complex multi-step forms, and different input types requiring specialized interactions.

**Solution**: The `FormInteractionHelper` provides a unified API for all form interactions, smart field detection, automatic validation waiting, and comprehensive error handling.

## 🚀 **Quick Start**

### Basic Form Interaction

```dart
import '../helpers/form_interaction_helper.dart';

testWidgets('Login form test', (tester) async {
  // Instead of manual field interactions
  await tester.enterText(find.byKey(Key('email-field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password-field')), 'password123');
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  
  // Use FormInteractionHelper
  final result = await FormInteractionHelper.fillAndSubmitForm(tester, {
    'email-field': 'test@example.com',
    'password-field': 'password123',
  }, submitButtonText: 'Sign In');
  
  expect(result.submitSuccess, isTrue);
});
```

### Advanced Form with Validation

```dart
testWidgets('Registration form with validation', (tester) async {
  final result = await FormInteractionHelper.fillAndSubmitForm(
    tester,
    {
      'first-name-field': 'John',
      'last-name-field': 'Doe',
      'email-field': 'john.doe@example.com',
      'password-field': 'SecurePass123!',
      'confirm-password-field': 'SecurePass123!',
      'terms-checkbox': true,
    },
    submitButtonText: 'Create Account',
    waitForValidation: true,
    verboseLogging: true,
  );
  
  if (result.hasErrors) {
    print('Form errors: ${result.validationErrors}');
  }
  
  expect(result.submitSuccess, isTrue);
  expect(result.validationErrors, isEmpty);
});
```

## 📋 **Field Identification Methods**

The helper supports multiple ways to identify form fields:

### 1. Key-based Identification (Default)
```dart
// Direct key specification
'email-field' // -> Key('email-field')

// Explicit key prefix
'key:email-field' // -> Key('email-field')
```

### 2. Text-based Identification
```dart
'text:Sign In' // -> find.text('Sign In')
'text:Email Address' // -> find.text('Email Address')
```

### 3. Label-based Identification
```dart
'label:Email' // -> find.textContaining('Email')
'label:Password' // -> find.textContaining('Password')
```

### 4. Type-based Smart Detection
```dart
'type:email' // -> TextField with emailAddress keyboard
'type:password' // -> TextField with obscureText = true
'type:number' // -> TextField with number keyboard
'type:phone' // -> TextField with phone keyboard
```

## 🔧 **Core Methods**

### fillAndSubmitForm()

**Primary method** for form interactions with comprehensive options:

```dart
Future<FormInteractionResult> fillAndSubmitForm(
  WidgetTester tester,
  Map<String, dynamic> fieldData, {
  String? submitButtonText,           // Submit button text (null = don't submit)
  Duration fillDelay = const Duration(milliseconds: 100),
  Duration validationWait = const Duration(milliseconds: 500),
  Duration submitWait = const Duration(seconds: 2),
  bool waitForValidation = true,      // Wait for validation after filling
  bool verboseLogging = false,        // Enable detailed logging
});
```

**Field Data Types:**
- `String`: Text input
- `bool`: Checkbox/switch toggle  
- `DateTime`: Date field (with picker handling)
- `int/double`: Numeric input

**Example:**
```dart
final result = await FormInteractionHelper.fillAndSubmitForm(tester, {
  'email-field': 'user@example.com',        // String -> text input
  'age-field': 25,                          // int -> numeric input
  'newsletter-checkbox': true,              // bool -> checkbox toggle
  'birth-date': DateTime(1995, 6, 15),     // DateTime -> date picker
});
```

### fillField()

**Single field** interaction with smart type detection:

```dart
// Fill email field
await FormInteractionHelper.fillField(
  tester, 
  'type:email', 
  'user@example.com',
  verboseLogging: true,
);

// Fill password field
await FormInteractionHelper.fillField(
  tester,
  'password-field',
  'secretPassword',
);
```

### submitForm()

**Submit form** without filling fields:

```dart
await FormInteractionHelper.submitForm(
  tester,
  'Submit',                    // Button text
  submitWait: Duration(seconds: 3),
  verboseLogging: true,
);
```

### getValidationErrors()

**Capture validation errors** for verification:

```dart
// Fill form with invalid data
await FormInteractionHelper.fillAndSubmitForm(tester, {
  'email-field': 'invalid-email',
  'password-field': '',
});

// Check validation errors
final errors = await FormInteractionHelper.getValidationErrors(tester);
expect(errors, contains('Enter a valid email'));
expect(errors, contains('Password is required'));
```

### clearForm()

**Clear all form fields** for clean test state:

```dart
await FormInteractionHelper.clearForm(tester, [
  'email-field',
  'password-field', 
  'first-name-field',
], verboseLogging: true);
```

## 🎛️ **Specialized Interactions**

### Dropdown Selection

```dart
await FormInteractionHelper.selectFromDropdown(
  tester,
  'country-dropdown',          // Dropdown identifier
  'United Kingdom',            // Option to select
  verboseLogging: true,
);
```

### Date Selection

```dart
await FormInteractionHelper.selectDate(
  tester,
  'birth-date-field',         // Date field identifier
  DateTime(1995, 6, 15),      // Date to select
  verboseLogging: true,
);
```

### File Upload

```dart
await FormInteractionHelper.uploadFile(
  tester,
  'profile-image-upload',     // Upload field identifier
  'profile.jpg',              // File name
  verboseLogging: true,
);
```

## 📋 **Multi-Step Forms**

For complex forms with multiple steps:

```dart
final steps = [
  FormStep(
    name: 'Personal Information',
    fieldData: {
      'first-name': 'John',
      'last-name': 'Doe',
      'email': 'john@example.com',
    },
    nextButtonText: 'Next',
  ),
  FormStep(
    name: 'Address Information', 
    fieldData: {
      'address-line-1': '123 Main St',
      'city': 'London',
      'postcode': 'SW1A 1AA',
    },
    nextButtonText: 'Next',
  ),
  FormStep(
    name: 'Payment Information',
    fieldData: {
      'card-number': '4242424242424242',
      'expiry': '12/25',
      'cvv': '123',
    },
    nextButtonText: 'Complete Order',
  ),
];

final result = await FormInteractionHelper.fillMultiStepForm(
  tester, 
  steps,
  verboseLogging: true,
);

expect(result.overallSuccess, isTrue);
expect(result.stepResults.length, equals(3));
```

## 📊 **Result Objects**

### FormInteractionResult

```dart
class FormInteractionResult {
  bool submitSuccess;              // Form submitted successfully
  String? submitError;             // Submit error message
  List<String> successfulFields;   // Fields filled successfully
  Map<String, String> failedFields; // Fields that failed with errors
  List<String> validationErrors;   // Validation errors found
  
  bool get hasErrors;              // Any errors occurred
  String get summary;              // Human-readable summary
}
```

**Usage:**
```dart
final result = await FormInteractionHelper.fillAndSubmitForm(tester, fieldData);

if (result.hasErrors) {
  print('Failed fields: ${result.failedFields}');
  print('Validation errors: ${result.validationErrors}');
} else {
  print('Success: ${result.summary}');
}
```

### MultiStepFormResult

```dart
class MultiStepFormResult {
  bool overallSuccess;                        // All steps completed
  int? failedAtStep;                         // Which step failed (0-indexed)
  String? error;                             // Error message
  List<FormInteractionResult> stepResults;   // Results for each step
  
  bool get hasErrors;                        // Any errors occurred
  String get summary;                        // Human-readable summary
}
```

## 🎯 **Common Patterns**

### Authentication Forms

```dart
// Login form
final loginResult = await FormInteractionHelper.fillAndSubmitForm(tester, {
  'email-field': TestCredentials.validEmail,
  'password-field': TestCredentials.validPassword,
}, submitButtonText: 'Sign In');

// Registration form
final registerResult = await FormInteractionHelper.fillAndSubmitForm(tester, {
  'first-name-field': 'Test',
  'last-name-field': 'User', 
  'email-field': TestCredentials.validEmail,
  'password-field': TestCredentials.validPassword,
  'confirm-password-field': TestCredentials.validPassword,
  'terms-checkbox': true,
}, submitButtonText: 'Create Account');
```

### Course Booking Forms

```dart
final bookingResult = await FormInteractionHelper.fillAndSubmitForm(tester, {
  'participant-name': 'John Doe',
  'participant-age': 25,
  'emergency-contact': 'Jane Doe',
  'emergency-phone': '+44 7700 900123',
  'medical-conditions': 'None',
  'terms-checkbox': true,
}, submitButtonText: 'Book Course');
```

### Payment Forms

```dart
final paymentResult = await FormInteractionHelper.fillAndSubmitForm(tester, {
  'card-number': TestCredentials.validCardNumber,
  'expiry-date': TestCredentials.validCardExpiry,
  'cvv': TestCredentials.validCardCVV,
  'cardholder-name': 'Test User',
  'billing-address': TestCredentials.testBillingAddress['addressLine1'],
  'billing-city': TestCredentials.testBillingAddress['city'],
  'billing-postcode': TestCredentials.testBillingAddress['postcode'],
}, submitButtonText: 'Complete Payment');
```

## 🔍 **Validation Testing**

### Error State Testing

```dart
testWidgets('Form validation errors', (tester) async {
  // Fill form with invalid data
  final result = await FormInteractionHelper.fillAndSubmitForm(tester, {
    'email-field': 'invalid-email',    // Invalid email format
    'password-field': '123',           // Too short password
    'age-field': 'not-a-number',       // Invalid age
  }, submitButtonText: 'Submit');
  
  // Verify submission failed due to validation
  expect(result.submitSuccess, isFalse);
  expect(result.validationErrors, isNotEmpty);
  
  // Check specific validation messages
  expect(result.validationErrors, contains('Enter a valid email'));
  expect(result.validationErrors, contains('Password must be at least 8 characters'));
});
```

### Required Field Testing

```dart
testWidgets('Required field validation', (tester) async {
  // Submit form with missing required fields
  final result = await FormInteractionHelper.fillAndSubmitForm(tester, {
    'optional-field': 'Some value',
    // Missing required fields intentionally
  }, submitButtonText: 'Submit');
  
  expect(result.submitSuccess, isFalse);
  expect(result.validationErrors.where((error) => 
    error.toLowerCase().contains('required')), isNotEmpty);
});
```

## 🐛 **Troubleshooting**

### Field Not Found Issues

```dart
// Enable verbose logging to debug field identification
final result = await FormInteractionHelper.fillAndSubmitForm(
  tester, 
  {'problematic-field': 'value'},
  verboseLogging: true,  // Shows detailed field search process
);
```

**Common Solutions:**
- Check field key names match exactly
- Use `find.byKey(Key('field-name'))` in Flutter Inspector
- Try different identification methods (text, label, type)
- Ensure field is visible and enabled

### Timing Issues

```dart
// Increase delays for slow forms
final result = await FormInteractionHelper.fillAndSubmitForm(
  tester,
  fieldData,
  fillDelay: Duration(milliseconds: 200),      // Slower typing
  validationWait: Duration(seconds: 1),        // More validation time
  submitWait: Duration(seconds: 5),            // Longer submit wait
);
```

### Validation Not Working

```dart
// Check validation errors manually
final errors = await FormInteractionHelper.getValidationErrors(tester);
print('Found validation errors: $errors');

// Ensure validation wait time is sufficient
final result = await FormInteractionHelper.fillAndSubmitForm(
  tester,
  invalidData,
  waitForValidation: true,
  validationWait: Duration(seconds: 2),  // Longer validation wait
);
```

## 🎯 **Best Practices**

### 1. Use Appropriate Identification Methods

```dart
// ✅ GOOD - Use semantic identifiers
'email-field'           // Clear field purpose
'type:email'           // Smart type detection
'label:Email Address'  // User-visible label

// ❌ AVOID - Generic identifiers  
'textfield-1'          // Unclear purpose
'input'                // Too generic
```

### 2. Handle Results Properly

```dart
// ✅ GOOD - Check results and handle errors
final result = await FormInteractionHelper.fillAndSubmitForm(tester, fieldData);
if (result.hasErrors) {
  print('Form errors: ${result.summary}');
  // Handle or assert on specific errors
}
expect(result.submitSuccess, isTrue);

// ❌ AVOID - Ignoring results
await FormInteractionHelper.fillAndSubmitForm(tester, fieldData);
// No error checking
```

### 3. Use Verbose Logging During Development

```dart
// During test development
final result = await FormInteractionHelper.fillAndSubmitForm(
  tester, 
  fieldData,
  verboseLogging: true,  // Remove when stable
);
```

### 4. Test Both Success and Error Scenarios

```dart
group('Form testing', () {
  testWidgets('Successful form submission', (tester) async {
    final result = await FormInteractionHelper.fillAndSubmitForm(tester, validData);
    expect(result.submitSuccess, isTrue);
  });
  
  testWidgets('Form validation errors', (tester) async {
    final result = await FormInteractionHelper.fillAndSubmitForm(tester, invalidData);
    expect(result.hasErrors, isTrue);
  });
});
```

### 5. Clear Forms Between Tests

```dart
testWidgets('Clean form state', (tester) async {
  // Clear form before filling
  await FormInteractionHelper.clearForm(tester, [
    'email-field',
    'password-field',
  ]);
  
  // Then fill with test data
  final result = await FormInteractionHelper.fillAndSubmitForm(tester, testData);
});
```

## ✅ **Migration from Manual Form Interactions**

### Before (Manual Approach)
```dart
testWidgets('Login test - manual', (tester) async {
  await tester.enterText(find.byKey(Key('email-field')), 'test@example.com');
  await tester.pump(Duration(milliseconds: 100));
  
  await tester.enterText(find.byKey(Key('password-field')), 'password123');
  await tester.pump(Duration(milliseconds: 100));
  
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(Duration(seconds: 2));
  
  // Manual validation checking
  final errorFinder = find.textContaining('error');
  expect(errorFinder, findsNothing);
});
```

### After (Using FormInteractionHelper)
```dart
testWidgets('Login test - using helper', (tester) async {
  final result = await FormInteractionHelper.fillAndSubmitForm(tester, {
    'email-field': 'test@example.com',
    'password-field': 'password123',
  }, submitButtonText: 'Sign In');
  
  expect(result.submitSuccess, isTrue);
  expect(result.validationErrors, isEmpty);
});
```

The FormInteractionHelper eliminates repetitive code, provides consistent error handling, and makes form tests more reliable and maintainable.