import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/course_group.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/terms_repository.dart';
import '../graphql/terms_queries.dart';
import '../../presentation/providers/graphql_provider.dart';

part 'terms_repository_impl.g.dart';

/// Terms repository implementation using GraphQL
class TermsRepositoryImpl implements TermsRepository {
  final GraphQLClient _client;
  final Logger _logger = Logger();
  
  // Simple in-memory cache
  List<Term>? _cachedTerms;
  String? _cachedDisplayStatus;
  DateTime? _cacheTimestamp;
  
  // Cache duration - 5 minutes
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  TermsRepositoryImpl(this._client);

  @override
  Future<List<Term>> getTerms({String displayStatus = 'LIVE'}) async {
    // Check cache first
    if (_isValidCache(displayStatus)) {
      return _cachedTerms!;
    }

    try {
      final options = QueryOptions(
        document: gql(getTermsQuery),
        variables: {
          'data': TermInput(displayStatus: displayStatus).toJson(),
        },
        fetchPolicy: FetchPolicy.networkOnly, // Always fetch fresh data
      );

      final result = await _client.query(options);

      if (result.hasException) {
        throw RepositoryException(
          'Failed to fetch terms',
          result.exception,
        );
      }

      final data = result.data?['getTerms'];
      if (data == null) {
        throw const RepositoryException('No terms data received');
      }

      // Parse the response - getTerms returns both 'terms' array and single 'term'
      final List<dynamic> termsData = data['terms'] ?? [];
      final dynamic termData = data['term'];

      final List<Term> terms = [];
      
      // Add terms from the terms array
      for (final termJson in termsData) {
        try {
          final term = _parseTermFromJson(termJson);
          terms.add(term);
        } catch (e) {
          // Log parsing error but continue with other terms
          _logger.w('Error parsing term: $e');
        }
      }
      
      // Add the single term if it exists and isn't already in the list
      if (termData != null) {
        try {
          final singleTerm = _parseTermFromJson(termData);
          // Check if this term is already in the list
          if (!terms.any((t) => t.id == singleTerm.id)) {
            terms.add(singleTerm);
          }
        } catch (e) {
          _logger.w('Error parsing single term: $e');
        }
      }

      // Update cache
      _cachedTerms = terms;
      _cachedDisplayStatus = displayStatus;
      _cacheTimestamp = DateTime.now();

      return terms;
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Unexpected error fetching terms', e);
    }
  }

  @override
  Future<CourseGroup?> getCourseGroup(int id, {String? displayStatus}) async {
    try {
      final variables = <String, dynamic>{
        'id': id.toDouble(), // GraphQL expects Float
      };
      
      if (displayStatus != null) {
        variables['displayStatus'] = displayStatus;
      }

      final options = QueryOptions(
        document: gql(getCourseGroupQuery),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _client.query(options);

      if (result.hasException) {
        throw RepositoryException(
          'Failed to fetch course group',
          result.exception,
        );
      }

      final data = result.data?['getCourseGroup'];
      if (data == null) {
        return null; // Course group not found
      }

      return _parseCourseGroupFromJson(data);
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Unexpected error fetching course group', e);
    }
  }

  @override
  Future<void> clearCache() async {
    _cachedTerms = null;
    _cachedDisplayStatus = null;
    _cacheTimestamp = null;
  }

  @override
  Future<List<Term>> refreshTerms({String displayStatus = 'LIVE'}) async {
    await clearCache();
    return getTerms(displayStatus: displayStatus);
  }

  /// Check if cached data is valid for the given display status
  bool _isValidCache(String displayStatus) {
    if (_cachedTerms == null || 
        _cachedDisplayStatus != displayStatus || 
        _cacheTimestamp == null) {
      return false;
    }

    final now = DateTime.now();
    return now.difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// Parse Term from JSON data
  Term _parseTermFromJson(Map<String, dynamic> json) {
    final List<ClassHoliday> holidays = [];
    final holidaysData = json['holidays'] as List<dynamic>? ?? [];
    
    for (final holidayJson in holidaysData) {
      try {
        final holiday = ClassHoliday(
          name: holidayJson['name'] as String,
          startDateTime: DateTime.parse(holidayJson['startDateTime'] as String),
          endDateTime: DateTime.parse(holidayJson['endDateTime'] as String),
        );
        holidays.add(holiday);
      } catch (e) {
        _logger.w('Error parsing holiday: $e');
      }
    }

    final List<CourseGroup> courseGroups = [];
    final courseGroupsData = json['courseGroups'] as List<dynamic>? ?? [];
    
    for (final courseGroupJson in courseGroupsData) {
      try {
        final courseGroup = _parseCourseGroupFromJson(courseGroupJson);
        courseGroups.add(courseGroup);
      } catch (e) {
        _logger.w('Error parsing course group: $e');
      }
    }

    return Term(
      id: json['id'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      holidays: holidays,
      courseGroups: courseGroups,
    );
  }

  /// Parse CourseGroup from JSON data
  CourseGroup _parseCourseGroupFromJson(Map<String, dynamic> json) {
    // Parse image position if present
    ImagePosition? imagePosition;
    final imagePositionData = json['imagePosition'];
    if (imagePositionData != null) {
      imagePosition = ImagePosition(
        X: (imagePositionData['X'] as num?)?.toDouble() ?? 0.0,
        Y: (imagePositionData['Y'] as num?)?.toDouble() ?? 0.0,
      );
    }

    // Parse courses
    final List<Course> courses = [];
    final coursesData = json['courses'] as List<dynamic>? ?? [];
    
    for (final courseJson in coursesData) {
      try {
        final course = _parseCourseFromJson(courseJson);
        courses.add(course);
      } catch (e) {
        _logger.w('Error parsing course: $e');
      }
    }

    return CourseGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      thumbImage: json['thumbImage'] as String?,
      image: json['image'] as String?,
      imagePosition: imagePosition,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      minOriginalPrice: json['minOriginalPrice'] as int?,
      maxOriginalPrice: json['maxOriginalPrice'] as int?,
      minPrice: json['minPrice'] as int?,
      maxPrice: json['maxPrice'] as int?,
      attendanceTypes: (json['attendanceTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      locations: (json['locations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      danceType: json['danceType'] as String?,
      courseTypes: (json['courseTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      courses: courses,
    );
  }

  /// Parse Course from JSON data with __typename discrimination
  Course _parseCourseFromJson(Map<String, dynamic> json) {
    // Convert attendance types
    final List<AttendanceType> attendanceTypes = [];
    final attendanceTypesData = json['attendanceTypes'] as List<dynamic>? ?? [];
    for (final attendanceType in attendanceTypesData) {
      switch (attendanceType as String) {
        case 'CHILDREN':
          attendanceTypes.add(AttendanceType.children);
          break;
        case 'ADULTS':
          attendanceTypes.add(AttendanceType.adults);
          break;
        default:
          _logger.w('Unknown attendance type: $attendanceType');
      }
    }

    // Parse common course fields
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
      ageFrom: json['ageFrom'] as int?,
      ageTo: json['ageTo'] as int?,
      active: json['active'] as bool? ?? true,
      price: json['price'] as int,
      originalPrice: json['originalPrice'] as int?,
      currentPrice: json['currentPrice'] as int?,
      depositPrice: json['depositPrice'] as int?,
      fullyBooked: json['fullyBooked'] as bool? ?? false,
      thumbImage: json['thumbImage'] as String?,
      image: json['image'] as String?,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      attendanceTypes: attendanceTypes.isNotEmpty ? attendanceTypes : [AttendanceType.adults],
      startDateTime: json['startDateTime'] != null ? DateTime.parse(json['startDateTime'] as String) : null,
      endDateTime: json['endDateTime'] != null ? DateTime.parse(json['endDateTime'] as String) : null,
      weeks: json['weeks'] as int?,
      order: json['order'] as int?,
      days: (json['days'] as List<dynamic>?)?.map((e) => e as String).toList(),
      hasTasterClasses: json['hasTasterClasses'] as bool? ?? false,
      tasterPrice: json['tasterPrice'] as int? ?? 0,
      isAcceptingDeposits: json['isAcceptingDeposits'] as bool? ?? false,
      instructions: json['instructions'] as String?,
      type: json['__typename'] as String? ?? 'StudioCourse',
    );
  }
}

/// Custom exception for repository errors
class RepositoryException implements Exception {
  final String message;
  final dynamic cause;

  const RepositoryException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'RepositoryException: $message\nCause: $cause';
    }
    return 'RepositoryException: $message';
  }
}

/// Provider for Terms repository
@riverpod
TermsRepository termsRepository(Ref ref) {
  final client = ref.watch(graphqlClientProvider);
  return TermsRepositoryImpl(client);
}