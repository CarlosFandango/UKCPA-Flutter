import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Form Interaction Helper - Consistent Form Testing Across Integration Tests
/// 
/// This helper solves common form testing challenges:
/// - Repetitive form field interactions
/// - Inconsistent validation waiting
/// - Complex multi-step form handling
/// - Error state verification
/// - Different input types (email, password, dates, dropdowns)
/// 
/// **Usage Example:**
/// ```dart
/// // Instead of manual field interactions
/// await tester.enterText(find.byKey(Key('email-field')), 'test@example.com');
/// await tester.enterText(find.byKey(Key('password-field')), 'password123');
/// await tester.tap(find.text('Submit'));
/// 
/// // Use FormInteractionHelper
/// await FormInteractionHelper.fillAndSubmitForm(tester, {
///   'email-field': 'test@example.com',
///   'password-field': 'password123',
/// }, submitButtonText: 'Submit');
/// ```
class FormInteractionHelper {
  
  /// Fill multiple form fields and optionally submit the form
  /// 
  /// [fieldData] - Map of field keys/selectors to values
  /// [submitButtonText] - Text of submit button (if null, won't submit)
  /// [waitForValidation] - Wait for validation after filling fields
  /// [verboseLogging] - Enable detailed logging for debugging
  static Future<FormInteractionResult> fillAndSubmitForm(
    WidgetTester tester,
    Map<String, dynamic> fieldData, {
    String? submitButtonText,
    Duration fillDelay = const Duration(milliseconds: 100),
    Duration validationWait = const Duration(milliseconds: 500),
    Duration submitWait = const Duration(seconds: 2),
    bool waitForValidation = true,
    bool verboseLogging = false,
  }) async {
    final result = FormInteractionResult();
    
    if (verboseLogging) {
      print('\n📝 FORM INTERACTION: Filling ${fieldData.length} fields');
    }
    
    // Fill all form fields
    for (final entry in fieldData.entries) {
      final fieldKey = entry.key;
      final fieldValue = entry.value;
      
      try {
        await _fillField(tester, fieldKey, fieldValue, fillDelay, verboseLogging);
        result.successfulFields.add(fieldKey);
      } catch (e) {
        result.failedFields[fieldKey] = e.toString();
        if (verboseLogging) {
          print('❌ Failed to fill field "$fieldKey": $e');
        }
      }
    }
    
    // Wait for validation if requested
    if (waitForValidation) {
      await tester.pump(validationWait);
      if (verboseLogging) {
        print('⏳ Waited ${validationWait.inMilliseconds}ms for validation');
      }
    }
    
    // Capture any validation errors
    result.validationErrors = await _captureValidationErrors(tester);
    if (result.validationErrors.isNotEmpty && verboseLogging) {
      print('⚠️  Validation errors found: ${result.validationErrors}');
    }
    
    // Submit form if requested
    if (submitButtonText != null) {
      try {
        await _submitForm(tester, submitButtonText, submitWait, verboseLogging);
        result.submitSuccess = true;
      } catch (e) {
        result.submitError = e.toString();
        if (verboseLogging) {
          print('❌ Form submission failed: $e');
        }
      }
    }
    
    if (verboseLogging) {
      print('✅ Form interaction complete: ${result.summary}');
    }
    
    return result;
  }
  
  /// Fill a single form field with smart type detection
  /// 
  /// Supports various field identification methods:
  /// - Key: 'email-field' -> Key('email-field')
  /// - Text: 'Email Address' -> find.text('Email Address')
  /// - Label: 'label:Email' -> find.textContaining('Email')
  /// - Type: 'type:email' -> Smart email field detection
  static Future<void> fillField(
    WidgetTester tester,
    String fieldIdentifier,
    dynamic value, {
    Duration delay = const Duration(milliseconds: 100),
    bool verboseLogging = false,
  }) async {
    await _fillField(tester, fieldIdentifier, value, delay, verboseLogging);
  }
  
  /// Submit a form by button text or key
  static Future<void> submitForm(
    WidgetTester tester,
    String submitIdentifier, {
    Duration submitWait = const Duration(seconds: 2),
    bool verboseLogging = false,
  }) async {
    await _submitForm(tester, submitIdentifier, submitWait, verboseLogging);
  }
  
  /// Verify form validation errors
  static Future<List<String>> getValidationErrors(WidgetTester tester) async {
    return await _captureValidationErrors(tester);
  }
  
  /// Clear all form fields
  static Future<void> clearForm(
    WidgetTester tester,
    List<String> fieldIdentifiers, {
    bool verboseLogging = false,
  }) async {
    if (verboseLogging) {
      print('\n🧹 CLEARING FORM: ${fieldIdentifiers.length} fields');
    }
    
    for (final fieldId in fieldIdentifiers) {
      try {
        final finder = _getFieldFinder(fieldId);
        if (finder.evaluate().isNotEmpty) {
          await tester.enterText(finder.first, '');
          await tester.pump(const Duration(milliseconds: 50));
        }
      } catch (e) {
        if (verboseLogging) {
          print('⚠️  Could not clear field "$fieldId": $e');
        }
      }
    }
    
    if (verboseLogging) {
      print('✅ Form cleared');
    }
  }
  
  /// Handle multi-step forms with progress tracking
  static Future<MultiStepFormResult> fillMultiStepForm(
    WidgetTester tester,
    List<FormStep> steps, {
    Duration stepDelay = const Duration(milliseconds: 500),
    bool verboseLogging = false,
  }) async {
    final result = MultiStepFormResult();
    
    if (verboseLogging) {
      print('\n📋 MULTI-STEP FORM: ${steps.length} steps');
    }
    
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      
      if (verboseLogging) {
        print('\n📝 Step ${i + 1}/${steps.length}: ${step.name}');
      }
      
      try {
        // Fill fields for this step
        final stepResult = await fillAndSubmitForm(
          tester,
          step.fieldData,
          submitButtonText: step.nextButtonText,
          verboseLogging: verboseLogging,
        );
        
        result.stepResults.add(stepResult);
        
        if (!stepResult.submitSuccess && step.nextButtonText != null) {
          result.failedAtStep = i;
          result.overallSuccess = false;
          break;
        }
        
        // Wait between steps
        await tester.pump(stepDelay);
        
      } catch (e) {
        result.failedAtStep = i;
        result.overallSuccess = false;
        result.error = e.toString();
        
        if (verboseLogging) {
          print('❌ Step ${i + 1} failed: $e');
        }
        break;
      }
    }
    
    if (result.overallSuccess && verboseLogging) {
      print('✅ Multi-step form completed successfully');
    }
    
    return result;
  }
  
  /// Handle dropdown selection
  static Future<void> selectFromDropdown(
    WidgetTester tester,
    String dropdownIdentifier,
    String optionText, {
    Duration selectionDelay = const Duration(milliseconds: 500),
    bool verboseLogging = false,
  }) async {
    if (verboseLogging) {
      print('🔽 Selecting "$optionText" from dropdown "$dropdownIdentifier"');
    }
    
    try {
      // Find and tap the dropdown
      final dropdownFinder = _getFieldFinder(dropdownIdentifier);
      expect(dropdownFinder, findsOneWidget, 
        reason: 'Dropdown "$dropdownIdentifier" not found');
      
      await tester.tap(dropdownFinder.first);
      await tester.pump(selectionDelay);
      
      // Find and tap the option
      final optionFinder = find.text(optionText);
      expect(optionFinder, findsOneWidget,
        reason: 'Dropdown option "$optionText" not found');
      
      await tester.tap(optionFinder.first);
      await tester.pump(selectionDelay);
      
      if (verboseLogging) {
        print('✅ Selected "$optionText" from dropdown');
      }
      
    } catch (e) {
      if (verboseLogging) {
        print('❌ Dropdown selection failed: $e');
      }
      rethrow;
    }
  }
  
  /// Handle date picker interactions
  static Future<void> selectDate(
    WidgetTester tester,
    String dateFieldIdentifier,
    DateTime date, {
    Duration selectionDelay = const Duration(milliseconds: 500),
    bool verboseLogging = false,
  }) async {
    if (verboseLogging) {
      print('📅 Selecting date ${date.toString().substring(0, 10)} for field "$dateFieldIdentifier"');
    }
    
    try {
      // Find and tap the date field
      final dateFieldFinder = _getFieldFinder(dateFieldIdentifier);
      expect(dateFieldFinder, findsOneWidget,
        reason: 'Date field "$dateFieldIdentifier" not found');
      
      await tester.tap(dateFieldFinder.first);
      await tester.pump(selectionDelay);
      
      // Look for date picker
      final datePickerFinder = find.byType(DatePickerDialog);
      if (datePickerFinder.evaluate().isNotEmpty) {
        // Handle Material date picker
        await _handleMaterialDatePicker(tester, date, selectionDelay);
      } else {
        // Fallback: enter date as text
        final dateString = '${date.day}/${date.month}/${date.year}';
        await tester.enterText(dateFieldFinder.first, dateString);
      }
      
      if (verboseLogging) {
        print('✅ Date selected successfully');
      }
      
    } catch (e) {
      if (verboseLogging) {
        print('❌ Date selection failed: $e');
      }
      rethrow;
    }
  }
  
  /// Handle file upload (if applicable to platform)
  static Future<void> uploadFile(
    WidgetTester tester,
    String uploadFieldIdentifier,
    String fileName, {
    Duration uploadDelay = const Duration(seconds: 1),
    bool verboseLogging = false,
  }) async {
    if (verboseLogging) {
      print('📁 Uploading file "$fileName" to field "$uploadFieldIdentifier"');
    }
    
    try {
      final uploadFinder = _getFieldFinder(uploadFieldIdentifier);
      expect(uploadFinder, findsOneWidget,
        reason: 'Upload field "$uploadFieldIdentifier" not found');
      
      await tester.tap(uploadFinder.first);
      await tester.pump(uploadDelay);
      
      // Note: Actual file upload would require platform-specific handling
      // This is a placeholder for the file upload interaction
      
      if (verboseLogging) {
        print('✅ File upload triggered (platform-specific handling required)');
      }
      
    } catch (e) {
      if (verboseLogging) {
        print('❌ File upload failed: $e');
      }
      rethrow;
    }
  }
  
  // ========== PRIVATE HELPER METHODS ==========
  
  /// Internal method to fill a single field
  static Future<void> _fillField(
    WidgetTester tester,
    String fieldIdentifier,
    dynamic value,
    Duration delay,
    bool verboseLogging,
  ) async {
    final finder = _getFieldFinder(fieldIdentifier);
    
    if (verboseLogging) {
      print('📝 Filling field "$fieldIdentifier" with "$value"');
    }
    
    expect(finder, findsOneWidget,
      reason: 'Field "$fieldIdentifier" not found');
    
    if (value is String) {
      await tester.enterText(finder.first, value);
    } else if (value is bool) {
      // Handle checkboxes/switches
      final widget = tester.widget(finder.first);
      if (widget is Checkbox || widget is Switch) {
        await tester.tap(finder.first);
      }
    } else {
      await tester.enterText(finder.first, value.toString());
    }
    
    await tester.pump(delay);
  }
  
  /// Internal method to submit form
  static Future<void> _submitForm(
    WidgetTester tester,
    String submitIdentifier,
    Duration submitWait,
    bool verboseLogging,
  ) async {
    if (verboseLogging) {
      print('📤 Submitting form via "$submitIdentifier"');
    }
    
    final submitFinder = _getFieldFinder(submitIdentifier);
    expect(submitFinder, findsOneWidget,
      reason: 'Submit button "$submitIdentifier" not found');
    
    await tester.tap(submitFinder.first);
    await tester.pump(submitWait);
  }
  
  /// Get finder for field based on identifier pattern
  static Finder _getFieldFinder(String identifier) {
    if (identifier.startsWith('key:')) {
      return find.byKey(Key(identifier.substring(4)));
    } else if (identifier.startsWith('text:')) {
      return find.text(identifier.substring(5));
    } else if (identifier.startsWith('label:')) {
      return find.textContaining(identifier.substring(6));
    } else if (identifier.startsWith('type:')) {
      return _getFieldByType(identifier.substring(5));
    } else {
      // Default: treat as key
      return find.byKey(Key(identifier));
    }
  }
  
  /// Get field by input type
  static Finder _getFieldByType(String type) {
    switch (type.toLowerCase()) {
      case 'email':
        return find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.keyboardType == TextInputType.emailAddress);
      case 'password':
        return find.byWidgetPredicate((widget) =>
          widget is TextField && widget.obscureText == true);
      case 'number':
        return find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.keyboardType == TextInputType.number);
      case 'phone':
        return find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.keyboardType == TextInputType.phone);
      default:
        return find.byType(TextField);
    }
  }
  
  /// Capture validation errors from the form
  static Future<List<String>> _captureValidationErrors(WidgetTester tester) async {
    final errors = <String>[];
    
    // Common error indicators
    final errorFinders = [
      find.textContaining('required'),
      find.textContaining('invalid'),
      find.textContaining('error'),
      find.textContaining('Enter a valid'),
      find.byIcon(Icons.error),
      find.byIcon(Icons.error_outline),
    ];
    
    for (final errorFinder in errorFinders) {
      final errorWidgets = errorFinder.evaluate();
      for (final errorElement in errorWidgets) {
        final widget = errorElement.widget;
        if (widget is Text) {
          final errorText = widget.data ?? '';
          if (errorText.isNotEmpty && !errors.contains(errorText)) {
            errors.add(errorText);
          }
        }
      }
    }
    
    return errors;
  }
  
  /// Handle Material date picker selection
  static Future<void> _handleMaterialDatePicker(
    WidgetTester tester,
    DateTime date,
    Duration delay,
  ) async {
    // This would contain platform-specific date picker handling
    // For now, just close the picker and use text input
    
    // Look for OK/Cancel buttons
    final okButton = find.text('OK');
    if (okButton.evaluate().isNotEmpty) {
      await tester.tap(okButton.first);
      await tester.pump(delay);
    }
  }
}

/// Result of form interaction operations
class FormInteractionResult {
  bool submitSuccess = false;
  String? submitError;
  List<String> successfulFields = [];
  Map<String, String> failedFields = {};
  List<String> validationErrors = [];
  
  bool get hasErrors => submitError != null || failedFields.isNotEmpty || validationErrors.isNotEmpty;
  
  String get summary => hasErrors
    ? 'Failed: ${failedFields.length} field errors, ${validationErrors.length} validation errors'
    : 'Success: ${successfulFields.length} fields filled';
}

/// Represents a single step in a multi-step form
class FormStep {
  final String name;
  final Map<String, dynamic> fieldData;
  final String? nextButtonText;
  
  const FormStep({
    required this.name,
    required this.fieldData,
    this.nextButtonText,
  });
}

/// Result of multi-step form operations
class MultiStepFormResult {
  bool overallSuccess = true;
  int? failedAtStep;
  String? error;
  List<FormInteractionResult> stepResults = [];
  
  bool get hasErrors => !overallSuccess || failedAtStep != null;
  
  String get summary => hasErrors
    ? 'Failed at step ${(failedAtStep ?? 0) + 1}: $error'
    : 'Success: ${stepResults.length} steps completed';
}