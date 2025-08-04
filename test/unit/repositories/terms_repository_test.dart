import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:ukcpa_flutter/data/repositories/terms_repository_impl.dart';
import 'package:ukcpa_flutter/domain/entities/term.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';

// Generate mocks
@GenerateMocks([GraphQLClient])
import 'terms_repository_test.mocks.dart';

void main() {
  group('TermsRepositoryImpl', () {
    late MockGraphQLClient mockClient;
    late TermsRepositoryImpl repository;

    setUp(() {
      mockClient = MockGraphQLClient();
      repository = TermsRepositoryImpl(mockClient);
    });

    group('getTerms', () {
      test('should return terms when query succeeds', () async {
        // Mock successful response
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [
                {
                  'id': 1,
                  'name': 'Spring 2025',
                  'startDate': '2025-01-15T00:00:00.000Z',
                  'endDate': '2025-04-15T00:00:00.000Z',
                  'holidays': [],
                  'courseGroups': [],
                }
              ],
              'term': null,
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        final result = await repository.getTerms(displayStatus: 'Live');

        expect(result, hasLength(1));
        expect(result[0].id, equals(1));
        expect(result[0].name, equals('Spring 2025'));
      });

      test('should handle both terms array and single term', () async {
        // Mock response with both terms array and single term
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [
                {
                  'id': 1,
                  'name': 'Spring 2025',
                  'startDate': '2025-01-15T00:00:00.000Z',
                  'endDate': '2025-04-15T00:00:00.000Z',
                  'holidays': [],
                  'courseGroups': [],
                }
              ],
              'term': {
                'id': 2,
                'name': 'Summer 2025',
                'startDate': '2025-05-15T00:00:00.000Z',
                'endDate': '2025-08-15T00:00:00.000Z',
                'holidays': [],
                'courseGroups': [],
              },
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        final result = await repository.getTerms(displayStatus: 'Live');

        expect(result, hasLength(2));
        expect(result[0].name, equals('Spring 2025'));
        expect(result[1].name, equals('Summer 2025'));
      });

      test('should not duplicate terms if single term is already in terms array', () async {
        // Mock response where single term is same as one in terms array
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [
                {
                  'id': 1,
                  'name': 'Spring 2025',
                  'startDate': '2025-01-15T00:00:00.000Z',
                  'endDate': '2025-04-15T00:00:00.000Z',
                  'holidays': [],
                  'courseGroups': [],
                }
              ],
              'term': {
                'id': 1, // Same ID as in terms array
                'name': 'Spring 2025',
                'startDate': '2025-01-15T00:00:00.000Z',
                'endDate': '2025-04-15T00:00:00.000Z',
                'holidays': [],
                'courseGroups': [],
              },
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        final result = await repository.getTerms(displayStatus: 'Live');

        expect(result, hasLength(1)); // Should not duplicate
        expect(result[0].name, equals('Spring 2025'));
      });

      test('should parse terms with holidays and course groups', () async {
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [
                {
                  'id': 1,
                  'name': 'Spring 2025',
                  'startDate': '2025-01-15T00:00:00.000Z',
                  'endDate': '2025-04-15T00:00:00.000Z',
                  'holidays': [
                    {
                      'name': 'Spring Break',
                      'startDateTime': '2025-03-01T00:00:00.000Z',
                      'endDateTime': '2025-03-08T00:00:00.000Z',
                    }
                  ],
                  'courseGroups': [
                    {
                      'id': 1,
                      'name': 'Ballet Basics',
                      'thumbImage': null,
                      'image': null,
                      'imagePosition': null,
                      'shortDescription': 'Introduction to ballet',
                      'description': null,
                      'minOriginalPrice': null,
                      'maxOriginalPrice': null,
                      'minPrice': 2000,
                      'maxPrice': 3000,
                      'attendanceTypes': ['adults'],
                      'locations': ['studio1'],
                      'danceType': 'BALLET',
                      'courseTypes': ['StudioCourse'],
                      'courses': [],
                    }
                  ],
                }
              ],
              'term': null,
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        final result = await repository.getTerms(displayStatus: 'Live');

        expect(result, hasLength(1));
        final term = result[0];
        expect(term.holidays, hasLength(1));
        expect(term.holidays[0].name, equals('Spring Break'));
        expect(term.courseGroups, hasLength(1));
        expect(term.courseGroups[0].name, equals('Ballet Basics'));
      });

      test('should throw RepositoryException when query fails', () async {
        final mockResult = QueryResult(
          data: null,
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
          exception: OperationException(),
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        expect(
          () => repository.getTerms(displayStatus: 'Live'),
          throwsA(isA<RepositoryException>()),
        );
      });

      test('should use cache when valid', () async {
        // First call - should hit network
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [
                {
                  'id': 1,
                  'name': 'Spring 2025',
                  'startDate': '2025-01-15T00:00:00.000Z',
                  'endDate': '2025-04-15T00:00:00.000Z',
                  'holidays': [],
                  'courseGroups': [],
                }
              ],
              'term': null,
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        // First call
        final result1 = await repository.getTerms(displayStatus: 'Live');
        expect(result1, hasLength(1));

        // Second call immediately - should use cache
        final result2 = await repository.getTerms(displayStatus: 'Live');
        expect(result2, hasLength(1));

        // Verify network was only called once
        verify(mockClient.query(any)).called(1);
      });

      test('should not use cache for different display status', () async {
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [],
              'term': null,
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        // First call with 'Live'
        await repository.getTerms(displayStatus: 'Live');
        
        // Second call with 'Draft' - should hit network again
        await repository.getTerms(displayStatus: 'Draft');

        // Verify network was called twice
        verify(mockClient.query(any)).called(2);
      });
    });

    group('getCourseGroup', () {
      test('should return course group when found', () async {
        final mockResult = QueryResult(
          data: {
            'getCourseGroup': {
              'id': 1,
              'name': 'Ballet Basics',
              'thumbImage': null,
              'image': null,
              'imagePosition': null,
              'shortDescription': 'Introduction to ballet',
              'description': null,
              'minOriginalPrice': null,
              'maxOriginalPrice': null,
              'minPrice': 2000,
              'maxPrice': 3000,
              'attendanceTypes': ['adults'],
              'locations': ['studio1'],
              'danceType': 'BALLET',
              'courseTypes': ['StudioCourse'],
              'courses': [],
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        final result = await repository.getCourseGroup(1);

        expect(result, isNotNull);
        expect(result!.id, equals(1));
        expect(result.name, equals('Ballet Basics'));
      });

      test('should return null when course group not found', () async {
        final mockResult = QueryResult(
          data: {'getCourseGroup': null},
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        final result = await repository.getCourseGroup(999);

        expect(result, isNull);
      });

      test('should include displayStatus in variables when provided', () async {
        final mockResult = QueryResult(
          data: {'getCourseGroup': null},
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        await repository.getCourseGroup(1, displayStatus: 'Draft');

        final captured = verify(mockClient.query(captureAny)).captured.single as QueryOptions;
        expect(captured.variables['displayStatus'], equals('Draft'));
      });
    });

    group('cache management', () {
      test('clearCache should clear cached data', () async {
        // Setup cache with data
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [
                {
                  'id': 1,
                  'name': 'Spring 2025',
                  'startDate': '2025-01-15T00:00:00.000Z',
                  'endDate': '2025-04-15T00:00:00.000Z',
                  'holidays': [],
                  'courseGroups': [],
                }
              ],
              'term': null,
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        // First call to populate cache
        await repository.getTerms(displayStatus: 'Live');
        
        // Clear cache
        await repository.clearCache();
        
        // Next call should hit network again
        await repository.getTerms(displayStatus: 'Live');

        // Verify network was called twice
        verify(mockClient.query(any)).called(2);
      });

      test('refreshTerms should clear cache and fetch fresh data', () async {
        final mockResult = QueryResult(
          data: {
            'getTerms': {
              'terms': [],
              'term': null,
            }
          },
          options: QueryOptions(document: gql('')),
          source: QueryResultSource.network,
        );

        when(mockClient.query(any)).thenAnswer((_) async => mockResult);

        // First call to populate cache
        await repository.getTerms(displayStatus: 'Live');
        
        // Refresh should clear cache and fetch fresh data
        await repository.refreshTerms(displayStatus: 'Live');

        // Verify network was called twice
        verify(mockClient.query(any)).called(2);
      });
    });
  });
}