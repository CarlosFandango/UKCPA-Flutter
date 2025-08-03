import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ukcpa_flutter/data/repositories/course_repository_impl.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/course_session.dart';
import 'package:ukcpa_flutter/domain/repositories/course_repository.dart';

import 'course_repository_impl_test.mocks.dart';

@GenerateMocks([GraphQLClient])
void main() {
  group('CourseRepositoryImpl Tests', () {
    late CourseRepositoryImpl repository;
    late MockGraphQLClient mockClient;

    setUp(() {
      mockClient = MockGraphQLClient();
      repository = CourseRepositoryImpl(client: mockClient);
    });

    group('getCourses', () {
      test('should return courses successfully', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'courses': {
              'items': [
                {
                  '__typename': 'StudioCourse',
                  'id': '1',
                  'name': 'Ballet Basics',
                  'price': 120,
                  'level': 'BEGINNER',
                  'danceType': 'BALLET',
                  'active': true,
                  'displayStatus': 'PUBLISHED',
                  'attendanceTypes': ['ADULTS'],
                  'startDateTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
                  'endDateTime': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
                  'ageFrom': 16,
                  'ageTo': 65,
                  'location': 'STUDIO',
                  'sessions': [],
                  'futureCourseSessions': [],
                  'videos': [],
                },
              ],
              'totalCount': 1,
              'hasMore': false,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCourses();

        // Assert
        expect(result.courses.length, equals(1));
        expect(result.courses.first.name, equals('Ballet Basics'));
        expect(result.totalCount, equals(1));
        expect(result.hasMore, isFalse);
        verify(mockClient.query(any)).called(1);
      });

      test('should handle GraphQL errors', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: null,
          exception: OperationException(
            graphqlErrors: [
              GraphQLError(message: 'Server error'),
            ],
          ),
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () async => await repository.getCourses(),
          throwsA(isA<CourseRepositoryException>()),
        );
        verify(mockClient.query(any)).called(1);
      });

      test('should apply search filters correctly', () async {
        // Arrange
        final filters = CourseSearchFilters(
          searchTerm: 'ballet',
          danceTypes: [DanceType.ballet],
          levels: [Level.beginner],
          minPrice: 50,
          maxPrice: 200,
          availableOnly: true,
          limit: 10,
          offset: 0,
        );

        final mockResponse = QueryResult(
          data: {
            'courses': {
              'items': [],
              'totalCount': 0,
              'hasMore': false,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        await repository.getCourses(filters: filters);

        // Assert
        final capturedCall = verify(mockClient.query(captureAny)).captured.first as QueryOptions;
        final variables = capturedCall.variables;
        
        expect(variables['searchTerm'], equals('ballet'));
        expect(variables['danceTypes'], equals(['BALLET']));
        expect(variables['levels'], equals(['BEGINNER']));
        expect(variables['minPrice'], equals(50));
        expect(variables['maxPrice'], equals(200));
        expect(variables['availableOnly'], isTrue);
        expect(variables['limit'], equals(10));
        expect(variables['offset'], equals(0));
      });

      test('should handle invalid data format', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {'courses': null},
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () async => await repository.getCourses(),
          throwsA(isA<InvalidCourseDataException>()),
        );
      });
    });

    group('getCourse', () {
      test('should return studio course successfully', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'course': {
              '__typename': 'StudioCourse',
              'id': '1',
              'name': 'Ballet Basics',
              'price': 120,
              'level': 'BEGINNER',
              'danceType': 'BALLET',
              'active': true,
              'displayStatus': 'PUBLISHED',
              'attendanceTypes': ['ADULTS'],
              'startDateTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'endDateTime': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
              'ageFrom': 16,
              'ageTo': 65,
              'location': 'STUDIO',
              'sessions': [],
              'futureCourseSessions': [],
              'videos': [],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCourse('1');

        // Assert
        expect(result, isNotNull);
        expect(result, isA<StudioCourse>());
        expect(result!.name, equals('Ballet Basics'));
        expect(result.id, equals('1'));
        verify(mockClient.query(any)).called(1);
      });

      test('should return online course successfully', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'course': {
              '__typename': 'OnlineCourse',
              'id': '2',
              'name': 'Online Ballet',
              'price': 80,
              'level': 'BEGINNER',
              'danceType': 'BALLET',
              'active': true,
              'displayStatus': 'PUBLISHED',  
              'attendanceTypes': ['ADULTS'],
              'startDateTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'endDateTime': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
              'ageFrom': 16,
              'ageTo': 65,
              'location': 'ONLINE',
              'sessions': [],
              'futureCourseSessions': [],
              'videos': [],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCourse('2');

        // Assert
        expect(result, isNotNull);
        expect(result, isA<OnlineCourse>());
        expect(result!.name, equals('Online Ballet'));
        expect(result.id, equals('2'));
      });

      test('should return null for non-existent course', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {'course': null},
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCourse('999');

        // Assert
        expect(result, isNull);
        verify(mockClient.query(any)).called(1);
      });
    });

    group('getStudioCourse', () {
      test('should return studio course when course is studio type', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'course': {
              '__typename': 'StudioCourse',
              'id': '1',
              'name': 'Ballet Basics',
              'price': 120,
              'level': 'BEGINNER',
              'danceType': 'BALLET',
              'active': true,
              'displayStatus': 'PUBLISHED',
              'attendanceTypes': ['ADULTS'],
              'startDateTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'endDateTime': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
              'ageFrom': 16,
              'ageTo': 65,
              'location': 'STUDIO',
              'sessions': [],
              'futureCourseSessions': [],
              'videos': [],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getStudioCourse('1');

        // Assert
        expect(result, isNotNull);
        expect(result, isA<StudioCourse>());
        expect(result!.name, equals('Ballet Basics'));
      });

      test('should return null when course is online type', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'course': {
              '__typename': 'OnlineCourse',
              'id': '2',
              'name': 'Online Ballet',
              'price': 80,
              'level': 'BEGINNER',
              'danceType': 'BALLET',
              'active': true,
              'displayStatus': 'PUBLISHED',
              'attendanceTypes': ['ADULTS'],
              'startDateTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'endDateTime': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
              'ageFrom': 16,
              'ageTo': 65,
              'location': 'ONLINE',
              'sessions': [],
              'futureCourseSessions': [],
              'videos': [],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getStudioCourse('2');

        // Assert
        expect(result, isNull);
      });
    });

    group('getOnlineCourse', () {
      test('should return online course when course is online type', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'course': {
              '__typename': 'OnlineCourse',
              'id': '2',
              'name': 'Online Ballet',
              'price': 80,
              'level': 'BEGINNER',
              'danceType': 'BALLET',
              'active': true,
              'displayStatus': 'PUBLISHED',
              'attendanceTypes': ['ADULTS'],
              'startDateTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'endDateTime': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
              'ageFrom': 16,
              'ageTo': 65,
              'location': 'ONLINE',
              'sessions': [],
              'futureCourseSessions': [],
              'videos': [],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getOnlineCourse('2');

        // Assert
        expect(result, isNotNull);
        expect(result, isA<OnlineCourse>());
        expect(result!.name, equals('Online Ballet'));
      });

      test('should return null when course is studio type', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'course': {
              '__typename': 'StudioCourse',
              'id': '1', 
              'name': 'Ballet Basics',
              'price': 120,
              'level': 'BEGINNER',
              'danceType': 'BALLET',
              'active': true,
              'displayStatus': 'PUBLISHED',
              'attendanceTypes': ['ADULTS'],
              'startDateTime': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'endDateTime': DateTime.now().add(const Duration(days: 90)).toIso8601String(),
              'ageFrom': 16,
              'ageTo': 65,
              'location': 'STUDIO',
              'sessions': [],
              'futureCourseSessions': [],
              'videos': [],
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getOnlineCourse('1');

        // Assert
        expect(result, isNull);
      });
    });

    group('getCourseGroups', () {
      test('should return course groups successfully', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'courseGroups': [
              {
                'id': 'group1',
                'name': 'Ballet Fundamentals',
                'active': true,
                'courses': [],
                'attendanceTypes': [],
              }
            ]
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCourseGroups();

        // Assert
        expect(result.length, equals(1));
        expect(result.first.name, equals('Ballet Fundamentals'));
        verify(mockClient.query(any)).called(1);
      });

      test('should return empty list when no groups exist', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {'courseGroups': []},
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCourseGroups();

        // Assert
        expect(result.isEmpty, isTrue);
      });
    });

    group('getCourseSessions', () {
      test('should return course sessions successfully', () async {
        // Arrange
        final sessionDateTime = DateTime.now().add(const Duration(days: 1));
        final mockResponse = QueryResult(
          data: {
            'courseSessions': [
              {
                'id': 'session1',
                'courseId': 'course1',
                'startDateTime': sessionDateTime.toIso8601String(),
                'endDateTime': sessionDateTime.add(const Duration(hours: 1)).toIso8601String(),
                'sessionTitle': 'Ballet Session 1',
                'isCancelled': false,
              }
            ]
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCourseSessions('course1');

        // Assert
        expect(result.length, equals(1));
        expect(result.first.sessionTitle, equals('Ballet Session 1'));
        verify(mockClient.query(any)).called(1);
      });
    });

    group('searchCourses', () {
      test('should search courses with query term', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'courses': {
              'items': [],
              'totalCount': 0,
              'hasMore': false,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        await repository.searchCourses('ballet');

        // Assert
        final capturedCall = verify(mockClient.query(captureAny)).captured.first as QueryOptions;
        final variables = capturedCall.variables;
        expect(variables['searchTerm'], equals('ballet'));
      });
    });

    group('getFeaturedCourses', () {
      test('should return featured courses with correct sorting', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'courses': {
              'items': [],
              'totalCount': 0,
              'hasMore': false,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        await repository.getFeaturedCourses(limit: 5);

        // Assert
        final capturedCall = verify(mockClient.query(captureAny)).captured.first as QueryOptions;
        final variables = capturedCall.variables;
        expect(variables['limit'], equals(5));
        expect(variables['sortBy'], equals('POPULARITY'));
        expect(variables['sortOrder'], equals('DESCENDING'));
      });
    });

    group('getFilterOptions', () {
      test('should return filter options successfully', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'courseFilterOptions': {
              'availableDanceTypes': ['BALLET', 'HIPHOP'],
              'availableLevels': ['BEGINNER', 'INTERMEDIATE'],
              'availableLocations': ['STUDIO', 'ONLINE'],
              'availableAttendanceTypes': ['ADULTS', 'CHILDREN'],
              'minPrice': 50,
              'maxPrice': 300,
              'minAge': 5,
              'maxAge': 65,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getFilterOptions();

        // Assert
        expect(result.availableDanceTypes.length, equals(2));
        expect(result.availableLevels.length, equals(2));
        expect(result.minPrice, equals(50));
        expect(result.maxPrice, equals(300));
        expect(result.minAge, equals(5));
        expect(result.maxAge, equals(65));
        verify(mockClient.query(any)).called(1);
      });

      test('should cache filter options', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: {
            'courseFilterOptions': {
              'availableDanceTypes': ['BALLET'],
              'availableLevels': ['BEGINNER'],
              'availableLocations': ['STUDIO'],
              'availableAttendanceTypes': ['ADULTS'],
              'minPrice': 50,
              'maxPrice': 300,
              'minAge': 5,
              'maxAge': 65,
            }
          },
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act
        await repository.getFilterOptions();
        await repository.getFilterOptions(); // Second call should use cache

        // Assert
        verify(mockClient.query(any)).called(1); // Only called once due to caching
      });
    });

    group('cache management', () {
      test('should clear cache successfully', () async {
        // Act
        await repository.clearCache();

        // Assert - should not throw any exceptions
        expect(true, isTrue);
      });

      test('should return cached courses', () async {
        // Act
        final cachedCourses = await repository.getCachedCourses();

        // Assert
        expect(cachedCourses, isA<List<Course>>());
      });

      test('should check if data is stale', () async {
        // Act
        final isStale = await repository.isDataStale();

        // Assert
        expect(isStale, isA<bool>());
      });
    });

    group('error handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        final mockResponse = QueryResult(
          data: null,
          exception: OperationException(
            linkException: NetworkException(
              message: 'Network error',
              uri: Uri.parse('http://test.com'),
              originalException: Exception('Connection failed'),
            ),
          ),
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () async => await repository.getCourses(),
          throwsA(isA<CourseRepositoryException>()),
        );
      });

      test('should wrap unknown errors in CourseRepositoryException', () async {
        // Arrange
        when(mockClient.query(any)).thenThrow(Exception('Unknown error'));

        // Act & Assert
        expect(
          () async => await repository.getCourses(),
          throwsA(isA<CourseRepositoryException>()),
        );
      });
    });
  });
}