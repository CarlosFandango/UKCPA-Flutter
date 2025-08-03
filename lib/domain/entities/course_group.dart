import 'package:freezed_annotation/freezed_annotation.dart';
import 'course.dart';

part 'course_group.freezed.dart';
part 'course_group.g.dart';

/// A group of related courses, typically representing a program or curriculum
@freezed
class CourseGroup with _$CourseGroup {
  const factory CourseGroup({
    required String id,
    required String name,
    String? description,
    String? shortDescription,
    String? subtitle,
    String? image,
    String? thumbImage,
    ImagePosition? imagePosition,
    int? order,
    @Default(true) bool active,
    DisplayStatus? displayStatus,
    DanceType? danceType,
    Level? level,
    @Default([]) List<AttendanceType> attendanceTypes,
    int? ageFrom,
    int? ageTo,
    
    // Course relationships
    @Default([]) List<Course> courses,
    int? totalCourses,
    int? availableCourses,
    
    // Pricing information
    int? totalPrice,
    int? discountedPrice,
    int? bundleDiscount,
    
    // Scheduling
    DateTime? startDate,
    DateTime? endDate,
    int? durationWeeks,
    
    // Prerequisites and progression
    List<String>? prerequisites,
    List<String>? progression,
    String? skillsLearned,
    
    // Metadata
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    List<String>? tags,
  }) = _CourseGroup;

  factory CourseGroup.fromJson(Map<String, dynamic> json) =>
      _$CourseGroupFromJson(json);
}

/// Extension methods for course group utilities
extension CourseGroupExtensions on CourseGroup {
  /// Check if the course group is available for booking
  bool get isAvailable {
    return active && 
           displayStatus == DisplayStatus.published &&
           courses.any((course) => course.isAvailable);
  }

  /// Get the lowest price from all courses in the group
  int? get minPrice {
    if (courses.isEmpty) return null;
    
    final prices = courses
        .where((course) => course.isAvailable)
        .map((course) => course.effectivePrice)
        .where((price) => price > 0);
    
    return prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
  }

  /// Get the highest price from all courses in the group
  int? get maxPrice {
    if (courses.isEmpty) return null;
    
    final prices = courses
        .where((course) => course.isAvailable)
        .map((course) => course.effectivePrice)
        .where((price) => price > 0);
    
    return prices.isEmpty ? null : prices.reduce((a, b) => a > b ? a : b);
  }

  /// Get price range display text
  String? get priceRangeDisplay {
    final min = minPrice;
    final max = maxPrice;
    
    if (min == null && max == null) return null;
    if (min == max) return '£$min';
    return '£$min - £$max';
  }

  /// Get courses available for a specific age group
  List<Course> coursesForAge(int age) {
    return courses.where((course) {
      if (course.ageFrom != null && age < course.ageFrom!) return false;
      if (course.ageTo != null && age > course.ageTo!) return false;
      return true;
    }).toList();
  }

  /// Get courses for children
  List<Course> get coursesForChildren {
    return courses.where((course) => course.isForChildren).toList();
  }

  /// Get courses for adults
  List<Course> get coursesForAdults {
    return courses.where((course) => course.isForAdults).toList();
  }

  /// Get courses by level
  List<Course> coursesForLevel(Level level) {
    return courses.where((course) => course.level == level).toList();
  }

  /// Get courses by dance type
  List<Course> coursesForDanceType(DanceType danceType) {
    return courses.where((course) => course.danceType == danceType).toList();
  }

  /// Get available course levels
  Set<Level> get availableLevels {
    return courses
        .where((course) => course.level != null)
        .map((course) => course.level!)
        .toSet();
  }

  /// Get available dance types
  Set<DanceType> get availableDanceTypes {
    return courses
        .where((course) => course.danceType != null)
        .map((course) => course.danceType!)
        .toSet();
  }

  /// Check if the group offers courses for families
  bool get isFamilyFriendly {
    return attendanceTypes.contains(AttendanceType.families) ||
           courses.any((course) => 
               course.attendanceTypes.contains(AttendanceType.families));
  }

  /// Get the number of available courses
  int get availableCoursesCount {
    return courses.where((course) => course.isAvailable).length;
  }

  /// Check if the group has any ongoing courses
  bool get hasOngoingCourses {
    return courses.any((course) => course.hasStarted && !course.hasEnded);
  }

  /// Check if the group has any upcoming courses
  bool get hasUpcomingCourses {
    return courses.any((course) => !course.hasStarted);
  }

  /// Get the earliest start date from all courses
  DateTime? get earliestStartDate {
    final startDates = courses
        .where((course) => course.startDateTime != null)
        .map((course) => course.startDateTime!)
        .toList();
    
    if (startDates.isEmpty) return null;
    
    startDates.sort();
    return startDates.first;
  }

  /// Get the latest end date from all courses
  DateTime? get latestEndDate {
    final endDates = courses
        .where((course) => course.endDateTime != null)
        .map((course) => course.endDateTime!)
        .toList();
    
    if (endDates.isEmpty) return null;
    
    endDates.sort();
    return endDates.last;
  }

  /// Get total duration in weeks for the entire group
  int? get totalDurationWeeks {
    final earliest = earliestStartDate;
    final latest = latestEndDate;
    
    if (earliest != null && latest != null) {
      return latest.difference(earliest).inDays ~/ 7;
    }
    
    return durationWeeks;
  }

  /// Check if registration is open
  bool get isRegistrationOpen {
    return isAvailable && hasUpcomingCourses;
  }

  /// Get summary statistics
  Map<String, dynamic> get statistics {
    return {
      'totalCourses': courses.length,
      'availableCourses': availableCoursesCount,
      'ongoingCourses': courses.where((c) => c.hasStarted && !c.hasEnded).length,
      'upcomingCourses': courses.where((c) => !c.hasStarted).length,
      'completedCourses': courses.where((c) => c.hasEnded).length,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'averagePrice': courses.isEmpty ? null : 
          courses.map((c) => c.effectivePrice).reduce((a, b) => a + b) / courses.length,
      'totalDuration': totalDurationWeeks,
      'levels': availableLevels.length,
      'danceTypes': availableDanceTypes.length,
    };
  }

  /// Get age range description for the group
  String? get ageRangeDescription {
    if (ageFrom != null && ageTo != null) {
      return '$ageFrom-$ageTo years';
    }
    
    // Calculate from courses if not set at group level
    final ages = <int>[];
    for (final course in courses) {
      if (course.ageFrom != null) ages.add(course.ageFrom!);
      if (course.ageTo != null) ages.add(course.ageTo!);
    }
    
    if (ages.isEmpty) return null;
    
    ages.sort();
    final minAge = ages.first;
    final maxAge = ages.last;
    
    if (minAge == maxAge) return '$minAge years';
    return '$minAge-$maxAge years';
  }

  /// Check if the group is suitable for a specific age
  bool isSuitableForAge(int age) {
    // Check group-level age restrictions first
    if (ageFrom != null && age < ageFrom!) return false;
    if (ageTo != null && age > ageTo!) return false;
    
    // If no group-level restrictions, check if any course is suitable
    if (ageFrom == null && ageTo == null) {
      return courses.any((course) => 
          (course.ageFrom == null || age >= course.ageFrom!) &&
          (course.ageTo == null || age <= course.ageTo!));
    }
    
    return true;
  }
}