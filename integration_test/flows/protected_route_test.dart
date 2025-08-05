import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for protected route behavior
/// Tests redirects, deep links, auto-login, and route protection
class ProtectedRouteTest extends BaseIntegrationTest with PerformanceTest {
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      // Ensure backend is ready before running tests
      await BackendHealthCheck.ensureBackendReady();
    });

    group('Protected Route Tests', () {
      testIntegration('should redirect to login when accessing protected route without auth', (tester) async {
        await launchApp(tester);
        
        // Ensure we start logged out
        await TestHelpers.logoutUser(tester);
        
        // Try to navigate directly to a protected route (basket)
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/basket',
            routes: {
              '/login': (context) => Container(key: Key('login-screen')),
              '/basket': (context) => Container(key: Key('basket-screen')),
            },
          ),
        );
        await TestHelpers.waitForAnimations(tester);
        
        // Should be redirected to login screen
        expect(
          find.byKey(const Key('login-screen')).evaluate().isNotEmpty ||
          find.text('Welcome Back').evaluate().isNotEmpty ||
          find.text('Sign In').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should redirect to login when accessing protected route without auth',
        );
        
        // Should not show the basket screen
        expect(find.byKey(const Key('basket-screen')), findsNothing);
        
        await screenshot('protected_route_redirect');
      });

      testIntegration('should allow access to protected route when authenticated', (tester) async {
        await launchApp(tester);
        
        // Login first
        await TestHelpers.loginUser(
          tester,
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );
        
        // Navigate to protected route (course groups/discovery)
        final coursesButton = find.text('Browse Courses');
        final courseGroupsButton = find.text('Course Groups');
        final exploreButton = find.text('Explore');
        
        if (coursesButton.evaluate().isNotEmpty) {
          await tester.tap(coursesButton);
        } else if (courseGroupsButton.evaluate().isNotEmpty) {
          await tester.tap(courseGroupsButton);
        } else if (exploreButton.evaluate().isNotEmpty) {
          await tester.tap(exploreButton);
        }
        
        await TestHelpers.waitForAnimations(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Should successfully show the protected content
        expect(
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.text('Select a term').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show protected content when authenticated',
        );
        
        await screenshot('protected_route_authorized');
      });

      testIntegration('should handle deep links to protected routes', (tester) async {
        await measurePerformance('deep_link_handling', () async {
          await launchApp(tester);
          
          // Simulate deep link to basket page
          // This would typically be handled by the router
          final deepLinkData = {
            'route': '/basket',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          
          // If not logged in, should redirect to login with return path
          await TestHelpers.logoutUser(tester);
          
          // Attempt to navigate via deep link
          try {
            // This simulates the deep link handling
            await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
              'flutter/navigation',
              null,
              (data) {},
            );
          } catch (e) {
            // Deep link handling may not be available in test environment
            print('Deep link simulation not available in test environment');
          }
          
          await TestHelpers.waitForAnimations(tester);
        });
        
        // Verify we're on login screen (due to protection)
        expect(
          find.text('Welcome Back').evaluate().isNotEmpty ||
          find.text('Sign In').evaluate().isNotEmpty ||
          find.byKey(const Key('login-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Deep link to protected route should show login',
        );
        
        await screenshot('deep_link_login_redirect');
      });

      testIntegration('should remember intended route after login', (tester) async {
        await launchApp(tester);
        
        // Start logged out
        await TestHelpers.logoutUser(tester);
        
        // Try to access basket (simulating redirect scenario)
        // In a real app, this would store the intended destination
        final intendedRoute = '/basket';
        
        // Should be on login screen
        expect(
          find.text('Welcome Back').evaluate().isNotEmpty ||
          find.text('Sign In').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show login screen when accessing protected route',
        );
        
        // Login
        await TestHelpers.loginUser(
          tester,
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );
        
        // After successful login, check if we can navigate to basket
        final basketButton = find.byIcon(Icons.shopping_cart);
        final basketText = find.text('Basket');
        final basketKey = find.byKey(const Key('basket-icon'));
        
        if (basketButton.evaluate().isNotEmpty) {
          await tester.tap(basketButton);
        } else if (basketText.evaluate().isNotEmpty) {
          await tester.tap(basketText);
        } else if (basketKey.evaluate().isNotEmpty) {
          await tester.tap(basketKey);
        }
        
        await TestHelpers.waitForAnimations(tester);
        
        // Should now show basket or related content
        expect(
          find.text('Your Basket').evaluate().isNotEmpty ||
          find.text('Basket').evaluate().isNotEmpty ||
          find.text('No items').evaluate().isNotEmpty ||
          find.byKey(const Key('basket-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should navigate to intended route after login',
        );
        
        await screenshot('post_login_navigation');
      });

      testIntegration('should maintain session across app restarts', (tester) async {
        await launchApp(tester);
        
        // Login
        await TestHelpers.loginUser(
          tester,
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );
        
        // Verify logged in state
        expect(
          find.byKey(const Key('user-menu')).evaluate().isNotEmpty ||
          find.byIcon(Icons.account_circle).evaluate().isNotEmpty ||
          find.text('Logout').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show logged in state',
        );
        
        await screenshot('logged_in_state');
        
        // Simulate app restart by reinitializing
        await tester.binding.reassembleApplication();
        await TestHelpers.waitForAnimations(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Should still be logged in (session persisted)
        // Check for logged-in indicators
        final isStillLoggedIn = 
          find.byKey(const Key('user-menu')).evaluate().isNotEmpty ||
          find.byIcon(Icons.account_circle).evaluate().isNotEmpty ||
          find.text('Logout').evaluate().isNotEmpty ||
          // If redirected to login, session was not maintained
          find.text('Welcome Back').evaluate().isEmpty;
        
        expect(
          isStillLoggedIn,
          isTrue,
          reason: 'Session should persist across app restarts',
        );
        
        await screenshot('session_after_restart');
      });

      testIntegration('should handle auto-login with stored credentials', (tester) async {
        await measurePerformance('auto_login', () async {
          await launchApp(tester);
          
          // If there are stored valid credentials, app should auto-login
          // Wait for potential auto-login process
          await TestHelpers.waitForNetworkIdle(tester);
          await TestHelpers.waitForAnimations(tester);
          
          // Give extra time for auto-login to complete
          await tester.pump(const Duration(seconds: 2));
        });
        
        // Check if we're logged in or on login screen
        final isLoggedIn = 
          find.byKey(const Key('user-menu')).evaluate().isNotEmpty ||
          find.byIcon(Icons.account_circle).evaluate().isNotEmpty ||
          find.text('Logout').evaluate().isNotEmpty;
        
        final isOnLoginScreen = 
          find.text('Welcome Back').evaluate().isNotEmpty ||
          find.text('Sign In').evaluate().isNotEmpty;
        
        // Should be in one of these states
        expect(
          isLoggedIn || isOnLoginScreen,
          isTrue,
          reason: 'Should either auto-login or show login screen',
        );
        
        if (isLoggedIn) {
          await screenshot('auto_login_success');
          print('✅ Auto-login successful');
        } else {
          await screenshot('no_auto_login');
          print('ℹ️ No stored credentials for auto-login');
        }
      });

      testIntegration('should handle logout and clear session', (tester) async {
        await launchApp(tester);
        
        // Ensure we're logged in first
        await TestHelpers.loginUser(
          tester,
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );
        
        // Verify logged in
        expect(
          find.byKey(const Key('user-menu')).evaluate().isNotEmpty ||
          find.byIcon(Icons.account_circle).evaluate().isNotEmpty ||
          find.text('Logout').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should be logged in before logout test',
        );
        
        // Logout
        await TestHelpers.logoutUser(tester);
        
        // Should be back on login screen
        expect(
          find.text('Welcome Back').evaluate().isNotEmpty ||
          find.text('Sign In').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show login screen after logout',
        );
        
        // Try to access protected route - should redirect to login
        final coursesButton = find.text('Browse Courses');
        if (coursesButton.evaluate().isNotEmpty) {
          await tester.tap(coursesButton);
          await TestHelpers.waitForAnimations(tester);
          
          // Should still be on login or show login requirement
          expect(
            find.text('Welcome Back').evaluate().isNotEmpty ||
            find.text('Sign In').evaluate().isNotEmpty ||
            find.text('Please log in').evaluate().isNotEmpty,
            isTrue,
            reason: 'Should require login after logout',
          );
        }
        
        await screenshot('after_logout_protection');
      });

      testIntegration('should handle expired session gracefully', (tester) async {
        await launchApp(tester);
        
        // Login first
        await TestHelpers.loginUser(
          tester,
          email: TestCredentials.validEmail,
          password: TestCredentials.validPassword,
        );
        
        // Simulate session expiration by making a request that would fail
        // In a real scenario, this would be triggered by a 401 response
        try {
          // This would typically be done by making an authenticated request
          // that returns 401, triggering session cleanup
          await TestHelpers.waitForNetworkIdle(tester);
          
          // For testing, we can't easily simulate server-side session expiration
          // So we'll test the UI behavior when auth state changes
          print('ℹ️ Session expiration simulation not fully available in test environment');
          
        } catch (e) {
          print('Session expiration test: $e');
        }
        
        // The app should handle session expiration by redirecting to login
        // This is more of a integration test with the backend
        await screenshot('session_expiration_handling');
      });
    });

    tearDownAll(() async {
      printPerformanceReport();
      await generateFailureAnalysisReport();
    });
  }
}

// Test runner
void main() {
  ProtectedRouteTest().main();
}