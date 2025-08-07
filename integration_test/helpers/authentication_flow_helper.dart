import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'form_interaction_helper.dart';
import 'navigation_test_helper.dart';
import '../fixtures/test_credentials.dart';

/// Authentication Flow Helper - Complete User Authentication Workflows
/// 
/// This helper solves authentication complexity in integration tests:
/// - Manual login/logout flows repeated across tests
/// - Different user personas and roles
/// - Session management between tests
/// - Authentication state verification
/// - Multiple auth methods (email/password, OAuth)
/// 
/// **Usage Example:**
/// ```dart
/// // Instead of manual login process
/// await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
/// await FormInteractionHelper.fillAndSubmitForm(tester, credentials);
/// // ... complex verification logic
/// 
/// // Use AuthenticationFlowHelper
/// await AuthenticationFlowHelper.loginAs(tester, UserRole.registeredUser);
/// ```
class AuthenticationFlowHelper {
  
  /// Login as a specific user role with automatic credential selection
  /// 
  /// [userRole] - Pre-configured user persona to login as
  /// [customCredentials] - Override default credentials if needed
  /// [verboseLogging] - Enable detailed authentication logging
  static Future<AuthenticationResult> loginAs(
    WidgetTester tester,
    UserRole userRole, {
    UserCredentials? customCredentials,
    Duration loginTimeout = const Duration(seconds: 5),
    bool verboseLogging = false,
  }) async {
    final result = AuthenticationResult();
    
    if (verboseLogging) {
      print('\n🔐 AUTHENTICATION: Logging in as ${userRole.name}');
    }
    
    try {
      // Step 1: Navigate to login page
      await NavigationTestHelper.ensurePageLoaded(
        tester, 
        NavigationTarget.login,
        verboseLogging: verboseLogging,
      );
      
      // Step 2: Get credentials for user role
      final credentials = customCredentials ?? _getCredentialsForRole(userRole);
      
      // Step 3: Perform login
      final loginResult = await FormInteractionHelper.fillAndSubmitForm(
        tester,
        {
          'email-field': credentials.email,
          'password-field': credentials.password,
        },
        submitButtonText: 'Sign In',
        submitWait: loginTimeout,
        verboseLogging: verboseLogging,
      );
      
      // Step 4: Verify login success
      result.formResult = loginResult;
      result.loginSuccess = loginResult.submitSuccess;
      
      if (result.loginSuccess) {
        result.authenticatedUser = AuthenticatedUser(
          role: userRole,
          credentials: credentials,
          loginTime: DateTime.now(),
        );
        
        // Verify we're no longer on login page
        await tester.pump(const Duration(seconds: 1));
        final stillOnLogin = find.text('Sign in to your account').evaluate().isNotEmpty;
        result.loginSuccess = !stillOnLogin;
        
        if (verboseLogging) {
          print('✅ Successfully logged in as ${userRole.name}');
        }
      } else {
        result.error = 'Login failed: ${loginResult.summary}';
        if (verboseLogging) {
          print('❌ Login failed: ${result.error}');
        }
      }
      
    } catch (e) {
      result.error = e.toString();
      result.loginSuccess = false;
      if (verboseLogging) {
        print('❌ Authentication error: $e');
      }
    }
    
    return result;
  }
  
  /// Login with specific credentials (not using predefined roles)
  static Future<AuthenticationResult> loginWithCredentials(
    WidgetTester tester,
    UserCredentials credentials, {
    Duration loginTimeout = const Duration(seconds: 5),
    bool verboseLogging = false,
  }) async {
    return await loginAs(
      tester,
      UserRole.custom,
      customCredentials: credentials,
      loginTimeout: loginTimeout,
      verboseLogging: verboseLogging,
    );
  }
  
  /// Continue as guest (skip authentication)
  static Future<AuthenticationResult> continueAsGuest(
    WidgetTester tester, {
    bool verboseLogging = false,
  }) async {
    final result = AuthenticationResult();
    
    if (verboseLogging) {
      print('\n👤 AUTHENTICATION: Continuing as guest');
    }
    
    try {
      // Navigate to login page first
      await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
      
      // Look for guest/skip options
      final guestOptions = [
        'Continue as Guest',
        'Skip Login',
        'Browse Without Account',
        'Guest Mode',
      ];
      
      bool foundGuestOption = false;
      for (final option in guestOptions) {
        final finder = find.text(option);
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          foundGuestOption = true;
          break;
        }
      }
      
      if (foundGuestOption) {
        result.loginSuccess = true;
        result.authenticatedUser = AuthenticatedUser(
          role: UserRole.guest,
          credentials: UserCredentials.guest(),
          loginTime: DateTime.now(),
        );
        
        if (verboseLogging) {
          print('✅ Successfully continued as guest');
        }
      } else {
        result.error = 'Guest option not found on login screen';
        if (verboseLogging) {
          print('❌ Could not find guest login option');
        }
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Guest authentication error: $e');
      }
    }
    
    return result;
  }
  
  /// Logout current user and return to login screen
  static Future<bool> logout(
    WidgetTester tester, {
    bool verboseLogging = false,
  }) async {
    if (verboseLogging) {
      print('\n🚪 AUTHENTICATION: Logging out');
    }
    
    try {
      // Look for logout options in various locations
      final logoutOptions = [
        'Logout',
        'Log Out', 
        'Sign Out',
        'Exit',
      ];
      
      bool foundLogoutOption = false;
      
      // Check for logout in common locations (menu, profile, etc.)
      for (final option in logoutOptions) {
        final finder = find.text(option);
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          foundLogoutOption = true;
          break;
        }
      }
      
      // If not found directly, look for menu/profile icons
      if (!foundLogoutOption) {
        final menuIcons = [
          find.byIcon(Icons.menu),
          find.byIcon(Icons.person),
          find.byIcon(Icons.account_circle),
        ];
        
        for (final menuIcon in menuIcons) {
          if (menuIcon.evaluate().isNotEmpty) {
            await tester.tap(menuIcon.first);
            await tester.pump(const Duration(milliseconds: 500));
            
            // Now look for logout option again
            for (final option in logoutOptions) {
              final finder = find.text(option);
              if (finder.evaluate().isNotEmpty) {
                await tester.tap(finder.first);
                await tester.pumpAndSettle(const Duration(seconds: 2));
                foundLogoutOption = true;
                break;
              }
            }
            
            if (foundLogoutOption) break;
          }
        }
      }
      
      if (foundLogoutOption) {
        // Verify we're back on login screen
        await tester.pump(const Duration(seconds: 1));
        final onLoginScreen = find.text('Sign in to your account').evaluate().isNotEmpty;
        
        if (verboseLogging) {
          print(onLoginScreen ? '✅ Successfully logged out' : '⚠️  Logout initiated but not on login screen');
        }
        
        return onLoginScreen;
      } else {
        if (verboseLogging) {
          print('❌ Could not find logout option');
        }
        return false;
      }
      
    } catch (e) {
      if (verboseLogging) {
        print('❌ Logout error: $e');
      }
      return false;
    }
  }
  
  /// Register a new user account
  static Future<AuthenticationResult> registerUser(
    WidgetTester tester,
    UserCredentials credentials, {
    Duration registrationTimeout = const Duration(seconds: 8),
    bool verboseLogging = false,
  }) async {
    final result = AuthenticationResult();
    
    if (verboseLogging) {
      print('\n📝 AUTHENTICATION: Registering new user ${credentials.email}');
    }
    
    try {
      // Step 1: Navigate to login page first
      await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
      
      // Step 2: Look for registration link
      final registrationLinks = [
        'Sign Up',
        'Create Account', 
        'Register',
        'New User?',
      ];
      
      bool foundRegistrationLink = false;
      for (final link in registrationLinks) {
        final finder = find.textContaining(link);
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          foundRegistrationLink = true;
          break;
        }
      }
      
      if (!foundRegistrationLink) {
        result.error = 'Could not find registration link on login page';
        return result;
      }
      
      // Step 3: Fill registration form
      final registrationData = <String, dynamic>{
        'first-name-field': credentials.firstName,
        'last-name-field': credentials.lastName,
        'email-field': credentials.email,
        'password-field': credentials.password,
      };
      
      // Add confirm password if field exists
      if (find.byKey(const Key('confirm-password-field')).evaluate().isNotEmpty) {
        registrationData['confirm-password-field'] = credentials.password;
      }
      
      // Add terms checkbox if exists
      if (find.byKey(const Key('terms-checkbox')).evaluate().isNotEmpty) {
        registrationData['terms-checkbox'] = true;
      }
      
      final registrationResult = await FormInteractionHelper.fillAndSubmitForm(
        tester,
        registrationData,
        submitButtonText: 'Create Account',
        submitWait: registrationTimeout,
        verboseLogging: verboseLogging,
      );
      
      result.formResult = registrationResult;
      result.loginSuccess = registrationResult.submitSuccess;
      
      if (result.loginSuccess) {
        result.authenticatedUser = AuthenticatedUser(
          role: UserRole.registeredUser,
          credentials: credentials,
          loginTime: DateTime.now(),
        );
        
        if (verboseLogging) {
          print('✅ Successfully registered user ${credentials.email}');
        }
      } else {
        result.error = 'Registration failed: ${registrationResult.summary}';
        if (verboseLogging) {
          print('❌ Registration failed: ${result.error}');
        }
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Registration error: $e');
      }
    }
    
    return result;
  }
  
  /// Verify current authentication state
  static Future<AuthenticationState> getCurrentAuthState(
    WidgetTester tester, {
    bool verboseLogging = false,
  }) async {
    if (verboseLogging) {
      print('\n🔍 AUTHENTICATION: Checking current auth state');
    }
    
    // Check if we're on login screen (not authenticated)
    if (find.text('Sign in to your account').evaluate().isNotEmpty) {
      return AuthenticationState.notAuthenticated;
    }
    
    // Look for authenticated user indicators
    final authIndicators = [
      find.text('Welcome'),
      find.text('My Account'),
      find.text('Profile'),
      find.text('Dashboard'),
      find.text('Browse Courses'),
      find.byIcon(Icons.account_circle),
    ];
    
    for (final indicator in authIndicators) {
      if (indicator.evaluate().isNotEmpty) {
        return AuthenticationState.authenticated;
      }
    }
    
    // Look for guest indicators
    final guestIndicators = [
      find.text('Guest'),
      find.text('Sign In'),
      find.text('Create Account'),
    ];
    
    for (final indicator in guestIndicators) {
      if (indicator.evaluate().isNotEmpty) {
        return AuthenticationState.guest;
      }
    }
    
    return AuthenticationState.unknown;
  }
  
  /// Reset authentication state (logout if needed)
  static Future<void> resetAuthState(
    WidgetTester tester, {
    bool verboseLogging = false,
  }) async {
    final currentState = await getCurrentAuthState(tester);
    
    if (currentState == AuthenticationState.authenticated) {
      await logout(tester, verboseLogging: verboseLogging);
    }
    
    // Ensure we're on login page
    await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.login);
  }
  
  /// Multi-factor authentication handling (placeholder for future implementation)
  static Future<bool> handleMFA(
    WidgetTester tester,
    String mfaCode, {
    bool verboseLogging = false,
  }) async {
    if (verboseLogging) {
      print('\n🔐 AUTHENTICATION: Handling MFA with code');
    }
    
    // Look for MFA code input
    final mfaFinder = find.byKey(const Key('mfa-code-field'));
    if (mfaFinder.evaluate().isNotEmpty) {
      await FormInteractionHelper.fillAndSubmitForm(
        tester,
        {'mfa-code-field': mfaCode},
        submitButtonText: 'Verify',
      );
      return true;
    }
    
    return false;
  }
  
  // ========== PRIVATE HELPER METHODS ==========
  
  /// Get predefined credentials for user role
  static UserCredentials _getCredentialsForRole(UserRole role) {
    switch (role) {
      case UserRole.guest:
        return UserCredentials.guest();
      case UserRole.registeredUser:
        return UserCredentials(
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
          firstName: TestCredentials.validFirstName,
          lastName: TestCredentials.validLastName,
        );
      case UserRole.alternateUser:
        return UserCredentials(
          email: TestCredentials.altEmail,
          password: TestCredentials.altPassword,
          firstName: 'Alt',
          lastName: 'User',
        );
      case UserRole.adminUser:
        return UserCredentials(
          email: 'admin@ukcpa.com',
          password: 'admin123',
          firstName: 'Admin',
          lastName: 'User',
        );
      case UserRole.invalidUser:
        return UserCredentials(
          email: TestCredentials.invalidEmail,
          password: TestCredentials.invalidPassword,
          firstName: 'Invalid',
          lastName: 'User',
        );
      case UserRole.custom:
        throw ArgumentError('Custom role requires customCredentials parameter');
    }
  }
}

/// Available user roles for authentication
enum UserRole {
  guest,
  registeredUser,
  alternateUser,
  adminUser,
  invalidUser,
  custom,
}

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.guest:
        return 'Guest';
      case UserRole.registeredUser:
        return 'Registered User';
      case UserRole.alternateUser:
        return 'Alternate User';
      case UserRole.adminUser:
        return 'Admin User';
      case UserRole.invalidUser:
        return 'Invalid User';
      case UserRole.custom:
        return 'Custom User';
    }
  }
}

/// Current authentication state
enum AuthenticationState {
  notAuthenticated,
  authenticated,
  guest,
  unknown,
}

/// User credentials for authentication
class UserCredentials {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phone;
  
  const UserCredentials({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phone,
  });
  
  factory UserCredentials.guest() {
    return const UserCredentials(
      email: '',
      password: '',
      firstName: 'Guest',
      lastName: 'User',
    );
  }
  
  @override
  String toString() => '$firstName $lastName ($email)';
}

/// Authenticated user information
class AuthenticatedUser {
  final UserRole role;
  final UserCredentials credentials;
  final DateTime loginTime;
  
  const AuthenticatedUser({
    required this.role,
    required this.credentials,
    required this.loginTime,
  });
  
  bool get isGuest => role == UserRole.guest;
  bool get isAdmin => role == UserRole.adminUser;
  Duration get sessionDuration => DateTime.now().difference(loginTime);
  
  @override
  String toString() => '${role.name}: ${credentials.toString()}';
}

/// Result of authentication operations
class AuthenticationResult {
  bool loginSuccess = false;
  String? error;
  AuthenticatedUser? authenticatedUser;
  FormInteractionResult? formResult;
  
  bool get hasError => error != null;
  bool get isAuthenticated => loginSuccess && authenticatedUser != null;
  
  String get summary {
    if (hasError) {
      return 'Authentication failed: $error';
    } else if (isAuthenticated) {
      return 'Successfully authenticated as ${authenticatedUser!.role.name}';
    } else {
      return 'Authentication pending';
    }
  }
}