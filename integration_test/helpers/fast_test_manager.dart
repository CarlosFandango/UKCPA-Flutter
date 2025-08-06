import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';
import 'package:ukcpa_flutter/domain/repositories/auth_repository.dart';
import 'package:ukcpa_flutter/domain/entities/user.dart';
import 'package:ukcpa_flutter/presentation/providers/auth_provider.dart';
import 'automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// High-performance test manager for fast integration tests
/// Shares app initialization and authentication across multiple tests
class FastTestManager {
  static bool _appInitialized = false;
  static bool _userLoggedIn = false;
  static WidgetTester? _sharedTester;
  
  /// Initialize app for each test with ULTRA-FAST mocked setup
  static Future<void> initializeOnce(WidgetTester tester) async {
    if (_appInitialized) {
      print('⚡ Reinitializing app with MOCKED clean state (ultra-fast)');
      
      // Restart the app with mocked providers for clean, fast state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Use mocked auth repository for speed
            authRepositoryProvider.overrideWithValue(_mockAuthRepository),
          ],
          child: const UKCPAApp(),
        ),
      );
      
      // Minimal wait with mocked dependencies (no real network calls)
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      
      _sharedTester = tester;
      print('⚡ Mocked app state ready in ultra-fast mode');
      return;
    }
    
    print('🚀 Fast initialization starting...');
    final startTime = DateTime.now();
    
    // Load environment
    await dotenv.load(fileName: ".env");
    
    // Clear any stored authentication data for clean test state first
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
    
    // Initialize storage (only once) after clearing
    await Hive.initFlutter();
    await initHiveForFlutter();
    
    // Pump app with MOCKED providers for ultra-fast performance
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Use mocked auth repository for speed  
          authRepositoryProvider.overrideWithValue(_mockAuthRepository),
        ],
        child: const UKCPAApp(),
      ),
    );
    
    // Minimal wait with mocked dependencies (no real network calls)
    await tester.pumpAndSettle(const Duration(milliseconds: 300)); // Ultra-fast!
    
    // Verify basic app state
    expect(find.byType(MaterialApp), findsAtLeastNWidgets(1));
    
    _appInitialized = true;
    _sharedTester = tester;
    
    final duration = DateTime.now().difference(startTime);
    print('⚡ Fast initialization completed in ${duration.inMilliseconds}ms');
  }
  
  /// Ensure user is logged in (shared across tests)
  static Future<void> ensureLoggedIn(WidgetTester tester) async {
    if (_userLoggedIn && _sharedTester == tester) {
      print('⚡ User already logged in, skipping auth');
      return;
    }
    
    // Check if already on a logged-in screen
    if (find.text('Sign in to your account').evaluate().isEmpty) {
      print('⚡ Already logged in based on UI state');
      _userLoggedIn = true;
      return;
    }
    
    print('🔐 Performing fast login...');
    final startTime = DateTime.now();
    
    // Fast login process
    await AutomatedTestTemplate.enterText(
      tester,
      key: const Key('email-field'),
      text: TestCredentials.validEmail,
    );
    
    await AutomatedTestTemplate.enterText(
      tester,
      key: const Key('password-field'),
      text: TestCredentials.validPassword,
    );
    
    await AutomatedTestTemplate.tapButton(tester, 'Sign In');
    
    // Reduced wait for login - only wait for navigation
    await tester.pumpAndSettle(const Duration(seconds: 3)); // Was 8+ seconds
    
    // Verify login success
    if (find.text('Sign in to your account').evaluate().isEmpty) {
      _userLoggedIn = true;
      final duration = DateTime.now().difference(startTime);
      print('⚡ Fast login completed in ${duration.inMilliseconds}ms');
    } else {
      throw Exception('Fast login failed - still on login screen');
    }
  }
  
  /// Navigate to specific screen quickly
  static Future<void> navigateToScreen(
    WidgetTester tester, 
    String screenName, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    print('🧭 Fast navigation to $screenName');
    
    switch (screenName.toLowerCase()) {
      case 'courses':
      case 'course_discovery':
        final coursesTab = find.text('Courses');
        if (coursesTab.evaluate().isNotEmpty) {
          await tester.tap(coursesTab);
          await tester.pumpAndSettle(timeout);
        }
        break;
      case 'home':
        final homeTab = find.text('Home');
        if (homeTab.evaluate().isNotEmpty) {
          await tester.tap(homeTab);
          await tester.pumpAndSettle(timeout);
        }
        break;
      case 'basket':
        final basketTab = find.text('Basket');
        if (basketTab.evaluate().isNotEmpty) {
          await tester.tap(basketTab);
          await tester.pumpAndSettle(timeout);
        }
        break;
    }
  }
  
  /// Reset only necessary state between tests (not full app reinit)
  static Future<void> resetForNextTest(WidgetTester tester) async {
    if (!_appInitialized) return;
    
    print('🔄 Quick reset between tests');
    
    // Navigate back to home if not there
    if (find.text('Home').evaluate().isNotEmpty) {
      await tester.tap(find.text('Home'));
      await tester.pump(const Duration(milliseconds: 200));
    }
    
    // Clear any modal dialogs
    final backButtons = find.byIcon(Icons.arrow_back);
    if (backButtons.evaluate().isNotEmpty) {
      await tester.tap(backButtons.first);
      await tester.pump(const Duration(milliseconds: 200));
    }
  }
  
  /// Create fast test wrapper
  static void createFastTest(
    String description,
    Future<void> Function(WidgetTester tester) testFunction, {
    bool requiresAuth = true,
    String? navigateTo,
    Duration? timeout,
  }) {
    testWidgets(description, (WidgetTester tester) async {
      final testStartTime = DateTime.now();
      
      try {
        // Fast initialization (shared across tests)
        await initializeOnce(tester);
        
        // Fast authentication (shared if already done)
        if (requiresAuth) {
          await ensureLoggedIn(tester);
        }
        
        // Fast navigation if requested
        if (navigateTo != null) {
          await navigateToScreen(tester, navigateTo);
        }
        
        // Run the actual test
        await testFunction(tester);
        
        // Quick reset for next test
        await resetForNextTest(tester);
        
        final testDuration = DateTime.now().difference(testStartTime);
        print('⚡ Test "$description" completed in ${testDuration.inMilliseconds}ms');
        
      } catch (e, stackTrace) {
        final testDuration = DateTime.now().difference(testStartTime);
        print('❌ Test "$description" failed after ${testDuration.inMilliseconds}ms');
        print('Error: $e');
        rethrow;
      }
    }, timeout: Timeout(timeout ?? const Duration(minutes: 2))); // Reduced timeout
  }
  
  /// Batch multiple tests in one session for maximum speed
  static void createFastTestBatch(
    String groupName,
    Map<String, Future<void> Function(WidgetTester tester)> tests, {
    bool requiresAuth = true,
  }) {
    group(groupName, () {
      late WidgetTester sharedTester;
      
      setUpAll(() async {
        // This runs once for the entire group
        print('🚀 Setting up fast test batch: $groupName');
      });
      
      tearDownAll(() async {
        print('🏁 Tearing down fast test batch: $groupName');
        _appInitialized = false;
        _userLoggedIn = false;
        _sharedTester = null;
      });
      
      for (final entry in tests.entries) {
        createFastTest(
          entry.key,
          entry.value,
          requiresAuth: requiresAuth,
          timeout: const Duration(minutes: 1), // Aggressive timeout
        );
      }
    });
  }
  
  /// Performance monitoring
  static void logPerformanceStats() {
    print('📊 Fast Test Manager Stats:');
    print('  - App initialized: $_appInitialized');
    print('  - User logged in: $_userLoggedIn');
    print('  - Shared state active: ${_sharedTester != null}');
  }
  
  /// Reset all state (use sparingly)
  static void forceReset() {
    _appInitialized = false;
    _userLoggedIn = false;
    _sharedTester = null;
    print('🔄 Fast test manager reset');
  }
}

/// Mock Auth Repository for ultra-fast testing
class _MockAuthRepository implements AuthRepository {
  @override
  Future<AuthResponse> login(String email, String password) async {
    // Simulate instant login for valid credentials (ultra-fast)
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (email == TestCredentials.validEmail && password == TestCredentials.validPassword) {
      return AuthResponse(
        user: User(
          id: '123',
          email: email,
          firstName: 'Test',
          lastName: 'User',
        ),
        token: 'mock-jwt-token-12345',
      );
    }
    
    return AuthResponse(
      errors: [FieldError(path: 'email', message: 'Invalid email or password')],
    );
  }
  
  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return null; // Start with no user for clean state
  }
  
  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  @override
  Future<void> saveAuthToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 10));
  }
  
  @override
  Future<String?> getAuthToken() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return null;
  }
  
  @override
  Future<void> clearAuthToken() async {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

// Static instance for reuse
final _mockAuthRepository = _MockAuthRepository();