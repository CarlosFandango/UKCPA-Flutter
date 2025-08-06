import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:ukcpa_flutter/main.dart';
import 'package:ukcpa_flutter/domain/repositories/auth_repository.dart';
import 'package:ukcpa_flutter/domain/entities/user.dart';
import 'package:ukcpa_flutter/presentation/providers/auth_provider.dart';
import 'automated_test_template.dart';
import '../fixtures/test_credentials.dart';

/// Mock Auth Repository for super-fast testing
class MockAuthRepository extends Mock implements AuthRepository {
  @override
  Future<AuthResponse> login(String email, String password) async {
    // Simulate instant login for valid credentials
    await Future.delayed(const Duration(milliseconds: 100)); // Minimal delay
    
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
    
    // Return error for invalid credentials
    return AuthResponse(
      errors: [FieldError(path: 'email', message: 'Invalid email or password')],
    );
  }
  
  @override
  Future<User?> getCurrentUser() async {
    // Return a mocked authenticated user so we can test post-login screens
    await Future.delayed(const Duration(milliseconds: 50));
    return User(
      id: '123',
      email: TestCredentials.validEmail,
      firstName: 'Test',
      lastName: 'User',
    );
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
    return null; // Start with no token for clean state
  }
  
  @override
  Future<void> clearAuthToken() async {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

/// Ultra-fast test manager using mocked dependencies
class MockedFastTestManager {
  static bool _initialized = false;
  static late MockAuthRepository _mockAuthRepository;
  
  /// Initialize app with mocked dependencies for super-fast testing
  static Future<void> initializeMocked(WidgetTester tester) async {
    if (!_initialized) {
      print('🚀 Initializing mocked fast test environment...');
      final startTime = DateTime.now();
      
      // Load environment (only once)
      await dotenv.load(fileName: ".env");
      
      // Initialize storage (minimal setup)
      await Hive.initFlutter();
      await initHiveForFlutter();
      
      _mockAuthRepository = MockAuthRepository();
      _initialized = true;
      
      final duration = DateTime.now().difference(startTime);
      print('⚡ Mocked environment initialized in ${duration.inMilliseconds}ms');
    } else {
      print('⚡ Reusing mocked test environment (ultra-fast)');
    }
    
    // Always pump fresh app with mocked providers for clean state
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the auth repository with our mock
          authRepositoryProvider.overrideWithValue(_mockAuthRepository),
        ],
        child: const UKCPAApp(),
      ),
    );
    
    // Minimal wait for app to settle (much faster than real backend calls)
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    
    print('📱 Mocked app ready for testing');
  }
  
  /// Create fast test batch with mocked dependencies
  static void createMockedTestBatch(
    String description,
    Map<String, Future<void> Function(WidgetTester)> tests, {
    bool requiresAuth = false,
  }) {
    group(description, () {
      for (final entry in tests.entries) {
        testWidgets(entry.key, (WidgetTester tester) async {
          print('🏃‍♂️ Running mocked test: ${entry.key}');
          
          // Initialize with mocked dependencies
          await initializeMocked(tester);
          
          // Run the test
          await entry.value(tester);
        });
      }
    });
  }
}

/// Fast automated test template with reduced wait times
class FastAutomatedTestTemplate {
  
  /// Enter text into a field identified by key (fast version)
  static Future<void> enterText(
    WidgetTester tester, {
    required Key key,
    required String text,
    Duration delay = const Duration(milliseconds: 50), // Much faster
  }) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Field with key $key not found');
    
    await tester.enterText(finder, text);
    await tester.pump(delay);
  }
  
  /// Tap a button by text (fast version)
  static Future<void> tapButton(
    WidgetTester tester, 
    String buttonText, {
    Duration delay = const Duration(milliseconds: 100), // Much faster
  }) async {
    final finder = find.text(buttonText);
    expect(finder, findsOneWidget, reason: 'Button with text "$buttonText" not found');
    
    await tester.tap(finder);
    await tester.pump(delay);
  }
  
  /// Wait for UI changes (fast version)
  static Future<void> waitForUI(
    WidgetTester tester, {
    Duration duration = const Duration(milliseconds: 200), // Much faster
  }) async {
    await tester.pumpAndSettle(duration);
  }
}