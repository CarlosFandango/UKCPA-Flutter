import '../entities/course.dart';
import '../entities/course_group.dart';
import '../entities/course_session.dart';

/// Filter criteria for searching courses
class CourseSearchFilters {
  final String? searchTerm;
  final List<DanceType>? danceTypes;
  final List<Level>? levels;
  final List<Location>? locations;
  final List<AttendanceType>? attendanceTypes;
  final int? minAge;
  final int? maxAge;
  final int? minPrice;
  final int? maxPrice;
  final bool? hasTasterClasses;
  final bool? isAcceptingDeposits;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final bool? availableOnly;
  final int? limit;
  final int? offset;
  final CourseSortBy? sortBy;
  final SortOrder? sortOrder;

  const CourseSearchFilters({
    this.searchTerm,
    this.danceTypes,
    this.levels,
    this.locations,
    this.attendanceTypes,
    this.minAge,
    this.maxAge,
    this.minPrice,
    this.maxPrice,
    this.hasTasterClasses,
    this.isAcceptingDeposits,
    this.startDateFrom,
    this.startDateTo,
    this.availableOnly = true,
    this.limit = 20,
    this.offset = 0,
    this.sortBy = CourseSortBy.name,
    this.sortOrder = SortOrder.ascending,
  });

  CourseSearchFilters copyWith({
    String? searchTerm,
    List<DanceType>? danceTypes,
    List<Level>? levels,
    List<Location>? locations,
    List<AttendanceType>? attendanceTypes,
    int? minAge,
    int? maxAge,
    int? minPrice,
    int? maxPrice,
    bool? hasTasterClasses,
    bool? isAcceptingDeposits,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    bool? availableOnly,
    int? limit,
    int? offset,
    CourseSortBy? sortBy,
    SortOrder? sortOrder,
  }) {
    return CourseSearchFilters(
      searchTerm: searchTerm ?? this.searchTerm,
      danceTypes: danceTypes ?? this.danceTypes,
      levels: levels ?? this.levels,
      locations: locations ?? this.locations,
      attendanceTypes: attendanceTypes ?? this.attendanceTypes,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      hasTasterClasses: hasTasterClasses ?? this.hasTasterClasses,
      isAcceptingDeposits: isAcceptingDeposits ?? this.isAcceptingDeposits,
      startDateFrom: startDateFrom ?? this.startDateFrom,
      startDateTo: startDateTo ?? this.startDateTo,
      availableOnly: availableOnly ?? this.availableOnly,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'searchTerm': searchTerm,
      'danceTypes': danceTypes?.map((e) => e.name).toList(),
      'levels': levels?.map((e) => e.name).toList(),
      'locations': locations?.map((e) => e.name).toList(),
      'attendanceTypes': attendanceTypes?.map((e) => e.name).toList(),
      'minAge': minAge,
      'maxAge': maxAge,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'hasTasterClasses': hasTasterClasses,
      'isAcceptingDeposits': isAcceptingDeposits,
      'startDateFrom': startDateFrom?.toIso8601String(),
      'startDateTo': startDateTo?.toIso8601String(),
      'availableOnly': availableOnly,
      'limit': limit,
      'offset': offset,
      'sortBy': sortBy?.name,
      'sortOrder': sortOrder?.name,
    };
  }
}

/// Sort options for courses
enum CourseSortBy {
  name,
  price,
  startDate,
  level,
  danceType,
  location,
  popularity,
  rating,
  newest,
}

/// Sort order options
enum SortOrder {
  ascending,
  descending,
}

/// Result container for course search
class CourseSearchResult {
  final List<Course> courses;
  final int totalCount;
  final bool hasMore;
  final CourseSearchFilters filters;

  const CourseSearchResult({
    required this.courses,
    required this.totalCount,
    required this.hasMore,
    required this.filters,
  });
}

/// Repository interface for course data operations
abstract class CourseRepository {
  /// Get all courses with optional filtering
  Future<CourseSearchResult> getCourses({
    CourseSearchFilters? filters,
  });

  /// Get a specific course by ID
  Future<Course?> getCourse(String courseId);

  /// Get a studio course by ID
  Future<StudioCourse?> getStudioCourse(String courseId);

  /// Get an online course by ID
  Future<OnlineCourse?> getOnlineCourse(String courseId);

  /// Get all course groups
  Future<List<CourseGroup>> getCourseGroups();

  /// Get a specific course group by ID
  Future<CourseGroup?> getCourseGroup(String groupId);

  /// Get courses in a specific group
  Future<List<Course>> getCoursesInGroup(String groupId);

  /// Get course sessions for a specific course
  Future<List<CourseSession>> getCourseSessions(String courseId);

  /// Get a specific course session
  Future<CourseSession?> getCourseSession(String sessionId);

  /// Get upcoming sessions for a course
  Future<List<CourseSession>> getUpcomingSessions(String courseId);

  /// Search courses by text query
  Future<CourseSearchResult> searchCourses(
    String query, {
    CourseSearchFilters? filters,
  });

  /// Get featured courses
  Future<List<Course>> getFeaturedCourses({int? limit});

  /// Get popular courses
  Future<List<Course>> getPopularCourses({int? limit});

  /// Get courses by dance type
  Future<List<Course>> getCoursesByDanceType(
    DanceType danceType, {
    CourseSearchFilters? filters,
  });

  /// Get courses by level
  Future<List<Course>> getCoursesByLevel(
    Level level, {
    CourseSearchFilters? filters,
  });

  /// Get courses by location
  Future<List<Course>> getCoursesByLocation(
    Location location, {
    CourseSearchFilters? filters,
  });

  /// Get courses suitable for a specific age
  Future<List<Course>> getCoursesForAge(
    int age, {
    CourseSearchFilters? filters,
  });

  /// Get courses with taster classes
  Future<List<Course>> getCoursesWithTasters({
    CourseSearchFilters? filters,
  });

  /// Get recommended courses based on user preferences
  Future<List<Course>> getRecommendedCourses({
    List<DanceType>? preferredDanceTypes,
    List<Level>? preferredLevels,
    int? age,
    CourseSearchFilters? filters,
  });

  /// Get courses starting in the next N days
  Future<List<Course>> getCoursesStartingSoon({
    int? days = 7,
    CourseSearchFilters? filters,
  });

  /// Get available filter options based on current courses
  Future<CourseFilterOptions> getFilterOptions();

  /// Refresh course data from server
  Future<void> refreshCourses();

  /// Clear local course cache
  Future<void> clearCache();

  /// Get cached courses (offline support)
  Future<List<Course>> getCachedCourses();

  /// Check if course data is stale and needs refresh
  Future<bool> isDataStale();
}

/// Available filter options for the UI
class CourseFilterOptions {
  final List<DanceType> availableDanceTypes;
  final List<Level> availableLevels;
  final List<Location> availableLocations;
  final List<AttendanceType> availableAttendanceTypes;
  final int minPrice;
  final int maxPrice;
  final int minAge;
  final int maxAge;

  const CourseFilterOptions({
    required this.availableDanceTypes,
    required this.availableLevels,
    required this.availableLocations,
    required this.availableAttendanceTypes,
    required this.minPrice,
    required this.maxPrice,
    required this.minAge,
    required this.maxAge,
  });
}

/// Exception thrown when course operations fail
class CourseRepositoryException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const CourseRepositoryException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    return 'CourseRepositoryException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Network-related course repository exceptions
class CourseNetworkException extends CourseRepositoryException {
  const CourseNetworkException({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Course not found exception
class CourseNotFoundException extends CourseRepositoryException {
  final String courseId;

  const CourseNotFoundException({
    required this.courseId,
    super.code,
    super.originalError,
  }) : super(message: 'Course with ID $courseId not found');
}

/// Invalid course data exception
class InvalidCourseDataException extends CourseRepositoryException {
  const InvalidCourseDataException({
    required super.message,
    super.code,
    super.originalError,
  });
}