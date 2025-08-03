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

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      
      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && _isProtectedRoute(state.matchedLocation)) {
        return '/auth/login?redirect=${state.matchedLocation}';
      }
      
      // Redirect to home if authenticated and trying to access auth routes
      if (isAuthenticated && isAuthRoute) {
        return '/home';
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

bool _isProtectedRoute(String route) {
  const protectedRoutes = [
    '/checkout',
    '/account',
  ];
  
  return protectedRoutes.any((r) => route.startsWith(r));
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