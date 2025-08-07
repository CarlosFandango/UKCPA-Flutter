# Authentication Flow Helper Guide

## 🎯 **Problem Solved**

**Issue**: Authentication workflows in integration tests require complex, repetitive code with manual navigation, form filling, session management, and state verification across different user types and scenarios.

**Solution**: The `AuthenticationFlowHelper` provides complete authentication workflows with predefined user personas, automatic session management, and comprehensive state verification.

## 🚀 **Quick Start**

### Basic User Authentication

```dart
import '../helpers/authentication_flow_helper.dart';

testWidgets('Course booking as registered user', (tester) async {
  // Instead of manual login process
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  await FormInteractionHelper.fillAndSubmitForm(tester, {
    'email-field': TestCredentials.validEmail,
    'password-field': TestCredentials.validPassword,
  }, submitButtonText: 'Sign In');
  // ... complex verification logic
  
  // Use AuthenticationFlowHelper
  final authResult = await AuthenticationFlowHelper.loginAs(
    tester, 
    UserRole.registeredUser,
  );
  
  expect(authResult.loginSuccess, isTrue);
  expect(authResult.authenticatedUser?.role, UserRole.registeredUser);
});
```

### Multi-User Testing

```dart
group('User role testing', () {
  testWidgets('Admin user functionality', (tester) async {
    final authResult = await AuthenticationFlowHelper.loginAs(
      tester, 
      UserRole.adminUser,
      verboseLogging: true,
    );
    
    expect(authResult.loginSuccess, isTrue);
    expect(authResult.authenticatedUser?.isAdmin, isTrue);
    
    // Test admin-specific functionality
    expect(find.text('Admin Panel'), findsOneWidget);
  });
  
  testWidgets('Guest user limitations', (tester) async {
    final authResult = await AuthenticationFlowHelper.continueAsGuest(tester);
    
    expect(authResult.loginSuccess, isTrue);
    expect(authResult.authenticatedUser?.isGuest, isTrue);
    
    // Verify guest limitations
    expect(find.text('Sign In to Book'), findsWidgets);
  });
});
```

## 👥 **User Roles & Personas**

The helper provides predefined user personas with appropriate credentials and permissions:

### Available User Roles

| Role | Description | Use Case | Credentials |
|------|-------------|----------|-------------|
| `UserRole.registeredUser` | Standard registered user | Course booking, profile management | TestCredentials.validEmail/Password |
| `UserRole.alternateUser` | Second registered user | Multi-user scenarios | TestCredentials.altEmail/Password |
| `UserRole.adminUser` | Administrative user | Admin functionality testing | admin@ukcpa.com/admin123 |
| `UserRole.guest` | Guest/anonymous user | Unauthenticated browsing | No credentials |
| `UserRole.invalidUser` | Invalid credentials | Error scenario testing | TestCredentials.invalidEmail/Password |
| `UserRole.custom` | Custom credentials | Specific test scenarios | Provided via customCredentials |

### User Role Examples

```dart
// Standard user login
final authResult = await AuthenticationFlowHelper.loginAs(
  tester, 
  UserRole.registeredUser,
);

// Admin user for administrative tests
final adminResult = await AuthenticationFlowHelper.loginAs(
  tester,
  UserRole.adminUser,
  verboseLogging: true,
);

// Guest user for public functionality
final guestResult = await AuthenticationFlowHelper.continueAsGuest(tester);

// Custom credentials for specific scenarios
final customResult = await AuthenticationFlowHelper.loginAs(
  tester,
  UserRole.custom,
  customCredentials: UserCredentials(
    email: 'specific@test.com',
    password: 'specificPassword',
    firstName: 'Test',
    lastName: 'User',
  ),
);
```

## 🔧 **Core Methods**

### loginAs()

**Primary authentication method** with role-based credential selection:

```dart
Future<AuthenticationResult> loginAs(
  WidgetTester tester,
  UserRole userRole, {
  UserCredentials? customCredentials,    // Override default credentials
  Duration loginTimeout = const Duration(seconds: 5),
  bool verboseLogging = false,           // Detailed authentication logging
});
```

**Usage Examples:**

```dart
// Basic login
final result = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);

// With custom timeout and logging
final result = await AuthenticationFlowHelper.loginAs(
  tester,
  UserRole.adminUser,
  loginTimeout: Duration(seconds: 10),
  verboseLogging: true,
);

// With custom credentials
final result = await AuthenticationFlowHelper.loginAs(
  tester,
  UserRole.custom,
  customCredentials: UserCredentials(
    email: 'custom@example.com',
    password: 'customPass123',
    firstName: 'Custom',
    lastName: 'User',
  ),
);
```

### loginWithCredentials()

**Direct credential login** without using predefined roles:

```dart
final credentials = UserCredentials(
  email: 'direct@example.com',
  password: 'directPassword',
  firstName: 'Direct',
  lastName: 'User',
);

final result = await AuthenticationFlowHelper.loginWithCredentials(
  tester,
  credentials,
  verboseLogging: true,
);
```

### continueAsGuest()

**Guest access** for unauthenticated functionality testing:

```dart
final result = await AuthenticationFlowHelper.continueAsGuest(
  tester,
  verboseLogging: true,
);

expect(result.authenticatedUser?.isGuest, isTrue);

// Test guest limitations
expect(find.text('Sign In to Continue'), findsWidgets);
```

### logout()

**User logout** with automatic verification:

```dart
final loggedOut = await AuthenticationFlowHelper.logout(
  tester,
  verboseLogging: true,
);

expect(loggedOut, isTrue);
expect(find.text('Sign in to your account'), findsOneWidget);
```

### registerUser()

**User registration** with comprehensive form handling:

```dart
final newUser = UserCredentials(
  email: 'newuser@example.com',
  password: 'SecurePass123!',
  firstName: 'New',
  lastName: 'User',
);

final result = await AuthenticationFlowHelper.registerUser(
  tester,
  newUser,
  registrationTimeout: Duration(seconds: 10),
  verboseLogging: true,
);

expect(result.loginSuccess, isTrue);
expect(result.authenticatedUser?.credentials.email, 'newuser@example.com');
```

## 🔍 **Authentication State Management**

### getCurrentAuthState()

**Check current authentication status**:

```dart
final state = await AuthenticationFlowHelper.getCurrentAuthState(
  tester,
  verboseLogging: true,
);

switch (state) {
  case AuthenticationState.notAuthenticated:
    print('User is not logged in');
    break;
  case AuthenticationState.authenticated:
    print('User is logged in');
    break;
  case AuthenticationState.guest:
    print('User is browsing as guest');
    break;
  case AuthenticationState.unknown:
    print('Cannot determine auth state');
    break;
}
```

### resetAuthState()

**Clean authentication state** between tests:

```dart
testWidgets('Clean slate test', (tester) async {
  // Ensure clean authentication state
  await AuthenticationFlowHelper.resetAuthState(tester);
  
  // Now proceed with test that requires unauthenticated state
  final result = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
});
```

## 📊 **Result Objects**

### AuthenticationResult

Complete authentication operation result:

```dart
class AuthenticationResult {
  bool loginSuccess;                    // Authentication succeeded
  String? error;                       // Error message if failed
  AuthenticatedUser? authenticatedUser; // User info if successful
  FormInteractionResult? formResult;    // Underlying form interaction result
  
  bool get hasError;                   // Any errors occurred
  bool get isAuthenticated;            // Successfully authenticated
  String get summary;                  // Human-readable summary
}
```

**Usage:**
```dart
final result = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);

if (result.hasError) {
  print('Authentication failed: ${result.error}');
  print('Form errors: ${result.formResult?.validationErrors}');
} else {
  print('Success: ${result.summary}');
  print('User: ${result.authenticatedUser}');
  print('Session duration: ${result.authenticatedUser?.sessionDuration}');
}
```

### AuthenticatedUser

Information about the authenticated user:

```dart
class AuthenticatedUser {
  final UserRole role;                 // User role
  final UserCredentials credentials;   // Login credentials
  final DateTime loginTime;            // When user logged in
  
  bool get isGuest;                    // Is guest user
  bool get isAdmin;                    // Is admin user  
  Duration get sessionDuration;        // Time since login
}
```

### UserCredentials

User credential information:

```dart
class UserCredentials {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
}
```

## 🎯 **Common Patterns**

### Test Setup with Authentication

```dart
group('Authenticated user tests', () {
  late AuthenticationResult authResult;
  
  setUpAll(() async {
    // Setup runs once for all tests in group
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await binding.defaultTestTimeout.timeout(() async {
      final tester = WidgetTester(binding);
      authResult = await AuthenticationFlowHelper.loginAs(
        tester, 
        UserRole.registeredUser,
      );
    });
  });
  
  testWidgets('User profile test', (tester) async {
    expect(authResult.loginSuccess, isTrue);
    // Test user profile functionality
  });
  
  testWidgets('Course booking test', (tester) async {
    expect(authResult.loginSuccess, isTrue);
    // Test course booking functionality
  });
});
```

### Multi-User Scenario Testing

```dart
testWidgets('Multi-user booking conflict', (tester) async {
  // User 1 starts booking
  final user1Result = await AuthenticationFlowHelper.loginAs(
    tester, 
    UserRole.registeredUser,
  );
  
  // Start booking process
  await tester.tap(find.text('Book Course'));
  await tester.pumpAndSettle();
  
  // Switch to User 2
  await AuthenticationFlowHelper.logout(tester);
  final user2Result = await AuthenticationFlowHelper.loginAs(
    tester,
    UserRole.alternateUser,
  );
  
  // Try to book same course
  await tester.tap(find.text('Book Course'));
  
  // Verify conflict handling
  expect(find.text('Course no longer available'), findsOneWidget);
});
```

### Role-Based Feature Testing

```dart
group('Role-based feature access', () {
  final testCases = [
    (UserRole.guest, false, 'Guest should not see admin features'),
    (UserRole.registeredUser, false, 'Regular user should not see admin features'), 
    (UserRole.adminUser, true, 'Admin should see admin features'),
  ];
  
  for (final testCase in testCases) {
    final (role, shouldSeeFeatures, description) = testCase;
    
    testWidgets(description, (tester) async {
      final result = role == UserRole.guest
        ? await AuthenticationFlowHelper.continueAsGuest(tester)
        : await AuthenticationFlowHelper.loginAs(tester, role);
      
      expect(result.loginSuccess, isTrue);
      
      final adminFeatures = find.text('Admin Panel');
      if (shouldSeeFeatures) {
        expect(adminFeatures, findsOneWidget);
      } else {
        expect(adminFeatures, findsNothing);
      }
    });
  }
});
```

### Session Management Testing

```dart
testWidgets('Session timeout handling', (tester) async {
  final result = await AuthenticationFlowHelper.loginAs(
    tester, 
    UserRole.registeredUser,
  );
  
  expect(result.loginSuccess, isTrue);
  
  // Simulate session timeout
  await tester.binding.defaultTestTimeout.timeout(
    () => Future.delayed(Duration(minutes: 30)), // Simulate time passing
  );
  
  // Try to access protected resource
  await tester.tap(find.text('My Account'));
  await tester.pumpAndSettle();
  
  // Should be redirected to login
  final authState = await AuthenticationFlowHelper.getCurrentAuthState(tester);
  expect(authState, AuthenticationState.notAuthenticated);
});
```

## ⚠️ **Error Scenario Testing**

### Invalid Credentials

```dart
testWidgets('Invalid login credentials', (tester) async {
  final result = await AuthenticationFlowHelper.loginAs(
    tester,
    UserRole.invalidUser,
    verboseLogging: true,
  );
  
  expect(result.loginSuccess, isFalse);
  expect(result.hasError, isTrue);
  expect(result.error, contains('Login failed'));
  
  // Should still be on login screen
  final authState = await AuthenticationFlowHelper.getCurrentAuthState(tester);
  expect(authState, AuthenticationState.notAuthenticated);
});
```

### Network Errors During Authentication

```dart
testWidgets('Network error during login', (tester) async {
  // Simulate network error (implementation depends on mock setup)
  // ...
  
  final result = await AuthenticationFlowHelper.loginAs(
    tester,
    UserRole.registeredUser,
    loginTimeout: Duration(seconds: 10),
  );
  
  if (result.hasError) {
    expect(result.error, contains('network'));
  }
});
```

### Account Lockout Scenarios

```dart
testWidgets('Account lockout after failed attempts', (tester) async {
  // Multiple failed login attempts
  for (int i = 0; i < 5; i++) {
    final result = await AuthenticationFlowHelper.loginAs(
      tester,
      UserRole.invalidUser,
    );
    expect(result.loginSuccess, isFalse);
    
    await AuthenticationFlowHelper.resetAuthState(tester);
  }
  
  // Try with valid credentials - should be locked
  final validResult = await AuthenticationFlowHelper.loginAs(
    tester,
    UserRole.registeredUser,
  );
  
  expect(validResult.loginSuccess, isFalse);
  expect(validResult.error, contains('locked'));
});
```

## 🔐 **Security Testing**

### Password Validation

```dart
testWidgets('Password strength validation', (tester) async {
  final weakCredentials = UserCredentials(
    email: 'test@example.com',
    password: '123',           // Weak password
    firstName: 'Test',
    lastName: 'User',
  );
  
  final result = await AuthenticationFlowHelper.registerUser(
    tester,
    weakCredentials,
  );
  
  expect(result.loginSuccess, isFalse);
  expect(result.formResult?.validationErrors, 
    contains('Password must be at least 8 characters'));
});
```

### Email Format Validation

```dart
testWidgets('Email validation', (tester) async {
  final invalidEmailCredentials = UserCredentials(
    email: 'invalid-email',    // Invalid format
    password: 'ValidPass123!',
    firstName: 'Test',
    lastName: 'User',
  );
  
  final result = await AuthenticationFlowHelper.loginWithCredentials(
    tester,
    invalidEmailCredentials,
  );
  
  expect(result.loginSuccess, isFalse);
  expect(result.formResult?.validationErrors,
    contains('Enter a valid email'));
});
```

## 🐛 **Troubleshooting**

### Authentication Not Working

```dart
// Enable verbose logging to debug
final result = await AuthenticationFlowHelper.loginAs(
  tester,
  UserRole.registeredUser,
  verboseLogging: true,  // Shows detailed auth process
);

if (result.hasError) {
  print('Auth error: ${result.error}');
  print('Form result: ${result.formResult?.summary}');
  print('Validation errors: ${result.formResult?.validationErrors}');
}
```

**Common Issues:**
- **Field not found**: Check field key names match UI implementation
- **Timeout on login**: Increase `loginTimeout` duration
- **Navigation issues**: Ensure NavigationTestHelper works correctly
- **Credentials mismatch**: Verify test credentials match actual test users

### State Detection Issues

```dart
// Debug authentication state detection
final state = await AuthenticationFlowHelper.getCurrentAuthState(
  tester,
  verboseLogging: true,
);
print('Current auth state: $state');

// Check what UI elements are visible
print('Login screen present: ${find.text('Sign in to your account').evaluate().isNotEmpty}');
print('Auth indicators present: ${find.text('Welcome').evaluate().isNotEmpty}');
```

## 🎯 **Best Practices**

### 1. Use Role-Based Testing

```dart
// ✅ GOOD - Use predefined roles for consistency
await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);

// ❌ AVOID - Manual credential management
await FormInteractionHelper.fillAndSubmitForm(tester, {
  'email-field': 'some@email.com',
  'password-field': 'somepassword',
});
```

### 2. Clean State Between Tests

```dart
// ✅ GOOD - Reset auth state between tests
testWidgets('Clean test', (tester) async {
  await AuthenticationFlowHelper.resetAuthState(tester);
  // Test with clean state
});

// ❌ AVOID - Assuming clean state
testWidgets('Assumes logged out', (tester) async {
  // May fail if previous test left user logged in
});
```

### 3. Verify Authentication Results

```dart
// ✅ GOOD - Check authentication result
final result = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
expect(result.loginSuccess, isTrue);
expect(result.authenticatedUser?.role, UserRole.registeredUser);

// ❌ AVOID - Assuming authentication worked
await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
// Continue without verification
```

### 4. Use Appropriate Timeouts

```dart
// ✅ GOOD - Adjust timeouts for network conditions
await AuthenticationFlowHelper.loginAs(
  tester,
  UserRole.registeredUser,
  loginTimeout: Duration(seconds: 10), // Longer for slow networks
);

// ❌ AVOID - Using default timeout for slow operations
await AuthenticationFlowHelper.registerUser(tester, credentials);
// May timeout on slow registration process
```

### 5. Test Error Scenarios

```dart
// ✅ GOOD - Test both success and failure cases
group('Authentication testing', () {
  testWidgets('Successful login', (tester) async {
    final result = await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
    expect(result.loginSuccess, isTrue);
  });
  
  testWidgets('Failed login', (tester) async {
    final result = await AuthenticationFlowHelper.loginAs(tester, UserRole.invalidUser);
    expect(result.loginSuccess, isFalse);
  });
});
```

## ✅ **Migration from Manual Authentication**

### Before (Manual Approach)
```dart
testWidgets('Manual authentication', (tester) async {
  // Navigate to login
  await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  
  // Fill credentials
  await tester.enterText(find.byKey(Key('email-field')), TestCredentials.validEmail);
  await tester.enterText(find.byKey(Key('password-field')), TestCredentials.validPassword);
  
  // Submit
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(Duration(seconds: 3));
  
  // Verify login
  expect(find.text('Sign in to your account'), findsNothing);
  
  // Later in test - logout
  await tester.tap(find.text('Logout'));
  await tester.pumpAndSettle(Duration(seconds: 2));
});
```

### After (Using AuthenticationFlowHelper)
```dart
testWidgets('Helper-based authentication', (tester) async {
  // Login
  final result = await AuthenticationFlowHelper.loginAs(
    tester, 
    UserRole.registeredUser,
  );
  
  expect(result.loginSuccess, isTrue);
  expect(result.authenticatedUser?.role, UserRole.registeredUser);
  
  // Later in test - logout
  final loggedOut = await AuthenticationFlowHelper.logout(tester);
  expect(loggedOut, isTrue);
});
```

**Benefits:**
- **80% less code** per authentication scenario
- **Consistent error handling** across all auth tests
- **Predefined user personas** for different test scenarios
- **Automatic session management** and state verification
- **Comprehensive result objects** with detailed information

The AuthenticationFlowHelper eliminates repetitive authentication code and provides reliable, consistent user authentication workflows across all integration tests.