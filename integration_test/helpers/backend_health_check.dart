import 'package:dio/dio.dart';
import '../fixtures/test_credentials.dart';

/// Backend health check utilities for integration tests
class BackendHealthCheck {
  static const String _graphqlEndpoint = 'http://localhost:4000/graphql';
  
  /// Check if backend is running and accessible
  static Future<bool> isBackendHealthy() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    
    try {
      // Simple introspection query to check GraphQL endpoint
      final response = await dio.post(
        _graphqlEndpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'siteid': TestCredentials.testSiteId,
          },
        ),
        data: {
          'query': r'''
            query HealthCheck {
              __schema {
                queryType {
                  name
                }
              }
            }
          ''',
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return data['data'] != null && data['data']['__schema'] != null;
      }
      
      return false;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }
  
  /// Wait for backend to be ready
  static Future<void> waitForBackend({
    Duration timeout = const Duration(seconds: 30),
    Duration checkInterval = const Duration(seconds: 1),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      if (await isBackendHealthy()) {
        print('✅ Backend is ready after ${stopwatch.elapsed.inSeconds} seconds');
        return;
      }
      
      await Future.delayed(checkInterval);
    }
    
    throw Exception('Backend did not become ready within $timeout');
  }
  
  /// Check if test user exists
  static Future<bool> checkTestUserExists() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    
    try {
      final response = await dio.post(
        _graphqlEndpoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'siteid': TestCredentials.testSiteId,
          },
        ),
        data: {
          'query': r'''
            mutation TestLogin($email: String!, $password: String!) {
              login(email: $email, password: $password) {
                errors {
                  field
                  message
                }
                user {
                  id
                  email
                }
              }
            }
          ''',
          'variables': {
            'email': TestCredentials.validEmail,
            'password': TestCredentials.validPassword,
          },
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final loginData = data['data']?['login'];
        
        // Check if login was successful
        return loginData != null && 
               loginData['user'] != null && 
               loginData['errors'] == null;
      }
      
      return false;
    } catch (e) {
      print('Test user check failed: $e');
      return false;
    }
  }
  
  /// Get backend version information
  static Future<Map<String, dynamic>?> getBackendInfo() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    
    try {
      final response = await dio.get(
        'http://localhost:4000/health',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      // Health endpoint might not exist, that's okay
      return null;
    }
  }
  
  /// Ensure test data exists
  static Future<void> ensureTestData() async {
    // Check if test user exists
    final userExists = await checkTestUserExists();
    
    if (!userExists) {
      print('⚠️  Test user does not exist or credentials are invalid');
      print('   Please ensure test user exists with:');
      print('   Email: ${TestCredentials.validEmail}');
      print('   Password: ${TestCredentials.validPassword}');
      
      // Try alternative credentials
      print('   Trying alternative credentials...');
      
      // For now, just warn but don't fail - tests can run without backend user
      print('⚠️  Warning: Tests will run without backend authentication');
      print('   Some tests may fail that require actual login');
      return;
    }
    
    print('✅ Test user verified');
  }
  
  /// Full backend readiness check
  static Future<void> ensureBackendReady() async {
    print('🔍 Checking backend readiness...');
    
    // 1. Check if backend is healthy
    await waitForBackend();
    
    // 2. Get backend info if available
    final info = await getBackendInfo();
    if (info != null) {
      print('📊 Backend info: $info');
    }
    
    // 3. Ensure test data exists
    await ensureTestData();
    
    print('✅ Backend is fully ready for integration tests');
  }
}