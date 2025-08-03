import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import 'package:ukcpa_flutter/data/repositories/auth_repository_impl.dart';
import 'package:ukcpa_flutter/domain/entities/user.dart';
import 'package:ukcpa_flutter/core/constants/app_constants.dart';

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([GraphQLClient, FlutterSecureStorage])
void main() {
  group('AuthRepositoryImpl', () {
    late AuthRepositoryImpl authRepository;
    late MockGraphQLClient mockGraphQLClient;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockGraphQLClient = MockGraphQLClient();
      mockSecureStorage = MockFlutterSecureStorage();
      authRepository = AuthRepositoryImpl(
        client: mockGraphQLClient,
        secureStorage: mockSecureStorage,
      );
    });

    final testUser = User(
      id: 'test-user-id',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      roles: ['STUDENT'],
    );

    final testToken = 'test-jwt-token';

    group('login', () {
      test('should return AuthResponse with user and token on successful login', () async {
        // Arrange
        final mockResult = QueryResult(
          data: {
            'login': {
              'user': {
                'id': testUser.id,
                'email': testUser.email,
                'firstName': testUser.firstName,
                'lastName': testUser.lastName,
                'profileImageUrl': null,
                'address': null,
                'stripeCustomerId': null,
                'roles': testUser.roles,
              },
              'token': testToken,
              'errors': null,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        final result = await authRepository.login('test@example.com', 'password');

        // Assert
        expect(result.isSuccess, true);
        expect(result.hasErrors, false);
        expect(result.user?.id, testUser.id);
        expect(result.user?.email, testUser.email);
        expect(result.token, testToken);

        verify(mockSecureStorage.write(
          key: AppConstants.authTokenKey,
          value: testToken,
        )).called(1);
      });

      test('should return AuthResponse with errors on server validation errors', () async {
        // Arrange
        final mockResult = QueryResult(
          data: {
            'login': {
              'user': null,
              'token': null,
              'errors': [
                {'path': 'email', 'message': 'Invalid email'},
                {'path': 'password', 'message': 'Invalid password'},
              ],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);

        // Act
        final result = await authRepository.login('invalid@example.com', 'wrongpassword');

        // Assert
        expect(result.isSuccess, false);
        expect(result.hasErrors, true);
        expect(result.errors?.length, 2);
        expect(result.errors?[0].path, 'email');
        expect(result.errors?[0].message, 'Invalid email');
        expect(result.errors?[1].path, 'password');
        expect(result.errors?[1].message, 'Invalid password');
      });

      test('should handle GraphQL exceptions', () async {
        // Arrange
        final exception = OperationException(
          graphqlErrors: [
            GraphQLError(message: 'Network error'),
          ],
        );
        final mockResult = QueryResult(
          exception: exception,
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);

        // Act
        final result = await authRepository.login('test@example.com', 'password');

        // Assert
        expect(result.isSuccess, false);
        expect(result.hasErrors, true);
        expect(result.errors?.length, 1);
        expect(result.errors?[0].path, 'general');
      });

      test('should normalize email to lowercase and trim whitespace', () async {
        // Arrange
        final mockResult = QueryResult(
          data: {
            'login': {
              'user': {
                'id': testUser.id,
                'email': testUser.email,
                'firstName': testUser.firstName,
                'lastName': testUser.lastName,
                'profileImageUrl': null,
                'address': null,
                'stripeCustomerId': null,
                'roles': testUser.roles,
              },
              'token': testToken,
              'errors': null,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await authRepository.login('  TEST@EXAMPLE.COM  ', 'password');

        // Assert
        final captured = verify(mockGraphQLClient.mutate(captureAny)).captured;
        final mutationOptions = captured[0] as MutationOptions;
        expect(mutationOptions.variables['data']['email'], 'test@example.com');
      });
    });

    group('register', () {
      test('should return AuthResponse with user on successful registration', () async {
        // Arrange
        final mockResult = QueryResult(
          data: {
            'register': {
              'user': {
                'id': testUser.id,
                'email': testUser.email,
                'firstName': testUser.firstName,
                'lastName': testUser.lastName,
                'profileImageUrl': null,
                'address': null,
                'stripeCustomerId': null,
                'roles': testUser.roles,
              },
              'errors': null,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        final result = await authRepository.register(
          email: 'test@example.com',
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.hasErrors, false);
        expect(result.user?.id, testUser.id);
        expect(result.user?.email, testUser.email);
        expect(result.token, null); // Registration doesn't return token
      });

      test('should handle registration validation errors', () async {
        // Arrange
        final mockResult = QueryResult(
          data: {
            'register': {
              'user': null,
              'errors': [
                {'path': 'email', 'message': 'Email already exists'},
              ],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);

        // Act
        final result = await authRepository.register(
          email: 'existing@example.com',
          password: 'password123',
          firstName: 'Test',
          lastName: 'User',
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.hasErrors, true);
        expect(result.errors?.length, 1);
        expect(result.errors?[0].path, 'email');
        expect(result.errors?[0].message, 'Email already exists');
      });

      test('should trim and normalize registration data', () async {
        // Arrange
        final mockResult = QueryResult(
          data: {
            'register': {
              'user': {
                'id': testUser.id,
                'email': testUser.email,
                'firstName': testUser.firstName,
                'lastName': testUser.lastName,
                'profileImageUrl': null,
                'address': null,
                'stripeCustomerId': null,
                'roles': testUser.roles,
              },
              'errors': null,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await authRepository.register(
          email: '  TEST@EXAMPLE.COM  ',
          password: 'password123',
          firstName: '  Test  ',
          lastName: '  User  ',
        );

        // Assert
        final captured = verify(mockGraphQLClient.mutate(captureAny)).captured;
        final mutationOptions = captured[0] as MutationOptions;
        final data = mutationOptions.variables['data'];
        expect(data['email'], 'test@example.com');
        expect(data['firstName'], 'Test');
        expect(data['lastName'], 'User');
      });
    });

    group('logout', () {
      test('should call logout mutation and clear auth data', () async {
        // Arrange
        final mockResult = QueryResult(
          data: {'logout': true},
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await authRepository.logout();

        // Assert
        verify(mockGraphQLClient.mutate(any)).called(1);
        verify(mockSecureStorage.delete(key: AppConstants.authTokenKey)).called(1);
        verify(mockSecureStorage.delete(key: AppConstants.userDataKey)).called(1);
        verify(mockSecureStorage.delete(key: AppConstants.basketKey)).called(1);
      });

      test('should clear auth data even if server logout fails', () async {
        // Arrange
        final exception = OperationException(
          graphqlErrors: [GraphQLError(message: 'Server error')],
        );
        final mockResult = QueryResult(
          exception: exception,
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.mutate(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await authRepository.logout();

        // Assert
        verify(mockSecureStorage.delete(key: AppConstants.authTokenKey)).called(1);
        verify(mockSecureStorage.delete(key: AppConstants.userDataKey)).called(1);
        verify(mockSecureStorage.delete(key: AppConstants.basketKey)).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should return null when no auth token exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.authTokenKey))
            .thenAnswer((_) async => null);

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, null);
        verifyNever(mockGraphQLClient.query(any));
      });

      test('should fetch user from server when token exists', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.authTokenKey))
            .thenAnswer((_) async => testToken);
        when(mockSecureStorage.read(key: AppConstants.userDataKey))
            .thenAnswer((_) async => null);

        final mockResult = QueryResult(
          data: {
            'me': {
              'user': {
                'id': testUser.id,
                'email': testUser.email,
                'firstName': testUser.firstName,
                'lastName': testUser.lastName,
                'profileImageUrl': null,
                'address': null,
                'stripeCustomerId': null,
                'roles': testUser.roles,
              }
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.query(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result?.id, testUser.id);
        expect(result?.email, testUser.email);
        verify(mockGraphQLClient.query(any)).called(1);
      });

      test('should clear auth data on unauthorized exception', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.authTokenKey))
            .thenAnswer((_) async => testToken);
        when(mockSecureStorage.read(key: AppConstants.userDataKey))
            .thenAnswer((_) async => null);

        final exception = OperationException(
          graphqlErrors: [
            GraphQLError(
              message: 'Unauthorized',
              extensions: {'code': 'UNAUTHENTICATED'},
            ),
          ],
        );
        final mockResult = QueryResult(
          exception: exception,
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockGraphQLClient.query(any)).thenAnswer((_) async => mockResult);
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        final result = await authRepository.getCurrentUser();

        // Assert
        expect(result, null);
        verify(mockSecureStorage.delete(key: AppConstants.authTokenKey)).called(1);
        verify(mockSecureStorage.delete(key: AppConstants.userDataKey)).called(1);
        verify(mockSecureStorage.delete(key: AppConstants.basketKey)).called(1);
      });
    });

    group('token management', () {
      test('should save auth token to secure storage', () async {
        // Arrange
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await authRepository.saveAuthToken(testToken);

        // Assert
        verify(mockSecureStorage.write(
          key: AppConstants.authTokenKey,
          value: testToken,
        )).called(1);
      });

      test('should get auth token from secure storage', () async {
        // Arrange
        when(mockSecureStorage.read(key: AppConstants.authTokenKey))
            .thenAnswer((_) async => testToken);

        // Act
        final result = await authRepository.getAuthToken();

        // Assert
        expect(result, testToken);
        verify(mockSecureStorage.read(key: AppConstants.authTokenKey)).called(1);
      });

      test('should clear auth token from secure storage', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await authRepository.clearAuthToken();

        // Assert
        verify(mockSecureStorage.delete(key: AppConstants.authTokenKey)).called(1);
      });

      test('should handle secure storage errors gracefully', () async {
        // Arrange
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenThrow(Exception('Storage error'));

        // Act
        final result = await authRepository.getAuthToken();

        // Assert
        expect(result, null);
      });
    });
  });
}