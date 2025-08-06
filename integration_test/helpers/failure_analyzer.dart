import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

/// Automatic failure analysis and documentation generator
/// Creates detailed investigation reports for failed tests
class FailureAnalyzer {
  static const String _failureReportsDir = 'test_results/failure_reports';
  static String _actualReportsDir = '';
  static final List<TestFailure> _failures = [];
  static final Map<String, dynamic> _testContext = {};

  /// Initialize failure tracking for a test session
  static void initializeSession() {
    _failures.clear();
    _testContext.clear();
    _testContext['session_start'] = DateTime.now().toIso8601String();
    _testContext['platform'] = Platform.operatingSystem;
    _testContext['dart_version'] = Platform.version;
    
    // Try multiple directory locations for reports (iOS simulator workaround)
    _actualReportsDir = _ensureReportsDirectory();
  }

  /// Ensure reports directory exists with multiple fallback locations
  static String _ensureReportsDirectory() {
    final fallbackDirs = [
      _failureReportsDir,                    // Primary: test_results/failure_reports
      'test_results',                        // Fallback 1: test_results/ (usually works)
      'reports',                             // Fallback 2: reports/
      'test_reports',                        // Fallback 3: test_reports/
      '.',                                   // Fallback 4: current directory
    ];
    
    for (final dirPath in fallbackDirs) {
      try {
        final dir = Directory(dirPath);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        
        // Test write permissions by creating a temp file
        final testFile = File('$dirPath/.write_test');
        testFile.writeAsStringSync('test');
        testFile.deleteSync();
        
        print('📁 Using reports directory: $dirPath');
        return dirPath;
      } catch (e) {
        print('⚠️  Cannot use directory $dirPath: $e');
        continue;
      }
    }
    
    // This should never happen since current directory is the final fallback
    print('❌ Could not create any reports directory');
    return '.';
  }

  /// Record a test failure with context
  static void recordFailure({
    required String testName,
    required String testFile,
    required dynamic exception,
    required StackTrace stackTrace,
    Map<String, dynamic>? additionalContext,
  }) {
    final failure = TestFailure(
      testName: testName,
      testFile: testFile,
      exception: exception,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      additionalContext: additionalContext ?? {},
    );
    
    _failures.add(failure);
    print('🔍 Failure recorded: $testName');
  }

  /// Add context information for the current test session
  static void addContext(String key, dynamic value) {
    _testContext[key] = value;
  }

  /// Generate comprehensive failure analysis report
  static Future<void> generateFailureReport() async {
    if (_failures.isEmpty) {
      print('✅ No failures to analyze');
      return;
    }

    final timestamp = DateTime.now();
    final report = _buildFailureReport(timestamp);
    
    // Try to save to file first (works in most environments)
    final reportFileName = 'failure_analysis_${timestamp.millisecondsSinceEpoch}.md';
    final reportFile = '$_actualReportsDir/$reportFileName';
    
    bool fileSaved = false;
    try {
      await File(reportFile).writeAsString(report);
      print('📊 Failure analysis report generated: $reportFile');
      
      // Also create a latest report for easy access
      final latestReportFile = '$_actualReportsDir/latest_failure_report.md';
      await File(latestReportFile).writeAsString(report);
      print('🔄 Latest report updated: $latestReportFile');
      
      print('📁 Reports saved in: $_actualReportsDir/');
      fileSaved = true;
    } catch (e) {
      // File system is read-only (iOS simulator) - output to stdout instead
      print('⚠️  File system is read-only, outputting failure analysis to console:');
      print('');
      print('=' * 80);
      print('FAILURE ANALYSIS REPORT - ${timestamp.toIso8601String()}');
      print('=' * 80);
      print(report);
      print('=' * 80);
      print('END FAILURE ANALYSIS REPORT');
      print('=' * 80);
      print('');
      print('💡 Copy the analysis above to investigate and resolve test failures');
    }
    
    print('📋 Summary: ${_failures.length} failures analyzed');
    if (!fileSaved) {
      print('📄 Analysis output above contains all investigation details');
    }
  }

  /// Build the comprehensive failure report
  static String _buildFailureReport(DateTime timestamp) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('# Integration Test Failure Analysis Report');
    buffer.writeln('');
    buffer.writeln('**Generated:** ${timestamp.toIso8601String()}');
    buffer.writeln('**Session Started:** ${_testContext['session_start']}');
    buffer.writeln('**Platform:** ${_testContext['platform']}');
    buffer.writeln('**Total Failures:** ${_failures.length}');
    buffer.writeln('');

    // Executive Summary
    buffer.writeln('## 🎯 Executive Summary');
    buffer.writeln('');
    buffer.writeln(_generateExecutiveSummary());
    buffer.writeln('');

    // Quick Action Items
    buffer.writeln('## ⚡ Immediate Action Items');
    buffer.writeln('');
    buffer.writeln(_generateActionItems());
    buffer.writeln('');

    // Detailed Failure Analysis
    buffer.writeln('## 🔍 Detailed Failure Analysis');
    buffer.writeln('');
    
    for (int i = 0; i < _failures.length; i++) {
      final failure = _failures[i];
      buffer.writeln(_buildFailureAnalysis(failure, i + 1));
      buffer.writeln('');
    }

    // Investigation Guide
    buffer.writeln('## 🧭 Investigation Guide');
    buffer.writeln('');
    buffer.writeln(_generateInvestigationGuide());
    buffer.writeln('');

    // Common Patterns
    buffer.writeln('## 🔄 Identified Patterns');
    buffer.writeln('');
    buffer.writeln(_analyzeFailurePatterns());
    buffer.writeln('');

    // Resolution Suggestions
    buffer.writeln('## 💡 Resolution Suggestions');
    buffer.writeln('');
    buffer.writeln(_generateResolutionSuggestions());
    buffer.writeln('');

    // Environment Context
    buffer.writeln('## 🌍 Environment Context');
    buffer.writeln('');
    buffer.writeln(_buildEnvironmentContext());
    buffer.writeln('');

    // Next Steps
    buffer.writeln('## 🚀 Recommended Next Steps');
    buffer.writeln('');
    buffer.writeln(_generateNextSteps());
    
    return buffer.toString();
  }

  /// Generate executive summary
  static String _generateExecutiveSummary() {
    final categories = _categorizeFailures();
    final buffer = StringBuffer();
    
    buffer.writeln('**Failure Categories:**');
    categories.forEach((category, count) {
      buffer.writeln('- **$category**: $count failures');
    });
    
    buffer.writeln('');
    buffer.writeln('**Primary Issues:**');
    
    if (categories.containsKey('UI Element Not Found')) {
      buffer.writeln('- Missing UI elements indicate incomplete implementation or incorrect test assumptions');
    }
    if (categories.containsKey('Network/Backend')) {
      buffer.writeln('- Backend connectivity or data issues affecting test execution');
    }
    if (categories.containsKey('Authentication')) {
      buffer.writeln('- User authentication setup or credential issues');
    }
    if (categories.containsKey('Timeout')) {
      buffer.writeln('- Performance issues or slow operations causing test timeouts');
    }
    
    return buffer.toString();
  }

  /// Generate immediate action items
  static String _generateActionItems() {
    final buffer = StringBuffer();
    final categories = _categorizeFailures();
    
    buffer.writeln('### Priority 1 (Critical)');
    
    if (categories.containsKey('Network/Backend')) {
      buffer.writeln('- [ ] **Verify backend server is running** on port 4000');
      buffer.writeln('- [ ] **Check GraphQL endpoint** accessibility at http://localhost:4000/graphql');
      buffer.writeln('- [ ] **Validate test user credentials** exist in database');
    }
    
    if (categories.containsKey('UI Element Not Found')) {
      buffer.writeln('- [ ] **Add missing widget keys** to UI components');
      buffer.writeln('- [ ] **Review widget naming conventions** in failed tests');
      buffer.writeln('- [ ] **Update test selectors** to match actual UI implementation');
    }
    
    buffer.writeln('');
    buffer.writeln('### Priority 2 (Important)');
    
    if (categories.containsKey('Authentication')) {
      buffer.writeln('- [ ] **Create test user** in backend database with email: test@ukcpa');
      buffer.writeln('- [ ] **Verify login mutation** works in GraphQL Playground');
      buffer.writeln('- [ ] **Check session management** configuration');
    }
    
    if (categories.containsKey('Timeout')) {
      buffer.writeln('- [ ] **Optimize slow operations** causing timeouts');
      buffer.writeln('- [ ] **Increase test timeouts** if operations are legitimately slow');
      buffer.writeln('- [ ] **Review performance** of GraphQL queries');
    }
    
    return buffer.toString();
  }

  /// Build detailed analysis for a single failure
  static String _buildFailureAnalysis(TestFailure failure, int index) {
    final buffer = StringBuffer();
    
    buffer.writeln('### Failure #$index: ${failure.testName}');
    buffer.writeln('');
    buffer.writeln('**File:** `${failure.testFile}`');
    buffer.writeln('**Time:** ${failure.timestamp.toIso8601String()}');
    buffer.writeln('**Category:** ${_categorizeFailure(failure)}');
    buffer.writeln('');
    
    // Exception details
    buffer.writeln('**Exception:**');
    buffer.writeln('```');
    buffer.writeln(failure.exception.toString());
    buffer.writeln('```');
    buffer.writeln('');
    
    // Stack trace (first 10 lines)
    buffer.writeln('**Stack Trace (Top 10 lines):**');
    buffer.writeln('```');
    final stackLines = failure.stackTrace.toString().split('\n');
    for (int i = 0; i < stackLines.length && i < 10; i++) {
      buffer.writeln(stackLines[i]);
    }
    if (stackLines.length > 10) {
      buffer.writeln('... (${stackLines.length - 10} more lines)');
    }
    buffer.writeln('```');
    buffer.writeln('');
    
    // Analysis
    buffer.writeln('**Analysis:**');
    buffer.writeln(_analyzeFailure(failure));
    buffer.writeln('');
    
    // Suggested fixes
    buffer.writeln('**Suggested Fixes:**');
    buffer.writeln(_suggestFixes(failure));
    buffer.writeln('');
    
    // Code context if available
    if (failure.additionalContext.isNotEmpty) {
      buffer.writeln('**Additional Context:**');
      failure.additionalContext.forEach((key, value) {
        buffer.writeln('- **$key**: $value');
      });
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  /// Categorize failures for analysis
  static Map<String, int> _categorizeFailures() {
    final categories = <String, int>{};
    
    for (final failure in _failures) {
      final category = _categorizeFailure(failure);
      categories[category] = (categories[category] ?? 0) + 1;
    }
    
    return categories;
  }

  /// Categorize a single failure
  static String _categorizeFailure(TestFailure failure) {
    final exceptionStr = failure.exception.toString().toLowerCase();
    
    if (exceptionStr.contains('found 0 widgets') || exceptionStr.contains('no element found')) {
      return 'UI Element Not Found';
    }
    if (exceptionStr.contains('timeout') || exceptionStr.contains('timed out')) {
      return 'Timeout';
    }
    if (exceptionStr.contains('network') || exceptionStr.contains('connection') || exceptionStr.contains('dio')) {
      return 'Network/Backend';
    }
    if (exceptionStr.contains('auth') || exceptionStr.contains('login') || exceptionStr.contains('credential')) {
      return 'Authentication';
    }
    if (exceptionStr.contains('type') || exceptionStr.contains('cast') || exceptionStr.contains('null')) {
      return 'Type/Null Error';
    }
    
    return 'Other';
  }

  /// Analyze a specific failure
  static String _analyzeFailure(TestFailure failure) {
    final category = _categorizeFailure(failure);
    final exceptionStr = failure.exception.toString();
    
    switch (category) {
      case 'UI Element Not Found':
        if (exceptionStr.contains('Sign in to your account')) {
          return '''
This test is looking for specific text "Sign in to your account" which suggests:
1. The login screen may not be displayed
2. The login screen uses different text
3. The app may be showing a different screen (e.g., already logged in)
4. The UI text may be dynamically generated or localized

The test assumes a specific login flow that may not match the actual implementation.
''';
        }
        if (exceptionStr.contains('email-field') || exceptionStr.contains('password-field')) {
          return '''
This test is looking for form fields with specific keys that don't exist:
1. The form fields may not have the expected Key() widgets
2. The field names may be different (e.g., 'username' instead of 'email')
3. The login form may use different widget types
4. The form may not be rendered yet when the test runs

This is a common issue when tests are written before UI implementation.
''';
        }
        return 'The test cannot find expected UI elements. This usually indicates missing widget keys or different UI implementation than expected.';
        
      case 'Network/Backend':
        if (exceptionStr.contains('400')) {
          return '''
HTTP 400 Bad Request suggests:
1. Invalid GraphQL query or variables
2. Missing required headers (e.g., siteid)
3. Backend validation errors
4. Malformed request data

The test user authentication is failing, which may indicate missing test data.
''';
        }
        return 'Network or backend connectivity issues. The backend may not be running or accessible.';
        
      case 'Authentication':
        return '''
Authentication-related failure suggests:
1. Test user doesn't exist in database
2. Invalid credentials for test user
3. Authentication endpoint not working
4. Session management issues

This is expected in early development when test data isn't set up.
''';
        
      case 'Timeout':
        return 'The operation took too long to complete. This could indicate performance issues or operations that need more time.';
        
      default:
        return 'Unexpected failure that requires manual investigation.';
    }
  }

  /// Suggest fixes for a failure
  static String _suggestFixes(TestFailure failure) {
    final category = _categorizeFailure(failure);
    final buffer = StringBuffer();
    
    switch (category) {
      case 'UI Element Not Found':
        buffer.writeln('1. **Add Widget Keys**: Add `Key(\'email-field\')` to email TextField');
        buffer.writeln('2. **Check Text Content**: Verify actual login screen text matches test expectations');
        buffer.writeln('3. **Update Test Selectors**: Use `find.byType(TextField)` instead of specific keys');
        buffer.writeln('4. **Add Debug Info**: Use `tester.printToConsole()` to see actual widget tree');
        break;
        
      case 'Network/Backend':
        buffer.writeln('1. **Start Backend**: Ensure UKCPA-Server is running: `cd UKCPA-Server && yarn start:dev`');
        buffer.writeln('2. **Check Port**: Verify backend is on port 4000 (not 3000)');
        buffer.writeln('3. **Create Test User**: Add test user to database with email: test@ukcpa');
        buffer.writeln('4. **Verify GraphQL**: Test queries in GraphQL Playground at http://localhost:4000/graphql');
        break;
        
      case 'Authentication':
        buffer.writeln('1. **Create Test User**: Insert user into database with test credentials');
        buffer.writeln('2. **Check Login Mutation**: Verify login GraphQL mutation works');
        buffer.writeln('3. **Update Credentials**: Use valid existing user credentials in test_credentials.dart');
        buffer.writeln('4. **Mock Authentication**: Consider mocking auth for UI-only tests');
        break;
        
      case 'Timeout':
        buffer.writeln('1. **Increase Timeout**: Add longer timeout to test operations');
        buffer.writeln('2. **Optimize Performance**: Improve slow backend operations');
        buffer.writeln('3. **Add Wait Conditions**: Use proper wait conditions instead of fixed delays');
        buffer.writeln('4. **Check Resources**: Ensure sufficient system resources for testing');
        break;
        
      default:
        buffer.writeln('1. **Manual Investigation**: Review exception details and stack trace');
        buffer.writeln('2. **Reproduce Manually**: Try to reproduce the issue manually in the app');
        buffer.writeln('3. **Add Logging**: Add more detailed logging around the failure point');
        buffer.writeln('4. **Simplify Test**: Break complex test into smaller, focused tests');
    }
    
    return buffer.toString();
  }

  /// Generate investigation guide
  static String _generateInvestigationGuide() {
    return '''
### Step-by-Step Investigation Process

#### 1. Environment Verification
```bash
# Check backend status
curl http://localhost:4000/graphql

# Verify Flutter environment
flutter doctor

# Check iOS simulator
xcrun simctl list devices
```

#### 2. Backend Investigation
```bash
# Start backend with logging
cd UKCPA-Server
yarn start:dev

# Test GraphQL queries
# Open http://localhost:4000/graphql in browser
# Try: query { __schema { queryType { name } } }
```

#### 3. Database Investigation
```sql
-- Check if test user exists
SELECT id, email FROM users WHERE email = 'test@ukcpa';

-- Create test user if missing
INSERT INTO users (email, password_hash, first_name, last_name) 
VALUES ('test@ukcpa', '\$2b\$10\$hashed_password', 'Test', 'User');
```

#### 4. UI Investigation
```dart
// Add debug prints to tests
print('Widget tree: \\\${tester.binding.renderViewTree}');

// Find actual widgets
final allTexts = find.byType(Text);
print('All texts found: \\\${allTexts.evaluate().length}');
```

#### 5. Test Isolation
- Run individual tests: `flutter test integration_test/flows/basic_ui_test.dart`
- Use minimal test data
- Mock external dependencies
''';
  }

  /// Analyze patterns across failures
  static String _analyzeFailurePatterns() {
    final buffer = StringBuffer();
    final categories = _categorizeFailures();
    
    if (categories['UI Element Not Found'] != null && categories['UI Element Not Found']! > 2) {
      buffer.writeln('### 🎯 Pattern: Missing UI Elements');
      buffer.writeln('Multiple tests failing due to missing UI elements suggests:');
      buffer.writeln('- Tests were written before UI implementation');
      buffer.writeln('- Systematic missing of widget keys in Flutter components');
      buffer.writeln('- Different UI architecture than expected by tests');
      buffer.writeln('');
      buffer.writeln('**Recommendation**: Focus on adding widget keys to UI components before running more tests.');
      buffer.writeln('');
    }
    
    if (categories['Network/Backend'] != null) {
      buffer.writeln('### 🌐 Pattern: Backend Issues');
      buffer.writeln('Network-related failures indicate:');
      buffer.writeln('- Backend server setup needed');
      buffer.writeln('- Test data initialization required');
      buffer.writeln('- GraphQL schema validation needed');
      buffer.writeln('');
      buffer.writeln('**Recommendation**: Set up complete backend environment before running integration tests.');
      buffer.writeln('');
    }
    
    // Time-based patterns
    final timePattern = _analyzeTimePatterns();
    if (timePattern.isNotEmpty) {
      buffer.writeln('### ⏰ Pattern: Timing Issues');
      buffer.writeln(timePattern);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  /// Analyze timing patterns
  static String _analyzeTimePatterns() {
    final buffer = StringBuffer();
    int timeoutCount = 0;
    
    for (final failure in _failures) {
      if (_categorizeFailure(failure) == 'Timeout') {
        timeoutCount++;
      }
    }
    
    if (timeoutCount > 1) {
      buffer.writeln('Multiple timeout failures suggest:');
      buffer.writeln('- System performance issues');
      buffer.writeln('- Insufficient test timeouts');
      buffer.writeln('- Slow backend operations');
      buffer.writeln('- Resource contention during testing');
    }
    
    return buffer.toString();
  }

  /// Generate resolution suggestions
  static String _generateResolutionSuggestions() {
    final categories = _categorizeFailures();
    final buffer = StringBuffer();
    
    buffer.writeln('### Prioritized Resolution Plan');
    buffer.writeln('');
    
    buffer.writeln('#### Phase 1: Environment Setup');
    buffer.writeln('1. **Backend Setup**: Ensure UKCPA-Server is running correctly');
    buffer.writeln('2. **Database Setup**: Create test users and sample data');
    buffer.writeln('3. **Connectivity**: Verify all network connections work');
    buffer.writeln('');
    
    buffer.writeln('#### Phase 2: UI Implementation');
    buffer.writeln('1. **Widget Keys**: Add missing Key() widgets to UI components');
    buffer.writeln('2. **Text Content**: Align UI text with test expectations');
    buffer.writeln('3. **Form Fields**: Ensure form fields have proper identifiers');
    buffer.writeln('');
    
    buffer.writeln('#### Phase 3: Test Refinement');
    buffer.writeln('1. **Resilient Selectors**: Use more flexible element finding');
    buffer.writeln('2. **Proper Waits**: Add appropriate wait conditions');
    buffer.writeln('3. **Error Handling**: Improve test error handling');
    buffer.writeln('');
    
    buffer.writeln('#### Phase 4: Validation');
    buffer.writeln('1. **Incremental Testing**: Run tests one by one');
    buffer.writeln('2. **End-to-End Validation**: Run complete test suite');
    buffer.writeln('3. **Performance Optimization**: Address any performance issues');
    
    return buffer.toString();
  }

  /// Build environment context
  static String _buildEnvironmentContext() {
    final buffer = StringBuffer();
    
    buffer.writeln('**System Information:**');
    buffer.writeln('- Platform: ${_testContext['platform']}');
    buffer.writeln('- Dart Version: ${_testContext['dart_version']}');
    buffer.writeln('- Test Session Start: ${_testContext['session_start']}');
    buffer.writeln('');
    
    buffer.writeln('**Test Configuration:**');
    buffer.writeln('- Backend URL: http://localhost:4000/graphql');
    buffer.writeln('- Test User: test@ukcpa');
    buffer.writeln('- Device Target: iPhone 16 Pro');
    buffer.writeln('- CI Mode: ${_testContext['ci_mode'] ?? 'false'}');
    buffer.writeln('');
    
    buffer.writeln('**Dependencies:**');
    buffer.writeln('- Backend Server: UKCPA-Server (port 4000)');
    buffer.writeln('- Database: PostgreSQL');
    buffer.writeln('- iOS Simulator: Required for testing');
    
    return buffer.toString();
  }

  /// Generate next steps
  static String _generateNextSteps() {
    return '''
### Immediate Actions (Today)
1. **Review this report** with the development team
2. **Verify backend setup** following environment investigation guide
3. **Start with highest priority fixes** from action items
4. **Run basic UI test** to verify environment: `flutter test integration_test/flows/basic_ui_test.dart`

### Short Term (This Week)
1. **Add missing widget keys** to UI components based on failure analysis
2. **Create test user data** in backend database
3. **Fix identified UI text mismatches**
4. **Re-run individual test files** to validate fixes

### Medium Term (Next Sprint)
1. **Implement comprehensive test data setup** scripts
2. **Add performance monitoring** to identify slow operations
3. **Create automated test environment** setup
4. **Document test troubleshooting** procedures

### Long Term (Future Sprints)
1. **Set up CI/CD pipeline** with automated testing
2. **Implement visual regression testing**
3. **Add performance benchmarking**
4. **Create comprehensive test coverage** reporting

---

**📞 Support:** For questions about this analysis, check the investigation guide or run individual tests for more specific debugging.
''';
  }
}

/// Data class for test failure information
class TestFailure {
  final String testName;
  final String testFile;
  final dynamic exception;
  final StackTrace stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> additionalContext;

  TestFailure({
    required this.testName,
    required this.testFile,
    required this.exception,
    required this.stackTrace,
    required this.timestamp,
    required this.additionalContext,
  });
}