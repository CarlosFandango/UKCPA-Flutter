import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/presentation/providers/router_provider.dart';


void main() {
  group('Router Configuration Tests', () {

    test('AppRoutes constants are correct', () {
      expect(AppRoutes.splash, equals('/'));
      expect(AppRoutes.login, equals('/auth/login'));
      expect(AppRoutes.register, equals('/auth/register'));
      expect(AppRoutes.home, equals('/home'));
      expect(AppRoutes.courses, equals('/courses'));
      expect(AppRoutes.basket, equals('/basket'));
      expect(AppRoutes.checkout, equals('/checkout'));
      expect(AppRoutes.account, equals('/account'));
      expect(AppRoutes.orders, equals('/account/orders'));
    });

    test('Course detail route generation', () {
      expect(AppRoutes.courseDetail('123'), equals('/courses/123'));
      expect(AppRoutes.courseDetail('test-course'), equals('/courses/test-course'));
    });

    test('Login with redirect generation', () {
      expect(
        AppRoutes.loginWithRedirect('/courses/123'),
        equals('/auth/login?redirect=%2Fcourses%2F123'),
      );
    });

    test('Protected route detection', () {
      // Test routes that are explicitly protected
      expect(AppRoutes.isProtectedRoute('/home'), isTrue);
      expect(AppRoutes.isProtectedRoute('/checkout'), isTrue);
      expect(AppRoutes.isProtectedRoute('/account'), isTrue);
      expect(AppRoutes.isProtectedRoute('/courses'), isTrue);
      expect(AppRoutes.isProtectedRoute('/account/orders'), isTrue);
      
      // Test routes that are explicitly public
      expect(AppRoutes.isProtectedRoute('/'), isFalse);
      expect(AppRoutes.isProtectedRoute('/auth/login'), isFalse);
      expect(AppRoutes.isProtectedRoute('/auth/register'), isFalse);
      expect(AppRoutes.isProtectedRoute('/basket'), isFalse);
    });

    test('Public route detection', () {
      expect(AppRoutes.isPublicRoute('/'), isTrue);
      expect(AppRoutes.isPublicRoute('/auth/login'), isTrue);
      expect(AppRoutes.isPublicRoute('/auth/register'), isTrue);
      expect(AppRoutes.isPublicRoute('/basket'), isTrue);
      
      expect(AppRoutes.isPublicRoute('/home'), isFalse); // /home is protected
      expect(AppRoutes.isPublicRoute('/checkout'), isFalse);
      expect(AppRoutes.isPublicRoute('/account'), isFalse);
      expect(AppRoutes.isPublicRoute('/courses'), isFalse);
    });

    test('All routes list is complete', () {
      final allRoutes = AppRoutes.allRoutes;
      expect(allRoutes, contains('/'));
      expect(allRoutes, contains('/auth/login'));
      expect(allRoutes, contains('/auth/register'));
      expect(allRoutes, contains('/home'));
      expect(allRoutes, contains('/courses'));
      expect(allRoutes, contains('/basket'));
      expect(allRoutes, contains('/checkout'));
      expect(allRoutes, contains('/account'));
      expect(allRoutes, contains('/account/orders'));
      expect(allRoutes.length, equals(9));
    });
  });


  group('Error Handling Tests', () {
    test('404 error page component exists', () {
      final notFoundPage = AppNotFoundPage(
        error: 'Test error',
        uri: '/invalid/route',
      );
      expect(notFoundPage, isNotNull);
      expect(notFoundPage.error, equals('Test error'));
      expect(notFoundPage.uri, equals('/invalid/route'));
    });
  });
}