import 'package:freezed_annotation/freezed_annotation.dart';
import 'course.dart';

part 'course_group.freezed.dart';
part 'course_group.g.dart';

/// A group of related courses, representing what users browse and select
/// Based exactly on CourseGroupFragment from the website GraphQL schema
@freezed
class CourseGroup with _$CourseGroup {
  const factory CourseGroup({
    required int id,
    required String name,
    String? thumbImage,
    String? image,
    ImagePosition? imagePosition,
    String? shortDescription,
    String? description,
    int? minOriginalPrice,
    int? maxOriginalPrice,
    int? minPrice,
    int? maxPrice,
    @Default([]) List<String> attendanceTypes,
    @Default([]) List<String> locations,
    String? danceType,
    @Default([]) List<String> courseTypes,
    @Default([]) List<Course> courses,
  }) = _CourseGroup;

  factory CourseGroup.fromJson(Map<String, dynamic> json) =>
      _$CourseGroupFromJson(json);
}

/// Image position for course group images
@freezed
class ImagePosition with _$ImagePosition {
  const factory ImagePosition({
    required double X,
    required double Y,
  }) = _ImagePosition;

  factory ImagePosition.fromJson(Map<String, dynamic> json) =>
      _$ImagePositionFromJson(json);
}

/// Extension methods for course group utilities
extension CourseGroupExtensions on CourseGroup {
  /// Check if the course group is available for booking
  bool get isAvailable {
    return courses.any((course) => course.isAvailable);
  }

  /// Get price range display text using the provided price fields
  String? get priceRangeDisplay {
    final min = minPrice;
    final max = maxPrice;
    
    if (min == null && max == null) return null;
    if (min == max) return '£${(min! / 100).toStringAsFixed(2)}';
    return '£${(min! / 100).toStringAsFixed(2)} - £${(max! / 100).toStringAsFixed(2)}';
  }

  /// Get original price range display text
  String? get originalPriceRangeDisplay {
    final min = minOriginalPrice;
    final max = maxOriginalPrice;
    
    if (min == null && max == null) return null;
    if (min == max) return '£${(min! / 100).toStringAsFixed(2)}';
    return '£${(min! / 100).toStringAsFixed(2)} - £${(max! / 100).toStringAsFixed(2)}';
  }

  /// Check if the group has discounted prices
  bool get hasDiscounts {
    return (minPrice != null && minOriginalPrice != null && minPrice! < minOriginalPrice!) ||
           (maxPrice != null && maxOriginalPrice != null && maxPrice! < maxOriginalPrice!);
  }

  /// Get courses for children based on attendance types
  List<Course> get coursesForChildren {
    return courses.where((course) => course.isForChildren).toList();
  }

  /// Get courses for adults based on attendance types
  List<Course> get coursesForAdults {
    return courses.where((course) => course.isForAdults).toList();
  }

  /// Check if the group offers courses for both children and adults
  bool get isFamilyFriendly {
    return attendanceTypes.contains('children') && attendanceTypes.contains('adults');
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

  /// Check if registration is open
  bool get isRegistrationOpen {
    return isAvailable && hasUpcomingCourses;
  }

  /// Check if the group has online courses
  bool get hasOnlineCourses {
    return courseTypes.contains('OnlineCourse');
  }

  /// Check if the group has studio courses
  bool get hasStudioCourses {
    return courseTypes.contains('StudioCourse');
  }

  /// Check if the group has mixed course types
  bool get hasMixedCourseTypes {
    return hasOnlineCourses && hasStudioCourses;
  }

  /// Get location display text
  String? get locationDisplay {
    if (locations.isEmpty) return null;
    if (locations.length == 1) return locations.first;
    return '${locations.length} locations';
  }

  /// Get course type display text
  String? get courseTypeDisplay {
    if (hasMixedCourseTypes) {
      return 'Online & Studio';
    } else if (hasOnlineCourses) {
      return 'Online';
    } else if (hasStudioCourses) {
      return 'Studio';
    }
    return null;
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
      'hasDiscounts': hasDiscounts,
      'attendanceTypes': attendanceTypes.length,
      'locations': locations.length,
      'courseTypes': courseTypes.length,
    };
  }

  /// Search within the course group's courses
  List<Course> searchCourses(String query) {
    if (query.trim().isEmpty) return courses;
    
    final lowerQuery = query.toLowerCase().trim();
    return courses.where((course) {
      return course.name.toLowerCase().contains(lowerQuery) ||
             course.subtitle?.toLowerCase().contains(lowerQuery) == true;
    }).toList();
  }
}