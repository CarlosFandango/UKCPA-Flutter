import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/course_groups/course_group_discovery_screen.dart';
import '../screens/courses/course_detail_screen.dart';
import '../screens/course_groups/course_group_detail_screen.dart';
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
        builder: (context, state) => const CourseGroupDiscoveryScreen(),
      ),
      GoRoute(
        path: '/course-groups/:id',
        builder: (context, state) {
          final courseGroupId = int.parse(state.pathParameters['id']!);
          return CourseGroupDetailScreen(courseGroupId: courseGroupId);
        },
      ),
      GoRoute(
        path: '/courses/:id',
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CourseDetailScreen(courseId: courseId);
        },
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
    errorBuilder: (context, state) => AppNotFoundPage(
      error: state.error?.toString(),
      uri: state.uri.toString(),
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
  // Root and auth routes are explicitly public
  const publicRoutes = [
    '/',
    '/auth/login',
    '/auth/register',
    '/basket', // Basket can be used by guests
  ];
  
  // Protected routes require authentication
  const protectedRoutes = [
    '/home',
    '/checkout',
    '/account',
    '/courses', // Course browsing requires auth for full features
  ];
  
  // Check if route is explicitly public first
  for (final publicRoute in publicRoutes) {
    if (route == publicRoute || (route.startsWith(publicRoute) && publicRoute != '/')) {
      return false;
    }
  }
  
  // Check if route is explicitly protected
  for (final protectedRoute in protectedRoutes) {
    if (route.startsWith(protectedRoute)) {
      return true;
    }
  }
  
  // Default to requiring auth for unknown routes
  return true;
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

/// Enhanced navigation helpers with validation and safety
extension GoRouterExtension on BuildContext {
  // Basic navigation methods
  void goHome() => go('/home');
  void goToLogin({String? redirectPath}) {
    if (redirectPath != null && redirectPath.isNotEmpty) {
      go('/auth/login?redirect=${Uri.encodeComponent(redirectPath)}');
    } else {
      go('/auth/login');
    }
  }
  void goToRegister() => go('/auth/register');
  
  // Course navigation
  void goToCourses() => go('/courses');
  void goToCourseGroup(int id) => go('/course-groups/$id');
  void goToCourse(String id) {
    if (id.isNotEmpty) {
      go('/courses/$id');
    } else {
      goToCourses();
    }
  }
  
  // Shopping navigation
  void goToBasket() => go('/basket');
  void goToCheckout() => go('/checkout');
  
  // Account navigation
  void goToAccount() => go('/account');
  void goToOrders() => go('/account/orders');
  
  // Safe navigation with fallback
  void goToPath(String path, {String? fallback}) {
    try {
      if (_isValidInternalPath(path)) {
        go(path);
      } else if (fallback != null) {
        go(fallback);
      } else {
        goHome();
      }
    } catch (e) {
      if (fallback != null) {
        go(fallback);
      } else {
        goHome();
      }
    }
  }
  
  // Push navigation (for modal/detail views)
  void pushToCourse(String id) {
    if (id.isNotEmpty) {
      push('/courses/$id');
    }
  }
  
  void pushToOrders() => push('/account/orders');
  
  // Back navigation with safety
  void goBackSafe() {
    if (canPop()) {
      pop();
    } else {
      goHome();
    }
  }
  
  // Check if we can go back
  bool canGoBack() => canPop();
  
  // Logout navigation
  void goToLoginAfterLogout() {
    go('/auth/login');
  }
}

/// Additional route utilities
class AppRoutes {
  static const String splash = '/';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String home = '/home';
  static const String courses = '/courses';
  static const String basket = '/basket';
  static const String checkout = '/checkout';
  static const String account = '/account';
  static const String orders = '/account/orders';
  
  /// Generate course detail route
  static String courseDetail(String id) => '/courses/$id';
  
  /// Generate login with redirect
  static String loginWithRedirect(String redirectPath) => 
    '/auth/login?redirect=${Uri.encodeComponent(redirectPath)}';
  
  /// Get all available routes
  static List<String> get allRoutes => [
    splash,
    login,
    register,
    home,
    courses,
    basket,
    checkout,
    account,
    orders,
  ];
  
  /// Check if route requires authentication
  static bool isProtectedRoute(String route) => _isProtectedRoute(route);
  
  /// Check if route is public
  static bool isPublicRoute(String route) => !_isProtectedRoute(route);
}

/// Validate if a path is a valid internal app route
bool _isValidInternalPath(String path) {
  if (path.isEmpty || !path.startsWith('/')) return false;
  
  final validPaths = [
    '/',
    '/auth/login',
    '/auth/register', 
    '/home',
    '/courses',
    '/basket',
    '/checkout',
    '/account',
    '/account/orders',
  ];
  
  // Check exact matches
  if (validPaths.contains(path)) return true;
  
  // Check course detail pattern
  final courseDetailRegex = RegExp(r'^/courses/[a-zA-Z0-9_-]+$');
  if (courseDetailRegex.hasMatch(path)) return true;
  
  return false;
}

/// Custom 404 page component
class AppNotFoundPage extends StatelessWidget {
  final String? error;
  final String? uri;
  
  const AppNotFoundPage({
    super.key,
    this.error,
    this.uri,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 404 Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Page Not Found',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                'The page you\'re looking for doesn\'t exist or has been moved.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              if (uri != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Requested: $uri',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.goBackSafe(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  FilledButton.icon(
                    onPressed: () => context.goHome(),
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Additional navigation options
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  TextButton(
                    onPressed: () => context.goToCourses(),
                    child: const Text('Browse Courses'),
                  ),
                  TextButton(
                    onPressed: () => context.goToBasket(),
                    child: const Text('View Basket'),
                  ),
                  TextButton(
                    onPressed: () => context.goToAccount(),
                    child: const Text('My Account'),
                  ),
                ],
              ),
              
              if (error != null) ...[
                const SizedBox(height: 32),
                ExpansionTile(
                  title: Text(
                    'Technical Details',
                    style: theme.textTheme.bodySmall,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}