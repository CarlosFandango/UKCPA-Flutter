import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/course_session.dart';
import 'package:ukcpa_flutter/domain/repositories/course_repository.dart';
import 'package:ukcpa_flutter/presentation/providers/course_provider.dart';

import 'course_provider_test.mocks.dart';

@GenerateMocks([CourseRepository])
void main() {
  group('Course Provider Tests', () {
    late MockCourseRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockCourseRepository();
      container = ProviderContainer(
        overrides: [
          courseRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('courseSearchProvider', () {
      test('should initialize with empty state', () {
        // Act
        final state = container.read(courseSearchProvider);

        // Assert
        expect(state.courses.isEmpty, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.hasMore, isFalse);
        expect(state.error, isNull);
        expect(state.totalCount, equals(0));
      });

      test('should search courses successfully', () async {
        // Arrange
        final testCourses = [
          Course(
            id: '1',
            name: 'Ballet Basics',
            price: 120,
            level: Level.beginner,
            danceType: DanceType.ballet,
            active: true,
            displayStatus: DisplayStatus.published,
            attendanceTypes: [AttendanceType.adults],
            startDateTime: DateTime.now().add(const Duration(days: 7)),
            endDateTime: DateTime.now().add(const Duration(days: 90)),
          ),
        ];

        final searchResult = CourseSearchResult(
          courses: testCourses,
          totalCount: 1,
          hasMore: false,
          filters: const CourseSearchFilters(),
        );

        when(mockRepository.getCourses(filters: anyNamed('filters')))
            .thenAnswer((_) async => searchResult);

        // Act
        await container.read(courseSearchProvider.notifier).searchCourses();

        // Assert
        final state = container.read(courseSearchProvider);
        expect(state.courses.length, equals(1));
        expect(state.courses.first.name, equals('Ballet Basics'));
        expect(state.isLoading, isFalse);
        expect(state.hasMore, isFalse);
        expect(state.totalCount, equals(1));
        expect(state.error, isNull);
      });

      test('should handle search errors', () async {
        // Arrange
        when(mockRepository.getCourses(filters: anyNamed('filters')))
            .thenThrow(Exception('Network error'));

        // Act
        await container.read(courseSearchProvider.notifier).searchCourses();

        // Assert
        final state = container.read(courseSearchProvider);
        expect(state.courses.isEmpty, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
        expect(state.error, contains('Network error'));
      });

      test('should load more courses correctly', () async {
        // Arrange
        final initialCourses = [
          Course(
            id: '1',
            name: 'Course 1',
            price: 100,
            level: Level.beginner,
            danceType: DanceType.ballet,
            active: true,
            displayStatus: DisplayStatus.published,
            attendanceTypes: [AttendanceType.adults],
            startDateTime: DateTime.now().add(const Duration(days: 7)),
            endDateTime: DateTime.now().add(const Duration(days: 90)),
          ),
        ];

        final moreCourses = [
          Course(
            id: '2',
            name: 'Course 2',
            price: 120,
            level: Level.beginner,
            danceType: DanceType.ballet,
            active: true,
            displayStatus: DisplayStatus.published,
            attendanceTypes: [AttendanceType.adults],
            startDateTime: DateTime.now().add(const Duration(days: 7)),
            endDateTime: DateTime.now().add(const Duration(days: 90)),
          ),
        ];

        // Initial search
        when(mockRepository.getCourses(filters: anyNamed('filters')))
            .thenAnswer((_) async => CourseSearchResult(
              courses: initialCourses,
              totalCount: 2,
              hasMore: true,
              filters: const CourseSearchFilters(),
            ));

        await container.read(courseSearchProvider.notifier).searchCourses();

        // Load more
        when(mockRepository.getCourses(filters: anyNamed('filters')))
            .thenAnswer((_) async => CourseSearchResult(
              courses: moreCourses,
              totalCount: 2,
              hasMore: false,
              filters: const CourseSearchFilters(),
            ));

        // Act
        await container.read(courseSearchProvider.notifier).loadMore();

        // Assert
        final state = container.read(courseSearchProvider);
        expect(state.courses.length, equals(2));
        expect(state.courses[0].name, equals('Course 1'));
        expect(state.courses[1].name, equals('Course 2'));
        expect(state.hasMore, isFalse);
      });

      test('should update filters and search', () async {
        // Arrange
        final filters = CourseSearchFilters(
          searchTerm: 'ballet',
          danceTypes: [DanceType.ballet],
        );

        final searchResult = CourseSearchResult(
          courses: [],
          totalCount: 0,
          hasMore: false,
          filters: filters,
        );

        when(mockRepository.getCourses(filters: anyNamed('filters')))
            .thenAnswer((_) async => searchResult);

        // Act
        await container.read(courseSearchProvider.notifier).updateFilters(filters);

        // Assert
        final state = container.read(courseSearchProvider);
        expect(state.filters.searchTerm, equals('ballet'));
        expect(state.filters.danceTypes, contains(DanceType.ballet));
        verify(mockRepository.getCourses(filters: anyNamed('filters'))).called(1);
      });

      test('should clear search results', () async {
        // Arrange - setup initial state with data
        final searchResult = CourseSearchResult(
          courses: [
            Course(
              id: '1',
              name: 'Test Course',
              price: 100,
              level: Level.beginner,
              danceType: DanceType.ballet,
              active: true,
              displayStatus: DisplayStatus.published,
              attendanceTypes: [AttendanceType.adults],
              startDateTime: DateTime.now().add(const Duration(days: 7)),
              endDateTime: DateTime.now().add(const Duration(days: 90)),
            ),
          ],
          totalCount: 1,
          hasMore: false,
          filters: const CourseSearchFilters(),
        );

        when(mockRepository.getCourses(filters: anyNamed('filters')))
            .thenAnswer((_) async => searchResult);

        await container.read(courseSearchProvider.notifier).searchCourses();

        // Act
        container.read(courseSearchProvider.notifier).clearSearch();

        // Assert
        final state = container.read(courseSearchProvider);
        expect(state.courses.isEmpty, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.hasMore, isFalse);
        expect(state.totalCount, equals(0));
      });

      test('should refresh courses', () async {
        // Arrange
        when(mockRepository.refreshCourses()).thenAnswer((_) async {});
        when(mockRepository.getCourses(filters: anyNamed('filters')))
            .thenAnswer((_) async => const CourseSearchResult(
              courses: [],
              totalCount: 0,
              hasMore: false,
              filters: CourseSearchFilters(),
            ));

        // Act
        await container.read(courseSearchProvider.notifier).refresh();

        // Assert
        verify(mockRepository.refreshCourses()).called(1);
        verify(mockRepository.getCourses(filters: anyNamed('filters'))).called(1);
      });
    });

    group('courseProvider', () {
      test('should fetch course successfully', () async {
        // Arrange
        final testCourse = Course(
          id: '1',
          name: 'Ballet Basics',
          price: 120,
          level: Level.beginner,
          danceType: DanceType.ballet,
          active: true,
          displayStatus: DisplayStatus.published,
          attendanceTypes: [AttendanceType.adults],
          startDateTime: DateTime.now().add(const Duration(days: 7)),
          endDateTime: DateTime.now().add(const Duration(days: 90)),
        );

        when(mockRepository.getCourse('1')).thenAnswer((_) async => testCourse);

        // Act
        final result = await container.read(courseProvider('1').future);

        // Assert
        expect(result, isNotNull);
        expect(result!.name, equals('Ballet Basics'));
        expect(result.id, equals('1'));
        verify(mockRepository.getCourse('1')).called(1);
      });

      test('should return null for non-existent course', () async {
        // Arrange
        when(mockRepository.getCourse('999')).thenAnswer((_) async => null);

        // Act
        final result = await container.read(courseProvider('999').future);

        // Assert
        expect(result, isNull);
        verify(mockRepository.getCourse('999')).called(1);
      });

      test('should handle course fetch errors', () async {
        // Arrange
        when(mockRepository.getCourse('1'))
            .thenThrow(CourseRepositoryException(message: 'Network error'));

        // Act & Assert
        expect(
          () => container.read(courseProvider('1').future),
          throwsA(isA<CourseRepositoryException>()),
        );
      });
    });

    group('courseGroupsProvider', () {
      test('should fetch course groups successfully', () async {
        // Arrange
        final testGroups = [
          CourseGroup(
            id: 'group1',
            name: 'Ballet Fundamentals',
            active: true,
            courses: [],
            attendanceTypes: [],
          ),
          CourseGroup(
            id: 'group2',
            name: 'Hip Hop Basics',
            active: true,
            courses: [],
            attendanceTypes: [],
          ),
        ];

        when(mockRepository.getCourseGroups()).thenAnswer((_) async => testGroups);

        // Act
        final result = await container.read(courseGroupsProvider.future);

        // Assert
        expect(result.length, equals(2));
        expect(result[0].name, equals('Ballet Fundamentals'));
        expect(result[1].name, equals('Hip Hop Basics'));
        verify(mockRepository.getCourseGroups()).called(1);
      });

      test('should return empty list when no groups exist', () async {
        // Arrange
        when(mockRepository.getCourseGroups()).thenAnswer((_) async => []);

        // Act
        final result = await container.read(courseGroupsProvider.future);

        // Assert
        expect(result.isEmpty, isTrue);
        verify(mockRepository.getCourseGroups()).called(1);
      });
    });

    group('courseSessionsProvider', () {
      test('should fetch course sessions successfully', () async {
        // Arrange
        final testSessions = [
          CourseSession(
            id: 'session1',
            courseId: 'course1',
            startDateTime: DateTime.now().add(const Duration(days: 1)),
            endDateTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
            sessionTitle: 'Session 1',
            isCancelled: false,
          ),
        ];

        when(mockRepository.getCourseSessions('course1'))
            .thenAnswer((_) async => testSessions);

        // Act
        final result = await container.read(courseSessionsProvider('course1').future);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.sessionTitle, equals('Session 1'));
        verify(mockRepository.getCourseSessions('course1')).called(1);
      });
    });

    group('featuredCoursesProvider', () {
      test('should fetch featured courses with limit', () async {
        // Arrange
        final testCourses = [
          Course(
            id: '1',
            name: 'Featured Course',
            price: 150,
            level: Level.intermediate,
            danceType: DanceType.ballet,
            active: true,
            displayStatus: DisplayStatus.published,
            attendanceTypes: [AttendanceType.adults],
            startDateTime: DateTime.now().add(const Duration(days: 7)),
            endDateTime: DateTime.now().add(const Duration(days: 90)),
          ),
        ];

        when(mockRepository.getFeaturedCourses(limit: 5))
            .thenAnswer((_) async => testCourses);

        // Act
        final result = await container.read(featuredCoursesProvider(5).future);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.name, equals('Featured Course'));
        verify(mockRepository.getFeaturedCourses(limit: 5)).called(1);
      });
    });

    group('courseFilterOptionsProvider', () {
      test('should fetch filter options successfully', () async {
        // Arrange
        final testOptions = CourseFilterOptions(
          availableDanceTypes: [DanceType.ballet, DanceType.hiphop],
          availableLevels: [Level.beginner, Level.intermediate],
          availableLocations: [Location.studio, Location.online],
          availableAttendanceTypes: [AttendanceType.adults, AttendanceType.children],
          minPrice: 50,
          maxPrice: 300,
          minAge: 5,
          maxAge: 65,
        );

        when(mockRepository.getFilterOptions()).thenAnswer((_) async => testOptions);

        // Act
        final result = await container.read(courseFilterOptionsProvider.future);

        // Assert
        expect(result.availableDanceTypes.length, equals(2));
        expect(result.availableLevels.length, equals(2));
        expect(result.minPrice, equals(50));
        expect(result.maxPrice, equals(300));
        verify(mockRepository.getFilterOptions()).called(1);
      });
    });

    group('courseFavoritesProvider', () {
      test('should initialize with empty favorites', () {
        // Act
        final state = container.read(courseFavoritesProvider);

        // Assert
        expect(state.favoriteIds.isEmpty, isTrue);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });

      test('should toggle favorite status', () async {
        // Act
        await container.read(courseFavoritesProvider.notifier).toggleFavorite('course1');

        // Assert
        final state = container.read(courseFavoritesProvider);
        expect(state.favoriteIds.contains('course1'), isTrue);

        // Toggle again
        await container.read(courseFavoritesProvider.notifier).toggleFavorite('course1');
        final updatedState = container.read(courseFavoritesProvider);
        expect(updatedState.favoriteIds.contains('course1'), isFalse);
      });

      test('should check if course is favorite', () async {
        // Arrange
        await container.read(courseFavoritesProvider.notifier).toggleFavorite('course1');

        // Act
        final state = container.read(courseFavoritesProvider);

        // Assert
        expect(state.isFavorite('course1'), isTrue);
        expect(state.isFavorite('course2'), isFalse);
      });
    });

    group('parameter classes', () {
      test('CoursesByDanceTypeParams should compare correctly', () {
        // Arrange
        const params1 = CoursesByDanceTypeParams(danceType: DanceType.ballet);
        const params2 = CoursesByDanceTypeParams(danceType: DanceType.ballet);
        const params3 = CoursesByDanceTypeParams(danceType: DanceType.hiphop);

        // Assert
        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('CoursesByLevelParams should compare correctly', () {
        // Arrange
        const params1 = CoursesByLevelParams(level: Level.beginner);
        const params2 = CoursesByLevelParams(level: Level.beginner);
        const params3 = CoursesByLevelParams(level: Level.intermediate);

        // Assert
        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('CoursesForAgeParams should compare correctly', () {
        // Arrange
        const params1 = CoursesForAgeParams(age: 25);
        const params2 = CoursesForAgeParams(age: 25);
        const params3 = CoursesForAgeParams(age: 30);

        // Assert
        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
        expect(params1.hashCode, equals(params2.hashCode));
      });
    });
  });
}