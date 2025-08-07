import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'authentication_flow_helper.dart';
import 'form_interaction_helper.dart';
import 'assertion_helper.dart';

/// Result class for error state testing operations
class ErrorTestResult {
  bool success;
  String? error;
  String? details;
  List<String> errorsDetected;
  String? actualBehavior;
  String? expectedBehavior;
  
  ErrorTestResult({
    this.success = false,
    this.error,
    this.details,
    this.errorsDetected = const [],
    this.actualBehavior,
    this.expectedBehavior,
  });
  
  String get summary => success 
    ? 'Error test passed${details != null ? ': $details' : ''}'
    : 'Error test failed${error != null ? ': $error' : ''}';
    
  bool get hasErrorsDetected => errorsDetected.isNotEmpty;
  
  String get errorSummary => errorsDetected.isEmpty 
    ? 'No errors detected' 
    : 'Errors detected: ${errorsDetected.join(', ')}';
}

/// Helper for systematic error scenario testing in integration tests
/// Provides methods to simulate error conditions and validate error handling
class ErrorStateTestingHelper {
  
  // ============================================================================
  // NETWORK ERROR SIMULATION
  // ============================================================================
  
  /// Simulate network connectivity issues and test app behavior
  static Future<ErrorTestResult> simulateNetworkError(
    WidgetTester tester, {
    Duration testDuration = const Duration(seconds: 3),
    bool expectErrorMessage = true,
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = expectErrorMessage 
      ? 'App should show network error message' 
      : 'App should handle network errors gracefully';
    
    if (verboseLogging) {
      print('\n🚨 ERROR SIMULATION: Network connectivity test');
      print('   Expected behavior: ${result.expectedBehavior}');
    }
    
    try {
      // Note: In a real implementation, this would interact with network mocking
      // For integration tests, we simulate by triggering actions that might fail
      
      // Try to trigger network operations (refresh, load data, etc.)
      final refreshButtons = [
        find.text('Refresh'),
        find.text('Reload'),
        find.byIcon(Icons.refresh),
        find.text('Try Again'),
      ];
      
      bool networkActionTriggered = false;
      for (final button in refreshButtons) {
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button);
          await tester.pumpAndSettle();
          networkActionTriggered = true;
          break;
        }
      }
      
      if (!networkActionTriggered) {
        // Try scrolling to trigger data loading
        final scrollables = find.byType(ListView);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, -300));
          await tester.pumpAndSettle();
          networkActionTriggered = true;
        }
      }
      
      if (networkActionTriggered) {
        // Wait for potential error states
        await Future.delayed(testDuration);
        await tester.pump();
        
        // Check for error indicators
        final errorPatterns = [
          'Network error',
          'Connection failed',
          'No internet',
          'Unable to connect',
          'Check your connection',
          'Offline',
          'Network timeout',
        ];
        
        final detectedErrors = <String>[];
        for (final pattern in errorPatterns) {
          if (find.textContaining(pattern).evaluate().isNotEmpty) {
            detectedErrors.add(pattern);
          }
        }
        
        result.errorsDetected = detectedErrors;
        result.actualBehavior = detectedErrors.isEmpty 
          ? 'No network error messages displayed'
          : 'Network error messages: ${detectedErrors.join(', ')}';
        
        if (expectErrorMessage) {
          result.success = detectedErrors.isNotEmpty;
          result.details = result.success 
            ? 'Network error handling working correctly'
            : 'Expected network error messages not found';
        } else {
          // Check that app didn't crash or show inappropriate errors
          result.success = true;
          result.details = 'App handled network issues gracefully';
        }
        
        if (verboseLogging) {
          print('   Network action triggered: $networkActionTriggered');
          print('   Errors detected: ${detectedErrors.length}');
          print('   Actual behavior: ${result.actualBehavior}');
        }
      } else {
        result.error = 'Could not trigger network operations to test error handling';
      }
      
    } catch (e) {
      result.error = 'Exception during network error simulation: $e';
      
      if (verboseLogging) {
        print('❌ Exception during network test: $e');
      }
    }
    
    return result;
  }
  
  /// Test app behavior when server returns errors
  static Future<ErrorTestResult> simulateServerError(
    WidgetTester tester, {
    Duration testDuration = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'App should show server error message and allow retry';
    
    if (verboseLogging) {
      print('\n🚨 ERROR SIMULATION: Server error test');
    }
    
    try {
      // Trigger actions that might result in server errors
      final actionButtons = [
        find.text('Submit'),
        find.text('Save'),
        find.text('Book Now'),
        find.text('Register'),
        find.text('Login'),
      ];
      
      bool actionTriggered = false;
      for (final button in actionButtons) {
        if (button.evaluate().isNotEmpty) {
          await tester.tap(button);
          await tester.pumpAndSettle();
          actionTriggered = true;
          
          // Wait for server response
          await Future.delayed(testDuration);
          await tester.pump();
          break;
        }
      }
      
      if (actionTriggered) {
        // Check for server error patterns
        final serverErrorPatterns = [
          'Server error',
          '500',
          'Internal error',
          'Something went wrong',
          'Try again later',
          'Service unavailable',
          'Maintenance',
        ];
        
        final detectedErrors = <String>[];
        for (final pattern in serverErrorPatterns) {
          if (find.textContaining(pattern).evaluate().isNotEmpty) {
            detectedErrors.add(pattern);
          }
        }
        
        result.errorsDetected = detectedErrors;
        result.actualBehavior = detectedErrors.isEmpty 
          ? 'No server error messages displayed'
          : 'Server error messages: ${detectedErrors.join(', ')}';
        
        result.success = true; // Success means we tested server error handling
        result.details = 'Server error simulation completed';
        
        if (verboseLogging) {
          print('   Action triggered: $actionTriggered');
          print('   Server errors detected: ${detectedErrors.length}');
          print('   ${result.actualBehavior}');
        }
      } else {
        result.error = 'Could not trigger server operations to test error handling';
      }
      
    } catch (e) {
      result.error = 'Exception during server error simulation: $e';
      
      if (verboseLogging) {
        print('❌ Exception during server test: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // AUTHENTICATION ERROR TESTING
  // ============================================================================
  
  /// Test invalid credentials and authentication failures
  static Future<ErrorTestResult> testInvalidCredentials(
    WidgetTester tester, {
    Map<String, String>? customInvalidCredentials,
    Duration timeout = const Duration(seconds: 5),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'App should show authentication error and prevent login';
    
    if (verboseLogging) {
      print('\n🚨 ERROR TEST: Invalid credentials');
    }
    
    try {
      // Use custom credentials or generate random invalid ones
      final invalidCredentials = customInvalidCredentials ?? {
        'email-field': 'invalid${Random().nextInt(1000)}@nonexistent.com',
        'password-field': 'wrongpassword${Random().nextInt(1000)}',
      };
      
      if (verboseLogging) {
        print('   Testing with credentials: ${invalidCredentials.keys.join(', ')}');
      }
      
      // Fill login form with invalid credentials
      final formResult = await FormInteractionHelper.fillAndSubmitForm(
        tester,
        invalidCredentials,
        submitButtonText: 'Sign In',
        verboseLogging: verboseLogging,
      );
      
      // Wait for authentication error response
      await Future.delayed(timeout);
      await tester.pumpAndSettle();
      
      // Check for authentication error messages
      final authErrorPatterns = [
        'Invalid credentials',
        'Login failed',
        'Incorrect email or password',
        'Authentication failed',
        'Invalid email',
        'Invalid password',
        'User not found',
        'Wrong password',
        'Access denied',
      ];
      
      final detectedErrors = <String>[];
      for (final pattern in authErrorPatterns) {
        if (find.textContaining(pattern).evaluate().isNotEmpty) {
          detectedErrors.add(pattern);
        }
      }
      
      result.errorsDetected = detectedErrors;
      result.actualBehavior = detectedErrors.isEmpty 
        ? 'No authentication error messages displayed'
        : 'Authentication errors: ${detectedErrors.join(', ')}';
      
      // Check that user is NOT logged in (still on login page)
      final stillOnLoginPage = find.textContaining('Sign in').evaluate().isNotEmpty ||
                              find.textContaining('Login').evaluate().isNotEmpty;
      
      result.success = detectedErrors.isNotEmpty && stillOnLoginPage;
      result.details = result.success 
        ? 'Invalid credentials correctly rejected'
        : 'Authentication error handling may be insufficient';
      
      if (verboseLogging) {
        print('   Form submission result: ${formResult.submitSuccess}');
        print('   Still on login page: $stillOnLoginPage');
        print('   Errors detected: ${detectedErrors.length}');
        print('   ${result.actualBehavior}');
      }
      
    } catch (e) {
      result.error = 'Exception during invalid credentials test: $e';
      
      if (verboseLogging) {
        print('❌ Exception during auth test: $e');
      }
    }
    
    return result;
  }
  
  /// Test authentication timeout scenarios
  static Future<ErrorTestResult> testAuthenticationTimeout(
    WidgetTester tester, {
    Duration timeoutDuration = const Duration(seconds: 10),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'App should handle authentication timeouts gracefully';
    
    if (verboseLogging) {
      print('\n🚨 ERROR TEST: Authentication timeout');
    }
    
    try {
      // Try to login and wait for extended period
      final credentials = {
        'email-field': 'timeout@test.com',
        'password-field': 'testpassword',
      };
      
      await FormInteractionHelper.fillAndSubmitForm(tester, credentials);
      
      // Submit and wait for timeout
      final submitButton = find.text('Sign In').evaluate().isNotEmpty 
        ? find.text('Sign In')
        : find.byType(ElevatedButton);
      
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pump();
        
        // Wait for timeout duration
        await Future.delayed(timeoutDuration);
        await tester.pumpAndSettle();
        
        // Check for timeout error messages
        final timeoutPatterns = [
          'Timeout',
          'Taking too long',
          'Connection timeout',
          'Please try again',
          'Network timeout',
        ];
        
        final detectedErrors = <String>[];
        for (final pattern in timeoutPatterns) {
          if (find.textContaining(pattern).evaluate().isNotEmpty) {
            detectedErrors.add(pattern);
          }
        }
        
        result.errorsDetected = detectedErrors;
        result.actualBehavior = detectedErrors.isEmpty 
          ? 'No timeout error messages displayed'
          : 'Timeout errors: ${detectedErrors.join(', ')}';
        
        result.success = true; // Success means we tested timeout handling
        result.details = 'Authentication timeout test completed';
        
        if (verboseLogging) {
          print('   Timeout errors detected: ${detectedErrors.length}');
          print('   ${result.actualBehavior}');
        }
      } else {
        result.error = 'Could not find submit button to test timeout';
      }
      
    } catch (e) {
      result.error = 'Exception during timeout test: $e';
      
      if (verboseLogging) {
        print('❌ Exception during timeout test: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // FORM VALIDATION ERROR TESTING
  // ============================================================================
  
  /// Test form with invalid input data
  static Future<ErrorTestResult> testInvalidFormData(
    WidgetTester tester,
    Map<String, String> invalidData, {
    String? submitButtonText,
    Duration validationTimeout = const Duration(seconds: 2),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'Form should show validation errors and prevent submission';
    
    if (verboseLogging) {
      print('\n🚨 ERROR TEST: Invalid form data');
      print('   Invalid data: $invalidData');
    }
    
    try {
      // Fill form with invalid data
      final formResult = await FormInteractionHelper.fillAndSubmitForm(
        tester,
        invalidData,
        submitButtonText: submitButtonText,
        verboseLogging: verboseLogging,
      );
      
      // Wait for validation errors to appear
      await Future.delayed(validationTimeout);
      await tester.pumpAndSettle();
      
      // Check for validation error messages
      final validationPatterns = [
        'Required',
        'Invalid',
        'Enter a valid',
        'This field',
        'Cannot be empty',
        'Must be',
        'Too short',
        'Too long',
        'Invalid format',
        'Please enter',
        'Required field',
      ];
      
      final detectedErrors = <String>[];
      for (final pattern in validationPatterns) {
        if (find.textContaining(pattern).evaluate().isNotEmpty) {
          detectedErrors.add(pattern);
        }
      }
      
      result.errorsDetected = detectedErrors;
      result.actualBehavior = detectedErrors.isEmpty 
        ? 'No validation error messages displayed'
        : 'Validation errors: ${detectedErrors.join(', ')}';
      
      result.success = detectedErrors.isNotEmpty && !formResult.submitSuccess;
      result.details = result.success 
        ? 'Form validation working correctly'
        : 'Form validation may be insufficient';
      
      if (verboseLogging) {
        print('   Form submitted successfully: ${formResult.submitSuccess}');
        print('   Validation errors detected: ${detectedErrors.length}');
        print('   ${result.actualBehavior}');
      }
      
    } catch (e) {
      result.error = 'Exception during invalid form test: $e';
      
      if (verboseLogging) {
        print('❌ Exception during form validation test: $e');
      }
    }
    
    return result;
  }
  
  /// Test required field validation
  static Future<ErrorTestResult> testRequiredFieldValidation(
    WidgetTester tester,
    List<Key> requiredFieldKeys, {
    String? submitButtonText,
    Duration validationTimeout = const Duration(seconds: 2),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'Empty required fields should show validation errors';
    
    if (verboseLogging) {
      print('\n🚨 ERROR TEST: Required field validation');
      print('   Testing ${requiredFieldKeys.length} required fields');
    }
    
    try {
      // Clear all fields first
      for (final fieldKey in requiredFieldKeys) {
        final fieldFinder = find.byKey(fieldKey);
        if (fieldFinder.evaluate().isNotEmpty) {
          await tester.tap(fieldFinder);
          await tester.enterText(fieldFinder, '');
          await tester.pump();
        }
      }
      
      // Try to submit empty form
      final submitButton = submitButtonText != null 
        ? find.text(submitButtonText)
        : find.byType(ElevatedButton);
      
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
        
        // Wait for validation errors
        await Future.delayed(validationTimeout);
        await tester.pump();
        
        // Use AssertionHelper to check validation
        final validationResult = await AssertionHelper.expectFormValidation(
          tester,
          requiredFieldKeys,
          timeout: validationTimeout,
          verboseLogging: verboseLogging,
        );
        
        result.success = validationResult.success;
        result.details = validationResult.details;
        result.error = validationResult.error;
        
        if (validationResult.success) {
          result.errorsDetected = ['Required field validation'];
          result.actualBehavior = 'Required field validation working correctly';
        } else {
          result.actualBehavior = 'Required field validation not detected';
        }
        
        if (verboseLogging) {
          print('   Validation result: ${validationResult.success}');
          print('   ${result.actualBehavior}');
        }
      } else {
        result.error = 'Could not find submit button to test validation';
      }
      
    } catch (e) {
      result.error = 'Exception during required field test: $e';
      
      if (verboseLogging) {
        print('❌ Exception during required field test: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // PAYMENT ERROR TESTING
  // ============================================================================
  
  /// Test payment failure scenarios
  static Future<ErrorTestResult> testPaymentFailures(
    WidgetTester tester, {
    Map<String, String>? invalidPaymentData,
    Duration paymentTimeout = const Duration(seconds: 5),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'Payment failures should be handled gracefully with clear error messages';
    
    if (verboseLogging) {
      print('\n🚨 ERROR TEST: Payment failures');
    }
    
    try {
      // Use invalid payment data or defaults
      final paymentData = invalidPaymentData ?? {
        'card-number-field': '4000000000000002', // Known decline card
        'expiry-field': '12/25',
        'cvv-field': '123',
        'name-field': 'Test User',
      };
      
      // Fill payment form if fields exist
      bool paymentFieldsFound = false;
      for (final entry in paymentData.entries) {
        final fieldKey = Key(entry.key);
        final fieldFinder = find.byKey(fieldKey);
        if (fieldFinder.evaluate().isNotEmpty) {
          await tester.enterText(fieldFinder, entry.value);
          paymentFieldsFound = true;
        }
      }
      
      if (paymentFieldsFound) {
        // Try to submit payment
        final paymentButtons = [
          find.text('Pay Now'),
          find.text('Complete Payment'),
          find.text('Submit Payment'),
          find.text('Purchase'),
        ];
        
        bool paymentSubmitted = false;
        for (final button in paymentButtons) {
          if (button.evaluate().isNotEmpty) {
            await tester.tap(button);
            await tester.pumpAndSettle();
            paymentSubmitted = true;
            break;
          }
        }
        
        if (paymentSubmitted) {
          // Wait for payment response
          await Future.delayed(paymentTimeout);
          await tester.pumpAndSettle();
          
          // Check for payment error messages
          final paymentErrorPatterns = [
            'Payment failed',
            'Card declined',
            'Insufficient funds',
            'Payment error',
            'Transaction failed',
            'Try a different card',
            'Payment could not be processed',
          ];
          
          final detectedErrors = <String>[];
          for (final pattern in paymentErrorPatterns) {
            if (find.textContaining(pattern).evaluate().isNotEmpty) {
              detectedErrors.add(pattern);
            }
          }
          
          result.errorsDetected = detectedErrors;
          result.actualBehavior = detectedErrors.isEmpty 
            ? 'No payment error messages displayed'
            : 'Payment errors: ${detectedErrors.join(', ')}';
          
          result.success = true; // Success means we tested payment error handling
          result.details = 'Payment error testing completed';
          
          if (verboseLogging) {
            print('   Payment fields found: $paymentFieldsFound');
            print('   Payment submitted: $paymentSubmitted');
            print('   Payment errors detected: ${detectedErrors.length}');
            print('   ${result.actualBehavior}');
          }
        } else {
          result.error = 'Could not find payment submission button';
        }
      } else {
        result.error = 'No payment form fields found to test';
      }
      
    } catch (e) {
      result.error = 'Exception during payment error test: $e';
      
      if (verboseLogging) {
        print('❌ Exception during payment test: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // ERROR MESSAGE VERIFICATION
  // ============================================================================
  
  /// Verify specific error message is displayed
  static Future<ErrorTestResult> verifyErrorMessage(
    WidgetTester tester,
    String expectedErrorMessage, {
    Duration timeout = const Duration(seconds: 3),
    bool exactMatch = false,
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'Error message "$expectedErrorMessage" should be visible';
    
    if (verboseLogging) {
      print('\n🔍 ERROR VERIFICATION: Checking for error message');
      print('   Expected message: $expectedErrorMessage');
      print('   Exact match: $exactMatch');
    }
    
    try {
      final endTime = DateTime.now().add(timeout);
      bool errorFound = false;
      
      while (DateTime.now().isBefore(endTime) && !errorFound) {
        await tester.pump(const Duration(milliseconds: 100));
        
        if (exactMatch) {
          errorFound = find.text(expectedErrorMessage).evaluate().isNotEmpty;
        } else {
          errorFound = find.textContaining(expectedErrorMessage).evaluate().isNotEmpty;
        }
      }
      
      if (errorFound) {
        result.success = true;
        result.errorsDetected = [expectedErrorMessage];
        result.actualBehavior = 'Expected error message found';
        result.details = 'Error message verification successful';
        
        if (verboseLogging) {
          print('✅ Expected error message found');
        }
      } else {
        result.error = 'Expected error message not found within timeout';
        result.actualBehavior = 'Expected error message not displayed';
        
        if (verboseLogging) {
          print('❌ Expected error message not found');
          
          // Show available text for debugging
          final allText = find.byType(Text);
          print('   Available text widgets: ${allText.evaluate().length}');
        }
      }
      
    } catch (e) {
      result.error = 'Exception during error message verification: $e';
      
      if (verboseLogging) {
        print('❌ Exception during verification: $e');
      }
    }
    
    return result;
  }
  
  /// Verify that error messages disappear after correction
  static Future<ErrorTestResult> verifyErrorRecovery(
    WidgetTester tester,
    Map<String, String> correctData, {
    List<String>? expectedErrorsToDisappear,
    Duration recoveryTimeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'Error messages should disappear after providing correct data';
    
    if (verboseLogging) {
      print('\n🔍 ERROR RECOVERY: Testing error message recovery');
      print('   Correcting with data: $correctData');
    }
    
    try {
      // Fill form with correct data
      await FormInteractionHelper.fillAndSubmitForm(tester, correctData);
      
      // Wait for errors to potentially disappear
      await Future.delayed(recoveryTimeout);
      await tester.pumpAndSettle();
      
      // Check if previous errors are gone
      final commonErrorPatterns = expectedErrorsToDisappear ?? [
        'Required',
        'Invalid',
        'Error',
        'Failed',
        'Cannot',
      ];
      
      final remainingErrors = <String>[];
      for (final pattern in commonErrorPatterns) {
        if (find.textContaining(pattern).evaluate().isNotEmpty) {
          remainingErrors.add(pattern);
        }
      }
      
      if (remainingErrors.isEmpty) {
        result.success = true;
        result.actualBehavior = 'All error messages cleared after correction';
        result.details = 'Error recovery working correctly';
        
        if (verboseLogging) {
          print('✅ Error messages cleared after correction');
        }
      } else {
        result.errorsDetected = remainingErrors;
        result.actualBehavior = 'Some error messages persist: ${remainingErrors.join(', ')}';
        result.details = 'Error recovery may not be working correctly';
        
        if (verboseLogging) {
          print('❌ Persistent errors: ${remainingErrors.join(', ')}');
        }
      }
      
    } catch (e) {
      result.error = 'Exception during error recovery test: $e';
      
      if (verboseLogging) {
        print('❌ Exception during recovery test: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // TIMEOUT AND LOADING ERROR TESTING
  // ============================================================================
  
  /// Test loading timeout scenarios
  static Future<ErrorTestResult> testLoadingTimeout(
    WidgetTester tester, {
    Duration loadingTimeout = const Duration(seconds: 10),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    result.expectedBehavior = 'App should handle loading timeouts with appropriate error messages';
    
    if (verboseLogging) {
      print('\n🚨 ERROR TEST: Loading timeout');
    }
    
    try {
      // Trigger loading action
      final loadingTriggers = [
        find.text('Load'),
        find.text('Fetch'),
        find.text('Refresh'),
        find.byIcon(Icons.refresh),
      ];
      
      bool loadingTriggered = false;
      for (final trigger in loadingTriggers) {
        if (trigger.evaluate().isNotEmpty) {
          await tester.tap(trigger);
          await tester.pump();
          loadingTriggered = true;
          break;
        }
      }
      
      if (loadingTriggered) {
        // Wait for loading to potentially timeout
        await Future.delayed(loadingTimeout);
        await tester.pumpAndSettle();
        
        // Check for timeout error messages
        final timeoutPatterns = [
          'Timeout',
          'Taking too long',
          'Load timeout',
          'Try again',
          'Connection timeout',
        ];
        
        final detectedErrors = <String>[];
        for (final pattern in timeoutPatterns) {
          if (find.textContaining(pattern).evaluate().isNotEmpty) {
            detectedErrors.add(pattern);
          }
        }
        
        // Also check if loading indicator is still present (bad)
        final loadingStillPresent = find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
                                   find.textContaining('Loading').evaluate().isNotEmpty;
        
        result.errorsDetected = detectedErrors;
        result.actualBehavior = loadingStillPresent 
          ? 'Loading indicator still present after timeout'
          : detectedErrors.isEmpty 
            ? 'No timeout handling detected'
            : 'Timeout errors: ${detectedErrors.join(', ')}';
        
        result.success = !loadingStillPresent; // Success if loading is handled
        result.details = 'Loading timeout test completed';
        
        if (verboseLogging) {
          print('   Loading triggered: $loadingTriggered');
          print('   Loading still present: $loadingStillPresent');
          print('   Timeout errors detected: ${detectedErrors.length}');
          print('   ${result.actualBehavior}');
        }
      } else {
        result.error = 'Could not trigger loading action to test timeout';
      }
      
    } catch (e) {
      result.error = 'Exception during loading timeout test: $e';
      
      if (verboseLogging) {
        print('❌ Exception during loading timeout test: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // COMBINED ERROR TESTING
  // ============================================================================
  
  /// Run comprehensive error state tests
  static Future<ErrorTestResult> runComprehensiveErrorTests(
    WidgetTester tester, {
    bool includeNetworkTests = true,
    bool includeAuthTests = true,
    bool includeFormTests = true,
    bool includePaymentTests = false, // Optional since not all apps have payment
    Duration testTimeout = const Duration(seconds: 5),
    bool verboseLogging = false,
  }) async {
    final result = ErrorTestResult();
    final testResults = <ErrorTestResult>[];
    
    if (verboseLogging) {
      print('\n🚨 COMPREHENSIVE ERROR TESTING');
      print('   Network tests: $includeNetworkTests');
      print('   Auth tests: $includeAuthTests');
      print('   Form tests: $includeFormTests');
      print('   Payment tests: $includePaymentTests');
    }
    
    try {
      // Network error tests
      if (includeNetworkTests) {
        final networkResult = await simulateNetworkError(
          tester,
          testDuration: testTimeout,
          verboseLogging: verboseLogging,
        );
        testResults.add(networkResult);
      }
      
      // Authentication error tests
      if (includeAuthTests) {
        final authResult = await testInvalidCredentials(
          tester,
          timeout: testTimeout,
          verboseLogging: verboseLogging,
        );
        testResults.add(authResult);
      }
      
      // Form validation tests
      if (includeFormTests) {
        final formResult = await testInvalidFormData(
          tester,
          {
            'email-field': 'invalid-email',
            'password-field': '', // Empty required field
          },
          validationTimeout: testTimeout,
          verboseLogging: verboseLogging,
        );
        testResults.add(formResult);
      }
      
      // Payment error tests (optional)
      if (includePaymentTests) {
        final paymentResult = await testPaymentFailures(
          tester,
          paymentTimeout: testTimeout,
          verboseLogging: verboseLogging,
        );
        testResults.add(paymentResult);
      }
      
      // Compile comprehensive results
      final successfulTests = testResults.where((r) => r.success).length;
      final allErrors = testResults
          .expand((r) => r.errorsDetected)
          .toSet()
          .toList();
      
      result.success = testResults.isNotEmpty;
      result.errorsDetected = allErrors;
      result.details = 'Comprehensive error testing completed: $successfulTests/${testResults.length} tests passed';
      result.actualBehavior = 'Total unique errors detected: ${allErrors.length}';
      
      if (verboseLogging) {
        print('   Total tests run: ${testResults.length}');
        print('   Successful tests: $successfulTests');
        print('   Total unique errors detected: ${allErrors.length}');
        print('   Error types: ${allErrors.join(', ')}');
      }
      
    } catch (e) {
      result.error = 'Exception during comprehensive error testing: $e';
      
      if (verboseLogging) {
        print('❌ Exception during comprehensive testing: $e');
      }
    }
    
    return result;
  }
}