import 'package:freezed_annotation/freezed_annotation.dart';
import 'course_group.dart';

part 'term.freezed.dart';
part 'term.g.dart';

/// A term represents a period containing course groups (e.g., "Spring 2025", "Summer 2025")
/// Based on TermFragment from the website GraphQL schema
@freezed
class Term with _$Term {
  const factory Term({
    required int id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    @Default([]) List<Holiday> holidays,
    @Default([]) List<CourseGroup> courseGroups,
  }) = _Term;

  factory Term.fromJson(Map<String, dynamic> json) => _$TermFromJson(json);
}

/// Holiday periods within a term
/// Based on holiday structure from TermFragment
@freezed
class Holiday with _$Holiday {
  const factory Holiday({
    required String name,
    required DateTime startDateTime,
    required DateTime endDateTime,
  }) = _Holiday;

  factory Holiday.fromJson(Map<String, dynamic> json) => _$HolidayFromJson(json);
}

/// Extension methods for term utilities
extension TermExtensions on Term {
  /// Check if the term is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAtSameMomentAs(startDate) || 
           (now.isAfter(startDate) && now.isBefore(endDate));
  }

  /// Check if the term is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  /// Check if the term has ended
  bool get hasEnded {
    return DateTime.now().isAfter(endDate);
  }

  /// Get the duration of the term in weeks
  int get durationInWeeks {
    return endDate.difference(startDate).inDays ~/ 7;
  }

  /// Get all available course groups in this term
  List<CourseGroup> get availableCourseGroups {
    return courseGroups.where((group) => group.isAvailable).toList();
  }

  /// Get course groups by dance type
  List<CourseGroup> courseGroupsByDanceType(String danceType) {
    return courseGroups.where((group) => 
        group.danceType?.toString().toLowerCase().contains(danceType.toLowerCase()) == true
    ).toList();
  }

  /// Get course groups suitable for children
  List<CourseGroup> get childrenCourseGroups {
    return courseGroups.where((group) => group.coursesForChildren.isNotEmpty).toList();
  }

  /// Get course groups suitable for adults
  List<CourseGroup> get adultCourseGroups {
    return courseGroups.where((group) => group.coursesForAdults.isNotEmpty).toList();
  }

  /// Check if a date falls within a holiday period
  bool isDateInHoliday(DateTime date) {
    return holidays.any((holiday) =>
        (date.isAtSameMomentAs(holiday.startDateTime) || date.isAfter(holiday.startDateTime)) &&
        date.isBefore(holiday.endDateTime));
  }

  /// Get holiday that contains the given date, if any
  Holiday? getHolidayForDate(DateTime date) {
    return holidays.where((holiday) =>
        (date.isAtSameMomentAs(holiday.startDateTime) || date.isAfter(holiday.startDateTime)) &&
        date.isBefore(holiday.endDateTime)
    ).firstOrNull;
  }

  /// Get all holidays within a date range
  List<Holiday> getHolidaysInRange(DateTime start, DateTime end) {
    return holidays.where((holiday) =>
        holiday.startDateTime.isBefore(end) && holiday.endDateTime.isAfter(start)
    ).toList();
  }

  /// Get total number of available courses in this term
  int get totalAvailableCoursesCount {
    return courseGroups.fold(0, (total, group) => total + group.availableCoursesCount);
  }

  /// Get price range across all course groups
  String? get priceRangeDisplay {
    final allPrices = <int>[];
    
    for (final group in courseGroups) {
      final minPrice = group.minPrice;
      final maxPrice = group.maxPrice;
      if (minPrice != null) allPrices.add(minPrice);
      if (maxPrice != null) allPrices.add(maxPrice);
    }
    
    if (allPrices.isEmpty) return null;
    
    allPrices.sort();
    final min = allPrices.first;
    final max = allPrices.last;
    
    if (min == max) return '£$min';
    return '£$min - £$max';
  }

  /// Search course groups by name or description
  List<CourseGroup> searchCourseGroups(String query) {
    if (query.trim().isEmpty) return courseGroups;
    
    final lowerQuery = query.toLowerCase().trim();
    return courseGroups.where((group) {
      return group.name.toLowerCase().contains(lowerQuery) ||
             (group.shortDescription?.toLowerCase().contains(lowerQuery) == true) ||
             (group.description?.toLowerCase().contains(lowerQuery) == true);
    }).toList();
  }

  /// Get unique locations from all course groups
  Set<String> get availableLocations {
    final locations = <String>{};
    for (final group in courseGroups) {
      if (group.locations != null) {
        locations.addAll(group.locations!);
      }
    }
    return locations;
  }

  /// Get unique dance types from all course groups
  Set<String> get availableDanceTypes {
    final danceTypes = <String>{};
    for (final group in courseGroups) {
      if (group.danceType != null) {
        danceTypes.add(group.danceType!);
      }
    }
    return danceTypes;
  }

  /// Get unique course types (Online/Studio) from all course groups
  Set<String> get availableCourseTypes {
    final courseTypes = <String>{};
    for (final group in courseGroups) {
      if (group.courseTypes != null) {
        courseTypes.addAll(group.courseTypes!);
      }
    }
    return courseTypes;
  }
}

/// Extension methods for holiday utilities
extension HolidayExtensions on Holiday {
  /// Get the duration of the holiday in days
  int get durationInDays {
    return endDateTime.difference(startDateTime).inDays;
  }

  /// Check if the holiday is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAtSameMomentAs(startDateTime) ||
           (now.isAfter(startDateTime) && now.isBefore(endDateTime));
  }

  /// Check if the holiday is upcoming
  bool get isUpcoming {
    return DateTime.now().isBefore(startDateTime);
  }

  /// Check if the holiday has ended
  bool get hasEnded {
    return DateTime.now().isAfter(endDateTime);
  }
}