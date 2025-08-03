import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/constants/app_constants.dart';
import '../datasources/graphql_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GraphQLClient _client;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();
  
  AuthRepositoryImpl({
    GraphQLClient? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? getGraphQLClient(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();
  
  @override
  Future<AuthResponse> login(String email, String password) async {
    _logger.d('Attempting login for email: $email');
    
    final String loginMutation = '''
      ${GraphQLFragments.userBasicFragment}
      
      mutation Login(\$data: LoginInput!) {
        login(data: \$data) {
          user {
            ...UserBasicFragment
          }
          token
          errors {
            path
            message
          }
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(loginMutation),
          variables: {
            'data': {
              'email': email.trim().toLowerCase(),
              'password': password,
            },
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      
      if (result.hasException) {
        _logger.e('Login GraphQL exception: ${result.exception}');
        return _handleGraphQLException(result.exception!);
      }
      
      final data = result.data?['login'];
      
      if (data == null) {
        _logger.e('Login returned null data');
        return AuthResponse(
          errors: [FieldError(path: 'general', message: 'No data returned from server')],
        );
      }
      
      // Handle server-side validation errors
      if (data['errors'] != null && (data['errors'] as List).isNotEmpty) {
        _logger.w('Login validation errors: ${data['errors']}');
        return AuthResponse(
          errors: (data['errors'] as List)
              .map((e) => FieldError(
                    path: e['path'] ?? 'general',
                    message: e['message'] ?? 'Unknown error',
                  ))
              .toList(),
        );
      }
      
      final user = data['user'] != null ? User.fromJson(data['user']) : null;
      final token = data['token'] as String?;
      
      if (user != null && token != null) {
        _logger.d('Login successful for user: ${user.id}');
        await saveAuthToken(token);
        await _cacheUserData(user);
        
        return AuthResponse(user: user, token: token);
      } else {
        _logger.e('Login missing user or token data');
        return AuthResponse(
          errors: [FieldError(path: 'general', message: 'Invalid login response')],
        );
      }
    } catch (e) {
      _logger.e('Login exception: $e');
      return AuthResponse(
        errors: [FieldError(path: 'general', message: _parseErrorMessage(e))],
      );
    }
  }
  
  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _logger.d('Attempting registration for email: $email');
    
    final String registerMutation = '''
      ${GraphQLFragments.userBasicFragment}
      
      mutation Register(\$data: CreateUserInput!) {
        register(data: \$data) {
          user {
            ...UserBasicFragment
          }
          errors {
            path
            message
          }
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(registerMutation),
          variables: {
            'data': {
              'email': email.trim().toLowerCase(),
              'password': password,
              'firstName': firstName.trim(),
              'lastName': lastName.trim(),
            },
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      
      if (result.hasException) {
        _logger.e('Registration GraphQL exception: ${result.exception}');
        return _handleGraphQLException(result.exception!);
      }
      
      final data = result.data?['register'];
      
      if (data == null) {
        _logger.e('Registration returned null data');
        return AuthResponse(
          errors: [FieldError(path: 'general', message: 'No data returned from server')],
        );
      }
      
      // Handle server-side validation errors
      if (data['errors'] != null && (data['errors'] as List).isNotEmpty) {
        _logger.w('Registration validation errors: ${data['errors']}');
        return AuthResponse(
          errors: (data['errors'] as List)
              .map((e) => FieldError(
                    path: e['path'] ?? 'general',
                    message: e['message'] ?? 'Unknown error',
                  ))
              .toList(),
        );
      }
      
      final user = data['user'] != null ? User.fromJson(data['user']) : null;
      
      if (user != null) {
        _logger.d('Registration successful for user: ${user.id}');
        await _cacheUserData(user);
        
        return AuthResponse(user: user);
      } else {
        _logger.e('Registration missing user data');
        return AuthResponse(
          errors: [FieldError(path: 'general', message: 'Registration failed')],
        );
      }
    } catch (e) {
      _logger.e('Registration exception: $e');
      return AuthResponse(
        errors: [FieldError(path: 'general', message: _parseErrorMessage(e))],
      );
    }
  }
  
  @override
  Future<void> logout() async {
    _logger.d('Attempting logout');
    
    const String logoutMutation = '''
      mutation LogOut {
        logout
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(logoutMutation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      
      if (result.hasException) {
        _logger.w('Logout GraphQL exception (proceeding with local cleanup): ${result.exception}');
      } else {
        _logger.d('Server logout successful');
      }
    } catch (e) {
      _logger.w('Logout error (proceeding with local cleanup): $e');
    }
    
    // Always clear local auth data, even if server logout fails
    await _clearAllAuthData();
    _logger.d('Local auth data cleared');
  }
  
  @override
  Future<User?> getCurrentUser() async {
    _logger.d('Fetching current user');
    
    // First check if we have a token
    final token = await getAuthToken();
    if (token == null) {
      _logger.d('No auth token found');
      return null;
    }
    
    // Try to get cached user first
    final cachedUser = await _getCachedUserData();
    if (cachedUser != null) {
      _logger.d('Returning cached user: ${cachedUser.id}');
      return cachedUser;
    }
    
    // Fetch from server
    final String meQuery = '''
      ${GraphQLFragments.userBasicFragment}
      
      query Me {
        me {
          user {
            ...UserBasicFragment
          }
        }
      }
    ''';
    
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(meQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      
      if (result.hasException) {
        _logger.e('Get current user exception: ${result.exception}');
        
        // If unauthorized, clear auth data
        if (_isUnauthorizedException(result.exception!)) {
          _logger.w('Unauthorized - clearing auth data');
          await _clearAllAuthData();
        }
        
        return null;
      }
      
      final userData = result.data?['me']?['user'];
      if (userData != null) {
        final user = User.fromJson(userData);
        _logger.d('Fetched current user: ${user.id}');
        await _cacheUserData(user);
        return user;
      } else {
        _logger.w('No user data returned from server');
        return null;
      }
    } catch (e) {
      _logger.e('Get current user error: $e');
      return null;
    }
  }
  
  @override
  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: AppConstants.authTokenKey);
    } catch (e) {
      _logger.e('Error reading auth token: $e');
      return null;
    }
  }
  
  @override
  Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
      _logger.d('Auth token saved successfully');
    } catch (e) {
      _logger.e('Error saving auth token: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> clearAuthToken() async {
    try {
      await _secureStorage.delete(key: AppConstants.authTokenKey);
      _logger.d('Auth token cleared successfully');
    } catch (e) {
      _logger.e('Error clearing auth token: $e');
      rethrow;
    }
  }
  
  // Private helper methods
  
  Future<void> _cacheUserData(User user) async {
    try {
      final userJson = user.toJson();
      await _secureStorage.write(
        key: AppConstants.userDataKey,
        value: userJson.toString(),
      );
      _logger.d('User data cached successfully');
    } catch (e) {
      _logger.w('Failed to cache user data: $e');
      // Don't throw - caching is not critical
    }
  }
  
  Future<User?> _getCachedUserData() async {
    try {
      final userDataStr = await _secureStorage.read(key: AppConstants.userDataKey);
      if (userDataStr != null) {
        // Note: This is a simplified approach. In production, you might want
        // to use a proper JSON serialization library
        return null; // For now, always fetch from server
      }
      return null;
    } catch (e) {
      _logger.w('Failed to read cached user data: $e');
      return null;
    }
  }
  
  Future<void> _clearAllAuthData() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: AppConstants.authTokenKey),
        _secureStorage.delete(key: AppConstants.userDataKey),
        _secureStorage.delete(key: AppConstants.basketKey),
      ]);
      
      // Reset GraphQL client to clear any cached auth headers
      GraphQLClientUtils.resetClient();
      
      _logger.d('All auth data cleared successfully');
    } catch (e) {
      _logger.e('Error clearing auth data: $e');
      rethrow;
    }
  }
  
  AuthResponse _handleGraphQLException(OperationException exception) {
    final errorMessage = parseGraphQLError(exception);
    
    if (errorMessage == AppConstants.sessionExpired) {
      // Clear auth data on session expiry
      _clearAllAuthData();
    }
    
    return AuthResponse(
      errors: [FieldError(path: 'general', message: errorMessage)],
    );
  }
  
  bool _isUnauthorizedException(OperationException exception) {
    if (exception.graphqlErrors.isNotEmpty) {
      for (final error in exception.graphqlErrors) {
        if (error.extensions?['code'] == 'UNAUTHENTICATED' ||
            error.message.toLowerCase().contains('unauthorized') ||
            error.message.toLowerCase().contains('unauthenticated')) {
          return true;
        }
      }
    }
    return false;
  }
  
  String _parseErrorMessage(dynamic error) {
    if (error is OperationException) {
      return parseGraphQLError(error);
    }
    
    final errorStr = error.toString();
    
    // Common network errors
    if (errorStr.contains('SocketException') || errorStr.contains('Connection')) {
      return AppConstants.networkError;
    }
    
    if (errorStr.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    
    if (errorStr.contains('FormatException')) {
      return 'Invalid server response. Please try again.';
    }
    
    return errorStr.length > 100 
        ? AppConstants.unknownError 
        : errorStr;
  }
}