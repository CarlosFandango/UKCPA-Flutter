import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'authentication_flow_helper.dart';

/// Result class for assertion operations
class AssertionResult {
  bool success;
  String? error;
  String? details;
  
  AssertionResult({
    this.success = false,
    this.error,
    this.details,
  });
  
  String get summary => success 
    ? 'Assertion passed${details != null ? ': $details' : ''}'
    : 'Assertion failed${error != null ? ': $error' : ''}';
}

/// Helper for common assertion patterns in integration tests
/// Provides reusable, consistent assertion methods with detailed error messages
class AssertionHelper {
  
  // ============================================================================
  // COURSE DATA ASSERTIONS
  // ============================================================================
  
  /// Assert that a specific course is visible on the page
  static Future<AssertionResult> expectCourseVisible(
    WidgetTester tester,
    String courseName, {
    Duration timeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking course visibility');
      print('   Course: $courseName');
    }
    
    try {
      // Wait for course to appear
      final endTime = DateTime.now().add(timeout);
      bool courseFound = false;
      
      while (DateTime.now().isBefore(endTime) && !courseFound) {
        await tester.pump(const Duration(milliseconds: 100));
        
        // Check multiple ways courses might be displayed
        final courseFinderText = find.text(courseName);
        final courseFinderContaining = find.textContaining(courseName);
        final courseFinderRichText = find.byWidgetPredicate((widget) {
          if (widget is RichText) {
            return widget.text.toPlainText().contains(courseName);
          }
          return false;
        });
        
        courseFound = courseFinderText.evaluate().isNotEmpty ||
                     courseFinderContaining.evaluate().isNotEmpty ||
                     courseFinderRichText.evaluate().isNotEmpty;
      }
      
      if (courseFound) {
        result.success = true;
        result.details = 'Course "$courseName" found on page';
        
        if (verboseLogging) {
          print('✅ Course found: $courseName');
        }
      } else {
        result.error = 'Course "$courseName" not found within ${timeout.inSeconds}s timeout';
        
        if (verboseLogging) {
          print('❌ Course not found: $courseName');
          
          // Log available courses for debugging
          final allTextWidgets = find.byType(Text);
          print('   Available text widgets: ${allTextWidgets.evaluate().length}');
          
          // Show some course-like text for debugging
          final coursePatterns = ['Course', 'Class', 'Workshop', 'Lesson'];
          for (final pattern in coursePatterns) {
            final patternFinder = find.textContaining(pattern);
            if (patternFinder.evaluate().isNotEmpty) {
              print('   Found "$pattern" widgets: ${patternFinder.evaluate().length}');
            }
          }
        }
      }
    } catch (e) {
      result.error = 'Error checking course visibility: $e';
      
      if (verboseLogging) {
        print('❌ Exception during course check: $e');
      }
    }
    
    return result;
  }
  
  /// Assert that multiple courses are visible
  static Future<AssertionResult> expectCoursesVisible(
    WidgetTester tester,
    List<String> courseNames, {
    Duration timeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    final foundCourses = <String>[];
    final missingCourses = <String>[];
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking multiple courses visibility');
      print('   Courses: ${courseNames.join(', ')}');
    }
    
    for (final courseName in courseNames) {
      final courseResult = await expectCourseVisible(
        tester, 
        courseName, 
        timeout: timeout,
        verboseLogging: false, // Avoid spam
      );
      
      if (courseResult.success) {
        foundCourses.add(courseName);
      } else {
        missingCourses.add(courseName);
      }
    }
    
    if (missingCourses.isEmpty) {
      result.success = true;
      result.details = 'All ${courseNames.length} courses found: ${foundCourses.join(', ')}';
      
      if (verboseLogging) {
        print('✅ All courses found: ${foundCourses.join(', ')}');
      }
    } else {
      result.error = 'Missing courses: ${missingCourses.join(', ')}';
      result.details = 'Found: ${foundCourses.join(', ')}';
      
      if (verboseLogging) {
        print('❌ Missing courses: ${missingCourses.join(', ')}');
        print('   Found courses: ${foundCourses.join(', ')}');
      }
    }
    
    return result;
  }
  
  /// Assert that a course has specific details (price, description, etc.)
  static Future<AssertionResult> expectCourseDetails(
    WidgetTester tester,
    String courseName,
    Map<String, String> expectedDetails, {
    Duration timeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    final foundDetails = <String, bool>{};
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking course details');
      print('   Course: $courseName');
      print('   Expected details: $expectedDetails');
    }
    
    try {
      // First ensure course is visible
      final courseResult = await expectCourseVisible(tester, courseName, timeout: timeout);
      if (!courseResult.success) {
        result.error = 'Course not found: ${courseResult.error}';
        return result;
      }
      
      // Check each expected detail
      for (final entry in expectedDetails.entries) {
        final detailKey = entry.key;
        final detailValue = entry.value;
        
        final detailFinder = find.textContaining(detailValue);
        foundDetails[detailKey] = detailFinder.evaluate().isNotEmpty;
        
        if (verboseLogging) {
          final status = foundDetails[detailKey]! ? '✅' : '❌';
          print('   $status $detailKey: $detailValue');
        }
      }
      
      final missingDetails = foundDetails.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();
      
      if (missingDetails.isEmpty) {
        result.success = true;
        result.details = 'All course details found for "$courseName"';
      } else {
        result.error = 'Missing details for "$courseName": ${missingDetails.join(', ')}';
      }
      
    } catch (e) {
      result.error = 'Error checking course details: $e';
      
      if (verboseLogging) {
        print('❌ Exception during course details check: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // UI STATE ASSERTIONS
  // ============================================================================
  
  /// Assert that no error messages are visible
  static Future<AssertionResult> expectNoErrors(
    WidgetTester tester, {
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking for error messages');
    }
    
    try {
      final errorPatterns = [
        'Error',
        'Failed',
        'Invalid',
        'Required',
        'Cannot',
        'Unable',
        'Network error',
        'Something went wrong',
        'Try again',
      ];
      
      final foundErrors = <String>[];
      
      for (final pattern in errorPatterns) {
        final errorFinder = find.textContaining(pattern);
        if (errorFinder.evaluate().isNotEmpty) {
          foundErrors.add(pattern);
        }
      }
      
      // Also check for common error UI elements
      final errorWidgetFinder = find.byWidgetPredicate((widget) => 
          widget is Container && 
          widget.decoration != null &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).color == Colors.red);
      
      if (errorWidgetFinder.evaluate().isNotEmpty) {
        foundErrors.add('Red error container');
      }
      
      if (foundErrors.isEmpty) {
        result.success = true;
        result.details = 'No error messages found';
        
        if (verboseLogging) {
          print('✅ No errors found');
        }
      } else {
        result.error = 'Found error indicators: ${foundErrors.join(', ')}';
        
        if (verboseLogging) {
          print('❌ Errors found: ${foundErrors.join(', ')}');
        }
      }
      
    } catch (e) {
      result.error = 'Error checking for errors: $e';
      
      if (verboseLogging) {
        print('❌ Exception during error check: $e');
      }
    }
    
    return result;
  }
  
  /// Assert that a loading state is visible
  static Future<AssertionResult> expectLoadingState(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 2),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking for loading state');
    }
    
    try {
      final endTime = DateTime.now().add(timeout);
      bool loadingFound = false;
      
      while (DateTime.now().isBefore(endTime) && !loadingFound) {
        await tester.pump(const Duration(milliseconds: 100));
        
        // Check for various loading indicators
        final progressIndicator = find.byType(CircularProgressIndicator);
        final linearProgress = find.byType(LinearProgressIndicator);
        final loadingText = find.textContaining('Loading');
        final loadingText2 = find.textContaining('Please wait');
        
        loadingFound = progressIndicator.evaluate().isNotEmpty ||
                      linearProgress.evaluate().isNotEmpty ||
                      loadingText.evaluate().isNotEmpty ||
                      loadingText2.evaluate().isNotEmpty;
      }
      
      if (loadingFound) {
        result.success = true;
        result.details = 'Loading state detected';
        
        if (verboseLogging) {
          print('✅ Loading state found');
        }
      } else {
        result.error = 'No loading state found within ${timeout.inSeconds}s timeout';
        
        if (verboseLogging) {
          print('❌ No loading state found');
        }
      }
      
    } catch (e) {
      result.error = 'Error checking loading state: $e';
      
      if (verboseLogging) {
        print('❌ Exception during loading check: $e');
      }
    }
    
    return result;
  }
  
  /// Assert that loading state has disappeared (content loaded)
  static Future<AssertionResult> expectLoadingComplete(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Waiting for loading to complete');
    }
    
    try {
      final endTime = DateTime.now().add(timeout);
      bool loadingGone = false;
      
      while (DateTime.now().isBefore(endTime) && !loadingGone) {
        await tester.pump(const Duration(milliseconds: 100));
        
        // Check that loading indicators are gone
        final progressIndicator = find.byType(CircularProgressIndicator);
        final linearProgress = find.byType(LinearProgressIndicator);
        final loadingText = find.textContaining('Loading');
        
        loadingGone = progressIndicator.evaluate().isEmpty &&
                     linearProgress.evaluate().isEmpty &&
                     loadingText.evaluate().isEmpty;
      }
      
      if (loadingGone) {
        result.success = true;
        result.details = 'Loading completed';
        
        if (verboseLogging) {
          print('✅ Loading completed');
        }
      } else {
        result.error = 'Loading did not complete within ${timeout.inSeconds}s timeout';
        
        if (verboseLogging) {
          print('❌ Loading timeout');
        }
      }
      
    } catch (e) {
      result.error = 'Error waiting for loading completion: $e';
      
      if (verboseLogging) {
        print('❌ Exception during loading wait: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // AUTHENTICATION STATE ASSERTIONS
  // ============================================================================
  
  /// Assert that user is in expected authentication state
  static Future<AssertionResult> expectAuthenticatedState(
    WidgetTester tester,
    UserRole expectedRole, {
    Duration timeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking authentication state');
      print('   Expected role: $expectedRole');
    }
    
    try {
      final authState = await AuthenticationFlowHelper.getCurrentAuthState(
        tester,
        timeout: timeout,
        verboseLogging: verboseLogging,
      );
      
      if (authState.isAuthenticated && authState.userRole == expectedRole) {
        result.success = true;
        result.details = 'User authenticated as ${expectedRole.toString()}';
        
        if (verboseLogging) {
          print('✅ Authentication state correct: $expectedRole');
        }
      } else if (!authState.isAuthenticated && expectedRole == UserRole.guest) {
        result.success = true;
        result.details = 'User in guest state as expected';
        
        if (verboseLogging) {
          print('✅ Guest state correct');
        }
      } else {
        result.error = 'Authentication state mismatch. Expected: $expectedRole, Actual: ${authState.userRole ?? 'unauthenticated'}';
        
        if (verboseLogging) {
          print('❌ Auth state mismatch - Expected: $expectedRole, Actual: ${authState.userRole}');
        }
      }
      
    } catch (e) {
      result.error = 'Error checking authentication state: $e';
      
      if (verboseLogging) {
        print('❌ Exception during auth state check: $e');
      }
    }
    
    return result;
  }
  
  /// Assert that user is logged out (guest state)
  static Future<AssertionResult> expectLoggedOut(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    return await expectAuthenticatedState(
      tester,
      UserRole.guest,
      timeout: timeout,
      verboseLogging: verboseLogging,
    );
  }
  
  // ============================================================================
  // FORM STATE ASSERTIONS
  // ============================================================================
  
  /// Assert that form fields contain expected values
  static Future<AssertionResult> expectFormValues(
    WidgetTester tester,
    Map<Key, String> expectedValues, {
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    final foundValues = <String, bool>{};
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking form field values');
    }
    
    try {
      for (final entry in expectedValues.entries) {
        final fieldKey = entry.key;
        final expectedValue = entry.value;
        
        final fieldFinder = find.byKey(fieldKey);
        if (fieldFinder.evaluate().isNotEmpty) {
          final widget = fieldFinder.evaluate().first.widget;
          String? actualValue;
          
          if (widget is TextField) {
            actualValue = widget.controller?.text;
          } else if (widget is TextFormField) {
            actualValue = widget.controller?.text;
          }
          
          final matches = actualValue == expectedValue;
          foundValues[fieldKey.toString()] = matches;
          
          if (verboseLogging) {
            final status = matches ? '✅' : '❌';
            print('   $status Field $fieldKey: Expected "$expectedValue", Got "$actualValue"');
          }
        } else {
          foundValues[fieldKey.toString()] = false;
          
          if (verboseLogging) {
            print('   ❌ Field $fieldKey: Not found');
          }
        }
      }
      
      final incorrectFields = foundValues.entries
          .where((entry) => !entry.value)
          .map((entry) => entry.key)
          .toList();
      
      if (incorrectFields.isEmpty) {
        result.success = true;
        result.details = 'All ${expectedValues.length} form fields have expected values';
      } else {
        result.error = 'Incorrect field values: ${incorrectFields.join(', ')}';
      }
      
    } catch (e) {
      result.error = 'Error checking form values: $e';
      
      if (verboseLogging) {
        print('❌ Exception during form check: $e');
      }
    }
    
    return result;
  }
  
  /// Assert that required form validation is working
  static Future<AssertionResult> expectFormValidation(
    WidgetTester tester,
    List<Key> requiredFields, {
    Duration timeout = const Duration(seconds: 2),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking form validation');
      print('   Required fields: ${requiredFields.length}');
    }
    
    try {
      // Try to submit empty form to trigger validation
      final submitButton = find.byType(ElevatedButton).first;
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle();
        
        // Wait for validation messages to appear
        await Future.delayed(timeout);
        await tester.pump();
        
        // Check for validation error messages
        final validationPatterns = [
          'Required',
          'This field is required',
          'Please enter',
          'Cannot be empty',
          'Invalid',
        ];
        
        bool validationFound = false;
        for (final pattern in validationPatterns) {
          if (find.textContaining(pattern).evaluate().isNotEmpty) {
            validationFound = true;
            break;
          }
        }
        
        if (validationFound) {
          result.success = true;
          result.details = 'Form validation is working';
          
          if (verboseLogging) {
            print('✅ Form validation found');
          }
        } else {
          result.error = 'No form validation messages found';
          
          if (verboseLogging) {
            print('❌ No validation messages found');
          }
        }
      } else {
        result.error = 'No submit button found to test validation';
        
        if (verboseLogging) {
          print('❌ No submit button found');
        }
      }
      
    } catch (e) {
      result.error = 'Error testing form validation: $e';
      
      if (verboseLogging) {
        print('❌ Exception during validation test: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // NAVIGATION ASSERTIONS
  // ============================================================================
  
  /// Assert that user is on expected page
  static Future<AssertionResult> expectCurrentPage(
    WidgetTester tester,
    String expectedPage, {
    Duration timeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking current page');
      print('   Expected: $expectedPage');
    }
    
    try {
      final endTime = DateTime.now().add(timeout);
      String currentPage = 'Unknown';
      
      while (DateTime.now().isBefore(endTime)) {
        await tester.pump(const Duration(milliseconds: 100));
        
        // Simple page detection based on key elements
        if (expectedPage.toLowerCase().contains('login') && 
            find.textContaining('Sign in').evaluate().isNotEmpty) {
          currentPage = 'Login';
          break;
        } else if (expectedPage.toLowerCase().contains('course') && 
                   find.textContaining('Course').evaluate().isNotEmpty) {
          currentPage = 'Course List';
          break;
        } else if (expectedPage.toLowerCase().contains('home') && 
                   find.textContaining('Home').evaluate().isNotEmpty) {
          currentPage = 'Home';
          break;
        }
        
        // Generic text matching
        if (find.textContaining(expectedPage).evaluate().isNotEmpty) {
          currentPage = expectedPage;
          break;
        }
      }
      
      if (currentPage.toLowerCase() == expectedPage.toLowerCase() ||
          currentPage.toLowerCase().contains(expectedPage.toLowerCase())) {
        result.success = true;
        result.details = 'On expected page: $currentPage';
        
        if (verboseLogging) {
          print('✅ On expected page: $currentPage');
        }
      } else {
        result.error = 'Page mismatch. Expected: $expectedPage, Actual: $currentPage';
        
        if (verboseLogging) {
          print('❌ Page mismatch - Expected: $expectedPage, Actual: $currentPage');
        }
      }
      
    } catch (e) {
      result.error = 'Error checking current page: $e';
      
      if (verboseLogging) {
        print('❌ Exception during page check: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // CUSTOM WIDGET MATCHERS
  // ============================================================================
  
  /// Assert that specific widget types are present
  static Future<AssertionResult> expectWidgetTypes(
    WidgetTester tester,
    List<Type> expectedTypes, {
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    final foundTypes = <Type>[];
    final missingTypes = <Type>[];
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking widget types');
      print('   Expected types: ${expectedTypes.map((t) => t.toString()).join(', ')}');
    }
    
    try {
      for (final expectedType in expectedTypes) {
        final finder = find.byType(expectedType);
        if (finder.evaluate().isNotEmpty) {
          foundTypes.add(expectedType);
        } else {
          missingTypes.add(expectedType);
        }
        
        if (verboseLogging) {
          final status = finder.evaluate().isNotEmpty ? '✅' : '❌';
          print('   $status ${expectedType.toString()}: ${finder.evaluate().length} found');
        }
      }
      
      if (missingTypes.isEmpty) {
        result.success = true;
        result.details = 'All ${expectedTypes.length} widget types found';
      } else {
        result.error = 'Missing widget types: ${missingTypes.map((t) => t.toString()).join(', ')}';
        result.details = 'Found types: ${foundTypes.map((t) => t.toString()).join(', ')}';
      }
      
    } catch (e) {
      result.error = 'Error checking widget types: $e';
      
      if (verboseLogging) {
        print('❌ Exception during widget type check: $e');
      }
    }
    
    return result;
  }
  
  /// Assert that minimum number of specific widgets are present
  static Future<AssertionResult> expectMinimumWidgets(
    WidgetTester tester,
    Type widgetType,
    int minimumCount, {
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Checking minimum widget count');
      print('   Type: $widgetType, Minimum: $minimumCount');
    }
    
    try {
      final finder = find.byType(widgetType);
      final actualCount = finder.evaluate().length;
      
      if (actualCount >= minimumCount) {
        result.success = true;
        result.details = 'Found $actualCount ${widgetType.toString()} widgets (minimum: $minimumCount)';
        
        if (verboseLogging) {
          print('✅ Sufficient widgets: $actualCount >= $minimumCount');
        }
      } else {
        result.error = 'Insufficient ${widgetType.toString()} widgets. Found: $actualCount, Required: $minimumCount';
        
        if (verboseLogging) {
          print('❌ Insufficient widgets: $actualCount < $minimumCount');
        }
      }
      
    } catch (e) {
      result.error = 'Error checking widget count: $e';
      
      if (verboseLogging) {
        print('❌ Exception during widget count check: $e');
      }
    }
    
    return result;
  }
  
  // ============================================================================
  // COMBINED ASSERTIONS
  // ============================================================================
  
  /// Run multiple assertions and return combined result
  static Future<AssertionResult> expectAll(
    List<Future<AssertionResult>> assertions, {
    bool verboseLogging = false,
  }) async {
    final result = AssertionResult();
    final results = <AssertionResult>[];
    
    if (verboseLogging) {
      print('\n🔍 ASSERTION: Running ${assertions.length} combined assertions');
    }
    
    try {
      for (final assertion in assertions) {
        final assertionResult = await assertion;
        results.add(assertionResult);
      }
      
      final failedAssertions = results.where((r) => !r.success).toList();
      
      if (failedAssertions.isEmpty) {
        result.success = true;
        result.details = 'All ${results.length} assertions passed';
        
        if (verboseLogging) {
          print('✅ All ${results.length} assertions passed');
        }
      } else {
        result.error = 'Failed assertions: ${failedAssertions.length}/${results.length}';
        result.details = failedAssertions.map((r) => r.error).join('; ');
        
        if (verboseLogging) {
          print('❌ Failed assertions: ${failedAssertions.length}/${results.length}');
          for (int i = 0; i < failedAssertions.length; i++) {
            print('   ${i + 1}. ${failedAssertions[i].error}');
          }
        }
      }
      
    } catch (e) {
      result.error = 'Error running combined assertions: $e';
      
      if (verboseLogging) {
        print('❌ Exception during combined assertions: $e');
      }
    }
    
    return result;
  }
}