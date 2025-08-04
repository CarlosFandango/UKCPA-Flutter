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
      _logger.d('Returning cached terms: ${_cachedTerms!.length} terms');
      return _cachedTerms!;
    }

    try {
      _logger.d('Fetching terms with displayStatus: $displayStatus');
      
      final options = QueryOptions(
        document: gql(getTermsQuery),
        variables: {
          'data': TermInput(displayStatus: displayStatus).toJson(),
        },
        fetchPolicy: FetchPolicy.networkOnly, // Always fetch fresh data
      );

      final result = await _client.query(options);

      if (result.hasException) {
        _logger.e('GraphQL exception: ${result.exception}');
        throw RepositoryException(
          'Failed to fetch terms',
          result.exception,
        );
      }

      final data = result.data?['getTerms'];
      if (data == null) {
        _logger.e('No getTerms data received in GraphQL response');
        throw const RepositoryException('No terms data received');
      }

      _logger.d('Raw GraphQL response structure: ${data.keys.toList()}');

      // Parse the response - getTerms returns both 'terms' array and single 'term'
      final List<dynamic> termsData = data['terms'] ?? [];
      final dynamic termData = data['term'];

      _logger.d('Terms array length: ${termsData.length}');
      _logger.d('Single term data: ${termData != null ? 'present' : 'null'}');

      final List<Term> terms = [];
      
      // Add terms from the terms array
      for (int i = 0; i < termsData.length; i++) {
        final termJson = termsData[i];
        try {
          _logger.d('Parsing term $i: ID=${termJson['id']}, name=${termJson['name']}');
          final term = _parseTermFromJson(termJson);
          terms.add(term);
          _logger.d('Successfully parsed term: ${term.name} with ${term.courseGroups.length} course groups');
        } catch (e, stackTrace) {
          // Log detailed parsing error
          _logger.e('Error parsing term $i: $e');
          _logger.e('Term JSON: $termJson');
          _logger.e('Stack trace: $stackTrace');
        }
      }
      
      // Add the single term if it exists and isn't already in the list
      if (termData != null) {
        try {
          _logger.d('Parsing single term: ID=${termData['id']}, name=${termData['name']}');
          final singleTerm = _parseTermFromJson(termData);
          // Check if this term is already in the list
          if (!terms.any((t) => t.id == singleTerm.id)) {
            terms.add(singleTerm);
            _logger.d('Added single term: ${singleTerm.name} with ${singleTerm.courseGroups.length} course groups');
          } else {
            _logger.d('Single term already exists in terms array, skipping');
          }
        } catch (e, stackTrace) {
          _logger.e('Error parsing single term: $e');
          _logger.e('Single term JSON: $termData');
          _logger.e('Stack trace: $stackTrace');
        }
      }

      _logger.d('Total parsed terms: ${terms.length}');
      for (final term in terms) {
        _logger.d('Term: ${term.name} has ${term.courseGroups.length} course groups');
      }

      // Update cache
      _cachedTerms = terms;
      _cachedDisplayStatus = displayStatus;
      _cacheTimestamp = DateTime.now();

      return terms;
    } catch (e) {
      _logger.e('Unexpected error in getTerms: $e');
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
    _logger.d('Parsing term from JSON: ${json.keys.toList()}');
    
    final List<ClassHoliday> holidays = [];
    final holidaysData = json['holidays'] as List<dynamic>? ?? [];
    
    _logger.d('Parsing ${holidaysData.length} holidays');
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
    
    _logger.d('Parsing ${courseGroupsData.length} course groups');
    for (int i = 0; i < courseGroupsData.length; i++) {
      final courseGroupJson = courseGroupsData[i];
      try {
        final courseGroup = _parseCourseGroupFromJson(courseGroupJson);
        courseGroups.add(courseGroup);
        _logger.d('Successfully parsed course group $i: ${courseGroup.name}');
      } catch (e, stackTrace) {
        _logger.e('Error parsing course group $i: $e');
        _logger.e('Course group JSON: $courseGroupJson');
        _logger.e('Stack trace: $stackTrace');
      }
    }

    // Handle Term ID - server returns string, we need int
    final idValue = json['id'];
    int termId;
    if (idValue is String) {
      termId = int.parse(idValue);
      _logger.d('Converted string ID "$idValue" to int $termId');
    } else if (idValue is int) {
      termId = idValue;
      _logger.d('Using int ID $termId');
    } else {
      throw Exception('Term ID must be string or int, got ${idValue.runtimeType}');
    }

    return Term(
      id: termId,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      holidays: holidays,
      courseGroups: courseGroups,
    );
  }

  /// Parse CourseGroup from JSON data
  CourseGroup _parseCourseGroupFromJson(Map<String, dynamic> json) {
    _logger.d('Parsing course group from JSON: ${json.keys.toList()}');
    _logger.d('Course group ID: ${json['id']}, name: ${json['name']}');
    
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
    
    _logger.d('Parsing ${coursesData.length} courses for course group ${json['name']}');
    for (int i = 0; i < coursesData.length; i++) {
      final courseJson = coursesData[i];
      try {
        final course = _parseCourseFromJson(courseJson);
        courses.add(course);
        _logger.d('Successfully parsed course $i: ${course.name}');
      } catch (e, stackTrace) {
        _logger.e('Error parsing course $i: $e');
        _logger.e('Course JSON: $courseJson');
        _logger.e('Stack trace: $stackTrace');
      }
    }

    // Handle CourseGroup ID - should be int from server
    final idValue = json['id'];
    int courseGroupId;
    if (idValue is int) {
      courseGroupId = idValue;
      _logger.d('Using int ID $courseGroupId');
    } else if (idValue is String) {
      courseGroupId = int.parse(idValue);
      _logger.d('Converted string ID "$idValue" to int $courseGroupId');
    } else {
      throw Exception('CourseGroup ID must be int or string, got ${idValue.runtimeType}');
    }

    final courseGroup = CourseGroup(
      id: courseGroupId,
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

    _logger.d('Successfully created course group: ${courseGroup.name} with ${courseGroup.courses.length} courses');
    return courseGroup;
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