import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/courses/course_list_screen.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/basket/basket_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/orders_screen.dart';
import 'auth_provider.dart';

/// Router provider with auth-aware navigation
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isAuthenticated = authState is AuthStateAuthenticated;
      final isAuthLoading = authState is AuthStateLoading || authState is AuthStateInitial;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final location = state.matchedLocation;
      
      // Don't redirect during initial auth check or loading
      if (isAuthLoading && location == '/') {
        return null; // Stay on splash
      }
      
      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isAuthLoading && _isProtectedRoute(location)) {
        return '/auth/login?redirect=${Uri.encodeComponent(location)}';
      }
      
      // Redirect to home if authenticated and trying to access auth routes
      if (isAuthenticated && isAuthRoute) {
        final redirectParam = state.uri.queryParameters['redirect'];
        if (redirectParam != null && redirectParam.isNotEmpty) {
          try {
            final decodedRedirect = Uri.decodeComponent(redirectParam);
            if (_isValidRedirect(decodedRedirect)) {
              return decodedRedirect;
            }
          } catch (e) {
            // Invalid redirect, fall back to home
          }
        }
        return '/home';
      }
      
      // Redirect from splash to appropriate screen after auth check
      if (location == '/' && !isAuthLoading) {
        return isAuthenticated ? '/home' : '/auth/login';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return LoginScreen(redirectPath: redirect);
        },
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/courses',
        builder: (context, state) => const CourseListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final courseId = state.pathParameters['id']!;
              return CourseDetailScreen(courseId: courseId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/basket',
        builder: (context, state) => const BasketScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
        routes: [
          GoRoute(
            path: 'orders',
            builder: (context, state) => const OrdersScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Router refresh notifier to listen to auth state changes
class RouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;
  
  RouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      // Notify router when auth state changes
      if (previous.runtimeType != next.runtimeType) {
        notifyListeners();
      }
    });
  }
}

/// Check if a route requires authentication
bool _isProtectedRoute(String route) {
  const protectedRoutes = [
    '/checkout',
    '/account',
    '/courses', // Course browsing requires auth for full features
  ];
  
  // Root and auth routes are not protected
  const publicRoutes = [
    '/',
    '/auth',
    '/basket', // Basket can be used by guests
  ];
  
  // Check if route is explicitly public
  if (publicRoutes.any((r) => route.startsWith(r))) {
    return false;
  }
  
  // Check if route is explicitly protected
  return protectedRoutes.any((r) => route.startsWith(r));
}

/// Validate redirect URLs to prevent open redirect attacks
bool _isValidRedirect(String redirect) {
  // Only allow internal app routes
  const validPrefixes = [
    '/home',
    '/courses',
    '/basket',
    '/checkout',
    '/account',
  ];
  
  return validPrefixes.any((prefix) => redirect.startsWith(prefix));
}

// Navigation helpers
extension GoRouterExtension on BuildContext {
  void goHome() => go('/home');
  void goToLogin() => go('/auth/login');
  void goToCourses() => go('/courses');
  void goToCourse(String id) => go('/courses/$id');
  void goToBasket() => go('/basket');
  void goToCheckout() => go('/checkout');
  void goToAccount() => go('/account');
  void goToOrders() => go('/account/orders');
}