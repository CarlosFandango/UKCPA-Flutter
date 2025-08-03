import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart' as logger;
import '../../domain/entities/course.dart';
import '../../domain/entities/course_group.dart';
import '../../domain/entities/course_session.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/graphql_client.dart';

/// Implementation of CourseRepository using GraphQL API
class CourseRepositoryImpl implements CourseRepository {
  final GraphQLClient _client;
  final logger.Logger _logger = logger.Logger();
  
  // Cache for filter options to reduce API calls
  CourseFilterOptions? _cachedFilterOptions;
  DateTime? _filterOptionsCacheTime;
  static const Duration _filterOptionsCacheDuration = Duration(hours: 1);
  
  // Cache for courses to support offline functionality
  List<Course>? _cachedCourses;
  DateTime? _coursesCacheTime;
  static const Duration _coursesCacheDuration = Duration(minutes: 30);

  CourseRepositoryImpl({GraphQLClient? client}) 
    : _client = client ?? getGraphQLClient();

  @override
  Future<CourseSearchResult> getCourses({
    CourseSearchFilters? filters,
  }) async {
    try {
      _logger.d('Fetching courses with filters: ${filters?.toJson()}');
      
      const query = '''
        query GetCourses(
          \$searchTerm: String
          \$danceTypes: [DanceTypeEnum!]
          \$levels: [LevelEnum!]
          \$locations: [LocationEnum!]
          \$attendanceTypes: [AttendanceTypeEnum!]
          \$minAge: Int
          \$maxAge: Int
          \$minPrice: Int
          \$maxPrice: Int
          \$hasTasterClasses: Boolean
          \$isAcceptingDeposits: Boolean
          \$startDateFrom: DateTime
          \$startDateTo: DateTime
          \$availableOnly: Boolean
          \$limit: Int
          \$offset: Int
          \$sortBy: CourseSortByEnum
          \$sortOrder: SortOrderEnum
        ) {
          courses(
            searchTerm: \$searchTerm
            danceTypes: \$danceTypes
            levels: \$levels
            locations: \$locations
            attendanceTypes: \$attendanceTypes
            minAge: \$minAge
            maxAge: \$maxAge
            minPrice: \$minPrice
            maxPrice: \$maxPrice
            hasTasterClasses: \$hasTasterClasses
            isAcceptingDeposits: \$isAcceptingDeposits
            startDateFrom: \$startDateFrom
            startDateTo: \$startDateTo
            availableOnly: \$availableOnly
            limit: \$limit
            offset: \$offset
            sortBy: \$sortBy
            sortOrder: \$sortOrder
          ) {
            items {
              __typename
              ... on StudioCourse {
                ...StudioCourseFragment
              }
              ... on OnlineCourse {
                ...OnlineCourseFragment
              }
            }
            totalCount
            hasMore
          }
        }
        ${GraphQLFragments.studioCourseFragment}
        ${GraphQLFragments.onlineCourseFragment}
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: _buildQueryVariables(filters),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
      );

      if (result.hasException) {
        throw CourseRepositoryException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final data = result.data?['courses'];
      if (data == null) {
        throw const InvalidCourseDataException(
          message: 'Invalid response format from server',
        );
      }

      final courses = (data['items'] as List)
          .map((json) => _parseCourseFromJson(json))
          .where((course) => course != null)
          .cast<Course>()
          .toList();

      // Update cache
      _cachedCourses = courses;
      _coursesCacheTime = DateTime.now();

      final searchResult = CourseSearchResult(
        courses: courses,
        totalCount: data['totalCount'] ?? 0,
        hasMore: data['hasMore'] ?? false,
        filters: filters ?? const CourseSearchFilters(),
      );

      _logger.d('Successfully fetched ${courses.length} courses');
      return searchResult;
    } catch (e) {
      _logger.e('Error fetching courses: $e');
      
      if (e is CourseRepositoryException) {
        rethrow;
      }
      
      throw CourseRepositoryException(
        message: 'Failed to fetch courses: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<Course?> getCourse(String courseId) async {
    try {
      _logger.d('Fetching course with ID: $courseId');
      
      const query = '''
        query GetCourse(\$id: ID!) {
          course(id: \$id) {
            __typename
            ... on StudioCourse {
              ...StudioCourseFragment
            }
            ... on OnlineCourse {
              ...OnlineCourseFragment
            }
          }
        }
        ${GraphQLFragments.studioCourseFragment}
        ${GraphQLFragments.onlineCourseFragment}
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': courseId},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        throw CourseRepositoryException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final courseData = result.data?['course'];
      if (courseData == null) {
        return null;
      }

      final course = _parseCourseFromJson(courseData);
      _logger.d('Successfully fetched course: ${course?.name}');
      return course;
    } catch (e) {
      _logger.e('Error fetching course $courseId: $e');
      
      if (e is CourseRepositoryException) {
        rethrow;
      }
      
      throw CourseRepositoryException(
        message: 'Failed to fetch course: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<StudioCourse?> getStudioCourse(String courseId) async {
    final course = await getCourse(courseId);
    return course is StudioCourse ? course as StudioCourse : null;
  }

  @override
  Future<OnlineCourse?> getOnlineCourse(String courseId) async {
    final course = await getCourse(courseId);
    return course is OnlineCourse ? course as OnlineCourse : null;
  }

  @override
  Future<List<CourseGroup>> getCourseGroups() async {
    try {
      _logger.d('Fetching course groups');
      
      const query = '''
        query GetCourseGroups {
          courseGroups {
            id
            name
            description
            shortDescription
            subtitle
            image
            thumbImage
            imagePosition {
              x
              y
            }
            order
            active
            displayStatus
            danceType
            level
            attendanceTypes
            ageFrom
            ageTo
            totalCourses
            availableCourses
            totalPrice
            discountedPrice
            bundleDiscount
            startDate
            endDate
            durationWeeks
            prerequisites
            progression
            skillsLearned
            category
            tags
            courses {
              __typename
              ... on StudioCourse {
                ...StudioCourseFragment
              }
              ... on OnlineCourse {
                ...OnlineCourseFragment
              }
            }
          }
        }
        ${GraphQLFragments.studioCourseFragment}
        ${GraphQLFragments.onlineCourseFragment}
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
      );

      if (result.hasException) {
        throw CourseRepositoryException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final groupsData = result.data?['courseGroups'] as List?;
      if (groupsData == null) {
        return [];
      }

      final groups = groupsData
          .map((json) => _parseCourseGroupFromJson(json))
          .where((group) => group != null)
          .cast<CourseGroup>()
          .toList();

      _logger.d('Successfully fetched ${groups.length} course groups');
      return groups;
    } catch (e) {
      _logger.e('Error fetching course groups: $e');
      
      if (e is CourseRepositoryException) {
        rethrow;
      }
      
      throw CourseRepositoryException(
        message: 'Failed to fetch course groups: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<CourseGroup?> getCourseGroup(String groupId) async {
    try {
      _logger.d('Fetching course group with ID: $groupId');
      
      const query = '''
        query GetCourseGroup(\$id: ID!) {
          courseGroup(id: \$id) {
            id
            name
            description
            shortDescription
            subtitle
            image
            thumbImage
            imagePosition {
              x
              y
            }
            order
            active
            displayStatus
            danceType
            level
            attendanceTypes
            ageFrom
            ageTo
            totalCourses
            availableCourses
            totalPrice
            discountedPrice
            bundleDiscount
            startDate
            endDate
            durationWeeks
            prerequisites
            progression
            skillsLearned
            category
            tags
            courses {
              __typename
              ... on StudioCourse {
                ...StudioCourseFragment
              }
              ... on OnlineCourse {
                ...OnlineCourseFragment
              }
            }
          }
        }
        ${GraphQLFragments.studioCourseFragment}
        ${GraphQLFragments.onlineCourseFragment}
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': groupId},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        throw CourseRepositoryException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final groupData = result.data?['courseGroup'];
      if (groupData == null) {
        return null;
      }

      final group = _parseCourseGroupFromJson(groupData);
      _logger.d('Successfully fetched course group: ${group?.name}');
      return group;
    } catch (e) {
      _logger.e('Error fetching course group $groupId: $e');
      
      if (e is CourseRepositoryException) {
        rethrow;
      }
      
      throw CourseRepositoryException(
        message: 'Failed to fetch course group: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<Course>> getCoursesInGroup(String groupId) async {
    final group = await getCourseGroup(groupId);
    return group?.courses ?? [];
  }

  @override
  Future<List<CourseSession>> getCourseSessions(String courseId) async {
    try {
      _logger.d('Fetching course sessions for course: $courseId');
      
      const query = '''
        query GetCourseSessions(\$courseId: ID!) {
          courseSessions(courseId: \$courseId) {
            id
            courseId
            startDateTime
            endDateTime
            title
            description
            instructor
            location
            maxParticipants
            currentParticipants
            isBookable
            isCancelled
            isRescheduled
            originalDateTime
            sessionType
            notes
            zoomMeeting {
              meetingId
              password
            }
            booking {
              id
              status
              bookingDate
            }
          }
        }
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'courseId': courseId},
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
      );

      if (result.hasException) {
        throw CourseRepositoryException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final sessionsData = result.data?['courseSessions'] as List?;
      if (sessionsData == null) {
        return [];
      }

      final sessions = sessionsData
          .map((json) => _parseCourseSessionFromJson(json))
          .where((session) => session != null)
          .cast<CourseSession>()
          .toList();

      _logger.d('Successfully fetched ${sessions.length} course sessions');
      return sessions;
    } catch (e) {
      _logger.e('Error fetching course sessions: $e');
      
      if (e is CourseRepositoryException) {
        rethrow;
      }
      
      throw CourseRepositoryException(
        message: 'Failed to fetch course sessions: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<CourseSession?> getCourseSession(String sessionId) async {
    try {
      _logger.d('Fetching course session with ID: $sessionId');
      
      const query = '''
        query GetCourseSession(\$id: ID!) {
          courseSession(id: \$id) {
            id
            courseId
            startDateTime
            endDateTime
            title
            description
            instructor
            location
            maxParticipants
            currentParticipants
            isBookable
            isCancelled
            isRescheduled
            originalDateTime
            sessionType
            notes
            zoomMeeting {
              meetingId
              password
            }
            booking {
              id
              status
              bookingDate
            }
          }
        }
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'id': sessionId},
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );

      if (result.hasException) {
        throw CourseRepositoryException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final sessionData = result.data?['courseSession'];
      if (sessionData == null) {
        return null;
      }

      final session = _parseCourseSessionFromJson(sessionData);
      _logger.d('Successfully fetched course session: ${session?.id}');
      return session;
    } catch (e) {
      _logger.e('Error fetching course session $sessionId: $e');
      
      if (e is CourseRepositoryException) {
        rethrow;
      }
      
      throw CourseRepositoryException(
        message: 'Failed to fetch course session: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<List<CourseSession>> getUpcomingSessions(String courseId) async {
    final sessions = await getCourseSessions(courseId);
    final now = DateTime.now();
    
    return sessions
        .where((session) => session.startDateTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
  }

  @override
  Future<CourseSearchResult> searchCourses(
    String query, {
    CourseSearchFilters? filters,
  }) async {
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      searchTerm: query,
    );
    
    return getCourses(filters: searchFilters);
  }

  @override
  Future<List<Course>> getFeaturedCourses({int? limit}) async {
    final filters = CourseSearchFilters(
      limit: limit ?? 10,
      sortBy: CourseSortBy.popularity,
      sortOrder: SortOrder.descending,
    );
    
    final result = await getCourses(filters: filters);
    return result.courses;
  }

  @override
  Future<List<Course>> getPopularCourses({int? limit}) async {
    final filters = CourseSearchFilters(
      limit: limit ?? 10,
      sortBy: CourseSortBy.popularity,
      sortOrder: SortOrder.descending,
    );
    
    final result = await getCourses(filters: filters);
    return result.courses;
  }

  @override
  Future<List<Course>> getCoursesByDanceType(
    DanceType danceType, {
    CourseSearchFilters? filters,
  }) async {
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      danceTypes: [danceType],
    );
    
    final result = await getCourses(filters: searchFilters);
    return result.courses;
  }

  @override
  Future<List<Course>> getCoursesByLevel(
    Level level, {
    CourseSearchFilters? filters,
  }) async {
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      levels: [level],
    );
    
    final result = await getCourses(filters: searchFilters);
    return result.courses;
  }

  @override
  Future<List<Course>> getCoursesByLocation(
    Location location, {
    CourseSearchFilters? filters,
  }) async {
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      locations: [location],
    );
    
    final result = await getCourses(filters: searchFilters);
    return result.courses;
  }

  @override
  Future<List<Course>> getCoursesForAge(
    int age, {
    CourseSearchFilters? filters,
  }) async {
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      minAge: age,
      maxAge: age,
    );
    
    final result = await getCourses(filters: searchFilters);
    return result.courses;
  }

  @override
  Future<List<Course>> getCoursesWithTasters({
    CourseSearchFilters? filters,
  }) async {
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      hasTasterClasses: true,
    );
    
    final result = await getCourses(filters: searchFilters);
    return result.courses;
  }

  @override
  Future<List<Course>> getRecommendedCourses({
    List<DanceType>? preferredDanceTypes,
    List<Level>? preferredLevels,
    int? age,
    CourseSearchFilters? filters,
  }) async {
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      danceTypes: preferredDanceTypes,
      levels: preferredLevels,
      minAge: age,
      maxAge: age,
      sortBy: CourseSortBy.popularity,
      sortOrder: SortOrder.descending,
      limit: 20,
    );
    
    final result = await getCourses(filters: searchFilters);
    return result.courses;
  }

  @override
  Future<List<Course>> getCoursesStartingSoon({
    int? days = 7,
    CourseSearchFilters? filters,
  }) async {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days!));
    
    final searchFilters = (filters ?? const CourseSearchFilters()).copyWith(
      startDateFrom: now,
      startDateTo: futureDate,
      sortBy: CourseSortBy.startDate,
      sortOrder: SortOrder.ascending,
    );
    
    final result = await getCourses(filters: searchFilters);
    return result.courses;
  }

  @override
  Future<CourseFilterOptions> getFilterOptions() async {
    // Return cached filter options if available and fresh
    if (_cachedFilterOptions != null && 
        _filterOptionsCacheTime != null &&
        DateTime.now().difference(_filterOptionsCacheTime!) < _filterOptionsCacheDuration) {
      return _cachedFilterOptions!;
    }

    try {
      _logger.d('Fetching course filter options');
      
      const query = '''
        query GetCourseFilterOptions {
          courseFilterOptions {
            availableDanceTypes
            availableLevels
            availableLocations
            availableAttendanceTypes
            minPrice
            maxPrice
            minAge
            maxAge
          }
        }
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
      );

      if (result.hasException) {
        throw CourseRepositoryException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final data = result.data?['courseFilterOptions'];
      if (data == null) {
        throw const InvalidCourseDataException(
          message: 'Invalid filter options response format',
        );
      }

      final filterOptions = CourseFilterOptions(
        availableDanceTypes: (data['availableDanceTypes'] as List?)
            ?.map((e) => DanceType.values.firstWhere((v) => v.name == e))
            .toList() ?? [],
        availableLevels: (data['availableLevels'] as List?)
            ?.map((e) => Level.values.firstWhere((v) => v.name == e))
            .cast<Level>()
            .toList() ?? [],
        availableLocations: (data['availableLocations'] as List?)
            ?.map((e) => Location.values.firstWhere((v) => v.name == e))
            .toList() ?? [],
        availableAttendanceTypes: (data['availableAttendanceTypes'] as List?)
            ?.map((e) => AttendanceType.values.firstWhere((v) => v.name == e))
            .toList() ?? [],
        minPrice: data['minPrice'] ?? 0,
        maxPrice: data['maxPrice'] ?? 1000,
        minAge: data['minAge'] ?? 0,
        maxAge: data['maxAge'] ?? 100,
      );

      // Cache the result
      _cachedFilterOptions = filterOptions;
      _filterOptionsCacheTime = DateTime.now();

      _logger.d('Successfully fetched course filter options');
      return filterOptions;
    } catch (e) {
      _logger.e('Error fetching filter options: $e');
      
      if (e is CourseRepositoryException) {
        rethrow;
      }
      
      throw CourseRepositoryException(
        message: 'Failed to fetch filter options: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> refreshCourses() async {
    try {
      _logger.d('Refreshing course data');
      
      // Clear caches to force fresh data
      await clearCache();
      
      // Fetch fresh data
      await getCourses();
      await getFilterOptions();
      
      _logger.d('Successfully refreshed course data');
    } catch (e) {
      _logger.e('Error refreshing courses: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      _logger.d('Clearing course repository cache');
      
      // Clear local caches
      _cachedCourses = null;
      _coursesCacheTime = null;
      _cachedFilterOptions = null;
      _filterOptionsCacheTime = null;
      
      // Clear GraphQL cache
      await GraphQLClientUtils.clearCache();
      
      _logger.d('Successfully cleared course repository cache');
    } catch (e) {
      _logger.e('Error clearing cache: $e');
      rethrow;
    }
  }

  @override
  Future<List<Course>> getCachedCourses() async {
    return _cachedCourses ?? [];
  }

  @override
  Future<bool> isDataStale() async {
    if (_coursesCacheTime == null) {
      return true;
    }
    
    final age = DateTime.now().difference(_coursesCacheTime!);
    return age > _coursesCacheDuration;
  }

  // Helper methods

  Map<String, dynamic> _buildQueryVariables(CourseSearchFilters? filters) {
    if (filters == null) return {};
    
    return {
      if (filters.searchTerm != null) 'searchTerm': filters.searchTerm,
      if (filters.danceTypes != null) 
        'danceTypes': filters.danceTypes!.map((e) => e.name.toUpperCase()).toList(),
      if (filters.levels != null) 
        'levels': filters.levels!.map((e) => e.name.toUpperCase()).toList(),
      if (filters.locations != null) 
        'locations': filters.locations!.map((e) => e.name.toUpperCase()).toList(),
      if (filters.attendanceTypes != null) 
        'attendanceTypes': filters.attendanceTypes!.map((e) => e.name.toUpperCase()).toList(),
      if (filters.minAge != null) 'minAge': filters.minAge,
      if (filters.maxAge != null) 'maxAge': filters.maxAge,
      if (filters.minPrice != null) 'minPrice': filters.minPrice,
      if (filters.maxPrice != null) 'maxPrice': filters.maxPrice,
      if (filters.hasTasterClasses != null) 'hasTasterClasses': filters.hasTasterClasses,
      if (filters.isAcceptingDeposits != null) 'isAcceptingDeposits': filters.isAcceptingDeposits,
      if (filters.startDateFrom != null) 'startDateFrom': filters.startDateFrom!.toIso8601String(),
      if (filters.startDateTo != null) 'startDateTo': filters.startDateTo!.toIso8601String(),
      if (filters.availableOnly != null) 'availableOnly': filters.availableOnly,
      if (filters.limit != null) 'limit': filters.limit,
      if (filters.offset != null) 'offset': filters.offset,
      if (filters.sortBy != null) 'sortBy': filters.sortBy!.name.toUpperCase(),
      if (filters.sortOrder != null) 'sortOrder': filters.sortOrder!.name.toUpperCase(),
    };
  }

  Course? _parseCourseFromJson(Map<String, dynamic> json) {
    try {
      final typename = json['__typename'] as String?;
      
      switch (typename) {
        case 'StudioCourse':
          return StudioCourse.fromJson(json) as Course;
        case 'OnlineCourse':
          return OnlineCourse.fromJson(json) as Course;
        default:
          _logger.w('Unknown course type: $typename');
          return null;
      }
    } catch (e) {
      _logger.e('Error parsing course from JSON: $e');
      return null;
    }
  }

  CourseGroup? _parseCourseGroupFromJson(Map<String, dynamic> json) {
    try {
      return CourseGroup.fromJson(json);
    } catch (e) {
      _logger.e('Error parsing course group from JSON: $e');
      return null;
    }
  }

  CourseSession? _parseCourseSessionFromJson(Map<String, dynamic> json) {
    try {
      return CourseSession.fromJson(json);
    } catch (e) {
      _logger.e('Error parsing course session from JSON: $e');
      return null;
    }
  }
}