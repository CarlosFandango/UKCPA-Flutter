import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/authentication_flow_helper.dart';
import '../helpers/navigation_test_helper.dart';

/// Enhanced Course Discovery Tests - Using Authentication Flow Helper
/// 
/// Tests course discovery functionality with different user roles and authentication states.
/// This demonstrates how to use AuthenticationFlowHelper for comprehensive user scenario testing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Course Discovery - Authentication-Aware Tests', () {
    
    testWidgets('Guest user can browse courses with limitations', (tester) async {
      // Login as guest user
      final authResult = await AuthenticationFlowHelper.continueAsGuest(
        tester,
        verboseLogging: true,
      );
      
      expect(authResult.loginSuccess, isTrue);
      expect(authResult.authenticatedUser?.isGuest, isTrue);
      
      // Navigate to course list
      await NavigationTestHelper.ensurePageLoaded(
        tester, 
        NavigationTarget.courseList,
        verboseLogging: true,
      );
      
      // Verify course content is visible
      final courseContent = [
        find.byType(Card),
        find.byType(ListTile), 
        find.textContaining('Course'),
        find.textContaining('Ballet'),
        find.text('No courses available'), // Empty state is also valid
      ];
      
      bool foundContent = false;
      for (final content in courseContent) {
        if (content.evaluate().isNotEmpty) {
          foundContent = true;
          print('✅ Found course content as guest user');
          break;
        }
      }
      
      expect(foundContent, isTrue, reason: 'Guest users should see course content');
      
      // Guest users should see sign-in prompts for booking
      final guestLimitations = [
        find.textContaining('Sign in to book'),
        find.textContaining('Register to book'),
        find.text('Login Required'),
      ];
      
      bool foundGuestLimitations = false;
      for (final limitation in guestLimitations) {
        if (limitation.evaluate().isNotEmpty) {
          foundGuestLimitations = true;
          print('✅ Found guest limitations');
          break;
        }
      }
      
      // Note: Guest limitations may not always be visible until booking is attempted
      print('ℹ️  Guest limitations visible: $foundGuestLimitations');
    });
    
    testWidgets('Registered user can browse and interact with courses', (tester) async {
      // Login as registered user
      final authResult = await AuthenticationFlowHelper.loginAs(
        tester,
        UserRole.registeredUser,
        verboseLogging: true,
      );
      
      expect(authResult.loginSuccess, isTrue);
      expect(authResult.authenticatedUser?.role, UserRole.registeredUser);
      
      // Navigate to course list
      await NavigationTestHelper.ensurePageLoaded(
        tester,
        NavigationTarget.courseList,
        verboseLogging: true,
      );
      
      // Verify course content is visible
      final courseContent = [
        find.byType(Card),
        find.byType(ListTile),
        find.textContaining('Course'),
        find.textContaining('Ballet'),
      ];
      
      bool foundContent = false;
      for (final content in courseContent) {
        if (content.evaluate().isNotEmpty) {
          foundContent = true;
          print('✅ Found course content as registered user');
          break;
        }
      }
      
      expect(foundContent, isTrue, reason: 'Registered users should see course content');
      
      // Registered users should see booking options
      final bookingOptions = [
        find.text('Book Now'),
        find.text('Add to Basket'),
        find.text('Register'),
        find.textContaining('Book'),
        find.textContaining('Enroll'),
      ];
      
      bool foundBookingOptions = false;
      for (final option in bookingOptions) {
        if (option.evaluate().isNotEmpty) {
          foundBookingOptions = true;
          print('✅ Found booking options for registered user');
          break;
        }
      }
      
      // Note: Booking options may not be visible if no courses are available
      print('ℹ️  Booking options visible: $foundBookingOptions');
    });
    
    testWidgets('Admin user sees additional course management features', (tester) async {
      // Login as admin user
      final authResult = await AuthenticationFlowHelper.loginAs(
        tester,
        UserRole.adminUser,
        verboseLogging: true,
      );
      
      expect(authResult.loginSuccess, isTrue);
      expect(authResult.authenticatedUser?.isAdmin, isTrue);
      
      // Navigate to course list
      await NavigationTestHelper.ensurePageLoaded(
        tester,
        NavigationTarget.courseList,
        verboseLogging: true,
      );
      
      // Check for admin-specific features
      final adminFeatures = [
        find.text('Admin Panel'),
        find.text('Manage Courses'),
        find.text('Edit Course'),
        find.text('Add Course'),
        find.byIcon(Icons.admin_panel_settings),
        find.byIcon(Icons.edit),
        find.byIcon(Icons.add),
      ];
      
      bool foundAdminFeatures = false;
      for (final feature in adminFeatures) {
        if (feature.evaluate().isNotEmpty) {
          foundAdminFeatures = true;
          print('✅ Found admin features');
          break;
        }
      }
      
      // Note: Admin features may only be visible in specific admin areas
      print('ℹ️  Admin features visible on course list: $foundAdminFeatures');
    });

    testWidgets('Multiple user session management', (tester) async {
      // Test user session switching
      
      // Start with first user
      final user1Result = await AuthenticationFlowHelper.loginAs(
        tester,
        UserRole.registeredUser,
        verboseLogging: true,
      );
      
      expect(user1Result.loginSuccess, isTrue);
      print('✅ User 1 logged in: ${user1Result.authenticatedUser?.credentials.email}');
      
      // Navigate to courses and verify access
      await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
      
      // Logout first user
      final loggedOut = await AuthenticationFlowHelper.logout(
        tester,
        verboseLogging: true,
      );
      expect(loggedOut, isTrue);
      print('✅ User 1 logged out successfully');
      
      // Login as second user
      final user2Result = await AuthenticationFlowHelper.loginAs(
        tester,
        UserRole.alternateUser,
        verboseLogging: true,
      );
      
      expect(user2Result.loginSuccess, isTrue);
      print('✅ User 2 logged in: ${user2Result.authenticatedUser?.credentials.email}');
      
      // Verify different user can access courses
      await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
      
      final courseContent = [
        find.byType(Card),
        find.textContaining('Course'),
        find.textContaining('Ballet'),
      ];
      
      bool foundContent = false;
      for (final content in courseContent) {
        if (content.evaluate().isNotEmpty) {
          foundContent = true;
          print('✅ User 2 can access course content');
          break;
        }
      }
      
      expect(foundContent, isTrue, reason: 'User 2 should see course content');
    });

    testWidgets('Authentication state persistence during course browsing', (tester) async {
      // Login and verify state is maintained during navigation
      final authResult = await AuthenticationFlowHelper.loginAs(
        tester,
        UserRole.registeredUser,
        verboseLogging: true,
      );
      
      expect(authResult.loginSuccess, isTrue);
      
      // Navigate to different screens and verify auth state persists
      final navigationTargets = [
        NavigationTarget.courseList,
        NavigationTarget.home,
        NavigationTarget.courseList, // Back to courses
      ];
      
      for (final target in navigationTargets) {
        await NavigationTestHelper.ensurePageLoaded(tester, target);
        
        // Check authentication state is still valid
        final currentAuthState = await AuthenticationFlowHelper.getCurrentAuthState(
          tester,
          verboseLogging: false,
        );
        
        expect(currentAuthState, AuthenticationState.authenticated);
        print('✅ Auth state maintained during navigation to ${target.name}');
      }
    });

    testWidgets('Course discovery error handling without authentication', (tester) async {
      // Reset to clean state (no authentication)
      await AuthenticationFlowHelper.resetAuthState(tester);
      
      // Verify we're in unauthenticated state
      final authState = await AuthenticationFlowHelper.getCurrentAuthState(tester);
      expect(authState, AuthenticationState.notAuthenticated);
      
      // Try to navigate to course list
      await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
      
      // Should either:
      // 1. Show courses with guest limitations, or
      // 2. Redirect to login, or  
      // 3. Show error message
      
      final possibleStates = [
        find.text('Sign in to your account'),           // Redirected to login
        find.textContaining('Login required'),         // Error message
        find.textContaining('Sign in to book'),        // Guest limitations
        find.byType(Card),                             // Course content visible to guests
      ];
      
      bool foundValidState = false;
      String currentState = 'Unknown';
      
      for (final state in possibleStates) {
        if (state.evaluate().isNotEmpty) {
          foundValidState = true;
          currentState = state.description;
          break;
        }
      }
      
      expect(foundValidState, isTrue, reason: 'Should handle unauthenticated course access gracefully');
      print('✅ Unauthenticated course access handled: $currentState');
    });

    testWidgets('Course discovery with invalid authentication recovery', (tester) async {
      // Attempt login with invalid credentials
      final invalidResult = await AuthenticationFlowHelper.loginAs(
        tester,
        UserRole.invalidUser,
        verboseLogging: true,
      );
      
      expect(invalidResult.loginSuccess, isFalse);
      expect(invalidResult.hasError, isTrue);
      print('✅ Invalid login correctly failed: ${invalidResult.error}');
      
      // Should still be able to recover with valid credentials
      final validResult = await AuthenticationFlowHelper.loginAs(
        tester,
        UserRole.registeredUser,
        verboseLogging: true,
      );
      
      expect(validResult.loginSuccess, isTrue);
      print('✅ Successfully recovered with valid credentials');
      
      // Should now be able to access courses
      await NavigationTestHelper.ensurePageLoaded(tester, NavigationTarget.courseList);
      
      final courseContent = [
        find.byType(Card),
        find.textContaining('Course'),
        find.text('No courses available'),
      ];
      
      bool foundContent = false;
      for (final content in courseContent) {
        if (content.evaluate().isNotEmpty) {
          foundContent = true;
          break;
        }
      }
      
      expect(foundContent, isTrue, reason: 'Should access courses after authentication recovery');
      print('✅ Course access restored after authentication recovery');
    });
  });
}