import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart' as log;
import '../../domain/entities/course.dart';
import '../../domain/entities/course_group.dart';
import '../../domain/entities/course_session.dart';
import '../../domain/repositories/course_repository.dart';
import '../../data/repositories/course_repository_impl.dart';

final log.Logger _logger = log.Logger();

// Repository provider
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepositoryImpl();
});

// Course search state
class CourseSearchState {
  final List<Course> courses;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final CourseSearchFilters filters;
  final int totalCount;

  const CourseSearchState({
    this.courses = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error,
    this.filters = const CourseSearchFilters(),
    this.totalCount = 0,
  });

  CourseSearchState copyWith({
    List<Course>? courses,
    bool? isLoading,
    bool? hasMore,
    String? error,
    CourseSearchFilters? filters,
    int? totalCount,
  }) {
    return CourseSearchState(
      courses: courses ?? this.courses,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filters: filters ?? this.filters,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// Course search notifier
class CourseSearchNotifier extends StateNotifier<CourseSearchState> {
  final CourseRepository _repository;

  CourseSearchNotifier(this._repository) : super(const CourseSearchState());

  /// Search courses with filters
  Future<void> searchCourses({
    CourseSearchFilters? filters,
    bool append = false,
  }) async {
    try {
      if (!append) {
        state = state.copyWith(
          isLoading: true,
          error: null,
        );
      }

      final searchFilters = filters ?? state.filters;
      final result = await _repository.getCourses(filters: searchFilters);

      final newCourses = append 
          ? [...state.courses, ...result.courses]
          : result.courses;

      state = state.copyWith(
        courses: newCourses,
        isLoading: false,
        hasMore: result.hasMore,
        filters: searchFilters,
        totalCount: result.totalCount,
      );

      _logger.d('Course search completed: ${newCourses.length} courses');
    } catch (e) {
      _logger.e('Error searching courses: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more courses (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    final nextFilters = state.filters.copyWith(
      offset: state.courses.length,
    );

    await searchCourses(filters: nextFilters, append: true);
  }

  /// Clear search results
  void clearSearch() {
    state = const CourseSearchState();
  }

  /// Update filters and search
  Future<void> updateFilters(CourseSearchFilters filters) async {
    await searchCourses(filters: filters);
  }

  /// Refresh courses
  Future<void> refresh() async {
    await _repository.refreshCourses();
    await searchCourses(filters: state.filters);
  }
}

// Course search provider
final courseSearchProvider = StateNotifierProvider<CourseSearchNotifier, CourseSearchState>((ref) {
  final repository = ref.watch(courseRepositoryProvider);
  return CourseSearchNotifier(repository);
});

// Individual course provider
final courseProvider = FutureProvider.family<Course?, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final course = await repository.getCourse(courseId);
    _logger.d('Fetched course: ${course?.name}');
    return course;
  } catch (e) {
    _logger.e('Error fetching course $courseId: $e');
    throw e;
  }
});

// Course groups provider
final courseGroupsProvider = FutureProvider<List<CourseGroup>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final groups = await repository.getCourseGroups();
    _logger.d('Fetched ${groups.length} course groups');
    return groups;
  } catch (e) {
    _logger.e('Error fetching course groups: $e');
    throw e;
  }
});

// Individual course group provider
final courseGroupProvider = FutureProvider.family<CourseGroup?, String>((ref, groupId) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final group = await repository.getCourseGroup(groupId);
    _logger.d('Fetched course group: ${group?.name}');
    return group;
  } catch (e) {
    _logger.e('Error fetching course group $groupId: $e');
    throw e;
  }
});

// Course sessions provider
final courseSessionsProvider = FutureProvider.family<List<CourseSession>, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final sessions = await repository.getCourseSessions(courseId);
    _logger.d('Fetched ${sessions.length} sessions for course $courseId');
    return sessions;
  } catch (e) {
    _logger.e('Error fetching sessions for course $courseId: $e');
    throw e;
  }
});

// Upcoming sessions provider
final upcomingSessionsProvider = FutureProvider.family<List<CourseSession>, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final sessions = await repository.getUpcomingSessions(courseId);
    _logger.d('Fetched ${sessions.length} upcoming sessions for course $courseId');
    return sessions;
  } catch (e) {
    _logger.e('Error fetching upcoming sessions for course $courseId: $e');
    throw e;
  }
});

// Featured courses provider
final featuredCoursesProvider = FutureProvider.family<List<Course>, int?>((ref, limit) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getFeaturedCourses(limit: limit);
    _logger.d('Fetched ${courses.length} featured courses');
    return courses;
  } catch (e) {
    _logger.e('Error fetching featured courses: $e');
    throw e;
  }
});

// Popular courses provider
final popularCoursesProvider = FutureProvider.family<List<Course>, int?>((ref, limit) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getPopularCourses(limit: limit);
    _logger.d('Fetched ${courses.length} popular courses');
    return courses;
  } catch (e) {
    _logger.e('Error fetching popular courses: $e');
    throw e;
  }
});

// Courses by dance type provider
final coursesByDanceTypeProvider = FutureProvider.family<List<Course>, CoursesByDanceTypeParams>((ref, params) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getCoursesByDanceType(params.danceType, filters: params.filters);
    _logger.d('Fetched ${courses.length} courses for dance type ${params.danceType}');
    return courses;
  } catch (e) {
    _logger.e('Error fetching courses by dance type: $e');
    throw e;
  }
});

// Courses by level provider
final coursesByLevelProvider = FutureProvider.family<List<Course>, CoursesByLevelParams>((ref, params) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getCoursesByLevel(params.level, filters: params.filters);
    _logger.d('Fetched ${courses.length} courses for level ${params.level}');
    return courses;
  } catch (e) {
    _logger.e('Error fetching courses by level: $e');
    throw e;
  }
});

// Courses for age provider
final coursesForAgeProvider = FutureProvider.family<List<Course>, CoursesForAgeParams>((ref, params) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getCoursesForAge(params.age, filters: params.filters);
    _logger.d('Fetched ${courses.length} courses for age ${params.age}');
    return courses;
  } catch (e) {
    _logger.e('Error fetching courses for age: $e');
    throw e;
  }
});

// Courses with tasters provider
final coursesWithTastersProvider = FutureProvider.family<List<Course>, CourseSearchFilters?>((ref, filters) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getCoursesWithTasters(filters: filters);
    _logger.d('Fetched ${courses.length} courses with tasters');
    return courses;
  } catch (e) {
    _logger.e('Error fetching courses with tasters: $e');
    throw e;
  }
});

// Recommended courses provider
final recommendedCoursesProvider = FutureProvider.family<List<Course>, RecommendedCoursesParams>((ref, params) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getRecommendedCourses(
      preferredDanceTypes: params.preferredDanceTypes,
      preferredLevels: params.preferredLevels,
      age: params.age,
      filters: params.filters,
    );
    _logger.d('Fetched ${courses.length} recommended courses');
    return courses;
  } catch (e) {
    _logger.e('Error fetching recommended courses: $e');
    throw e;
  }
});

// Courses starting soon provider
final coursesStartingSoonProvider = FutureProvider.family<List<Course>, CoursesStartingSoonParams>((ref, params) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final courses = await repository.getCoursesStartingSoon(
      days: params.days,
      filters: params.filters,
    );
    _logger.d('Fetched ${courses.length} courses starting in ${params.days} days');
    return courses;
  } catch (e) {
    _logger.e('Error fetching courses starting soon: $e');
    throw e;
  }
});

// Filter options provider
final courseFilterOptionsProvider = FutureProvider<CourseFilterOptions>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final options = await repository.getFilterOptions();
    _logger.d('Fetched course filter options');
    return options;
  } catch (e) {
    _logger.e('Error fetching filter options: $e');
    throw e;
  }
});

// Course cache status provider
final courseCacheStatusProvider = FutureProvider<CourseCacheStatus>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  try {
    final cachedCourses = await repository.getCachedCourses();
    final isStale = await repository.isDataStale();
    
    return CourseCacheStatus(
      cachedCoursesCount: cachedCourses.length,
      isStale: isStale,
      lastUpdated: isStale ? null : DateTime.now(),
    );
  } catch (e) {
    _logger.e('Error fetching cache status: $e');
    throw e;
  }
});

// Helper classes for provider parameters
class CoursesByDanceTypeParams {
  final DanceType danceType;
  final CourseSearchFilters? filters;

  const CoursesByDanceTypeParams({
    required this.danceType,
    this.filters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursesByDanceTypeParams &&
          runtimeType == other.runtimeType &&
          danceType == other.danceType &&
          filters == other.filters;

  @override
  int get hashCode => danceType.hashCode ^ filters.hashCode;
}

class CoursesByLevelParams {
  final Level level;
  final CourseSearchFilters? filters;

  const CoursesByLevelParams({
    required this.level,
    this.filters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursesByLevelParams &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          filters == other.filters;

  @override
  int get hashCode => level.hashCode ^ filters.hashCode;
}

class CoursesForAgeParams {
  final int age;
  final CourseSearchFilters? filters;

  const CoursesForAgeParams({
    required this.age,
    this.filters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursesForAgeParams &&
          runtimeType == other.runtimeType &&
          age == other.age &&
          filters == other.filters;

  @override
  int get hashCode => age.hashCode ^ filters.hashCode;
}

class RecommendedCoursesParams {
  final List<DanceType>? preferredDanceTypes;
  final List<Level>? preferredLevels;
  final int? age;
  final CourseSearchFilters? filters;

  const RecommendedCoursesParams({
    this.preferredDanceTypes,
    this.preferredLevels,
    this.age,
    this.filters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecommendedCoursesParams &&
          runtimeType == other.runtimeType &&
          preferredDanceTypes == other.preferredDanceTypes &&
          preferredLevels == other.preferredLevels &&
          age == other.age &&
          filters == other.filters;

  @override
  int get hashCode =>
      preferredDanceTypes.hashCode ^
      preferredLevels.hashCode ^
      age.hashCode ^
      filters.hashCode;
}

class CoursesStartingSoonParams {
  final int days;
  final CourseSearchFilters? filters;

  const CoursesStartingSoonParams({
    this.days = 7,
    this.filters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursesStartingSoonParams &&
          runtimeType == other.runtimeType &&
          days == other.days &&
          filters == other.filters;

  @override
  int get hashCode => days.hashCode ^ filters.hashCode;
}

class CourseCacheStatus {
  final int cachedCoursesCount;
  final bool isStale;
  final DateTime? lastUpdated;

  const CourseCacheStatus({
    required this.cachedCoursesCount,
    required this.isStale,
    this.lastUpdated,
  });
}

// Course favorites state (for future use)
class CourseFavoritesState {
  final Set<String> favoriteIds;
  final bool isLoading;
  final String? error;

  const CourseFavoritesState({
    this.favoriteIds = const {},
    this.isLoading = false,
    this.error,
  });

  CourseFavoritesState copyWith({
    Set<String>? favoriteIds,
    bool? isLoading,
    String? error,
  }) {
    return CourseFavoritesState(
      favoriteIds: favoriteIds ?? this.favoriteIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isFavorite(String courseId) => favoriteIds.contains(courseId);
}

// Course favorites notifier (placeholder for future implementation)
class CourseFavoritesNotifier extends StateNotifier<CourseFavoritesState> {
  CourseFavoritesNotifier() : super(const CourseFavoritesState());

  Future<void> toggleFavorite(String courseId) async {
    // TODO: Implement favorites functionality
    final currentFavorites = Set<String>.from(state.favoriteIds);
    
    if (currentFavorites.contains(courseId)) {
      currentFavorites.remove(courseId);
    } else {
      currentFavorites.add(courseId);
    }
    
    state = state.copyWith(favoriteIds: currentFavorites);
  }

  Future<void> loadFavorites() async {
    // TODO: Load favorites from storage/API
  }
}

// Course favorites provider
final courseFavoritesProvider = StateNotifierProvider<CourseFavoritesNotifier, CourseFavoritesState>((ref) {
  return CourseFavoritesNotifier();
});