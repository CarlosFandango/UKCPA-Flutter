import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/constants/app_constants.dart';
import '../datasources/graphql_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GraphQLClient _client;
  final FlutterSecureStorage _secureStorage;
  
  AuthRepositoryImpl({
    GraphQLClient? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? getGraphQLClient(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();
  
  @override
  Future<AuthResponse> login(String email, String password) async {
    const String loginMutation = r'''
      mutation Login($data: LoginInput!) {
        login(data: $data) {
          user {
            id
            email
            firstName
            lastName
            profileImageUrl
            stripeCustomerId
            roles
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
              'email': email,
              'password': password,
            },
          },
        ),
      );
      
      if (result.hasException) {
        throw result.exception!;
      }
      
      final data = result.data?['login'];
      
      if (data['errors'] != null && data['errors'].isNotEmpty) {
        return AuthResponse(
          errors: (data['errors'] as List)
              .map((e) => FieldError(
                    path: e['path'],
                    message: e['message'],
                  ))
              .toList(),
        );
      }
      
      return AuthResponse(
        user: data['user'] != null ? User.fromJson(data['user']) : null,
        token: data['token'],
      );
    } catch (e) {
      return AuthResponse(
        errors: [
          FieldError(
            path: 'general',
            message: e.toString(),
          ),
        ],
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
    const String registerMutation = r'''
      mutation Register($data: CreateUserInput!) {
        register(data: $data) {
          user {
            id
            email
            firstName
            lastName
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
              'email': email,
              'password': password,
              'firstName': firstName,
              'lastName': lastName,
            },
          },
        ),
      );
      
      if (result.hasException) {
        throw result.exception!;
      }
      
      final data = result.data?['register'];
      
      if (data['errors'] != null && data['errors'].isNotEmpty) {
        return AuthResponse(
          errors: (data['errors'] as List)
              .map((e) => FieldError(
                    path: e['path'],
                    message: e['message'],
                  ))
              .toList(),
        );
      }
      
      return AuthResponse(
        user: data['user'] != null ? User.fromJson(data['user']) : null,
      );
    } catch (e) {
      return AuthResponse(
        errors: [
          FieldError(
            path: 'general',
            message: e.toString(),
          ),
        ],
      );
    }
  }
  
  @override
  Future<void> logout() async {
    const String logoutMutation = r'''
      mutation LogOut {
        logout
      }
    ''';
    
    try {
      await _client.mutate(
        MutationOptions(
          document: gql(logoutMutation),
        ),
      );
    } catch (e) {
      // Log error but don't throw - we still want to clear local auth
      print('Logout error: $e');
    }
    
    await clearAuthToken();
  }
  
  @override
  Future<User?> getCurrentUser() async {
    const String meQuery = r'''
      query Me {
        me {
          user {
            id
            email
            firstName
            lastName
            profileImageUrl
            address {
              line1
              line2
              city
              county
              country
              postCode
            }
            stripeCustomerId
            roles
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
        throw result.exception!;
      }
      
      final userData = result.data?['me']?['user'];
      return userData != null ? User.fromJson(userData) : null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }
  
  @override
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: AppConstants.authTokenKey);
  }
  
  @override
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
  }
  
  @override
  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: AppConstants.authTokenKey);
  }
}