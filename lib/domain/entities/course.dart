import 'package:freezed_annotation/freezed_annotation.dart';
import 'course_session.dart';
import 'course_group.dart';

part 'course.freezed.dart';
part 'course.g.dart';

/// Dance types supported by the app
enum DanceType {
  @JsonValue('CHINESE')
  chinese,
  @JsonValue('BALLET')
  ballet,
  @JsonValue('LATIN')
  latin,
  @JsonValue('KPOP')
  kpop,
  @JsonValue('BELLY')
  belly,
  @JsonValue('JAZZ')
  jazz,
  @JsonValue('HIPHOP')
  hiphop,
}

/// Course difficulty levels
enum Level {
  @JsonValue('BEGINNER')
  beginner,
  @JsonValue('INTERMEDIATE')
  intermediate,
  @JsonValue('ADVANCED')
  advanced,
  @JsonValue('KIDS_FOUNDATION')
  kidsFoundation,
  @JsonValue('KIDS_1')
  kids1,
  @JsonValue('KIDS_2')
  kids2,
}

/// Types of attendance supported
enum AttendanceType {
  @JsonValue('CHILDREN')
  children,
  @JsonValue('ADULTS')
  adults,
}

/// Course display status
enum DisplayStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('PUBLISHED')
  published,
  @JsonValue('ARCHIVED')
  archived,
}

/// Course list display styles
enum CourseListStyle {
  @JsonValue('STANDARD')
  standard,
  @JsonValue('FEATURED')
  featured,
  @JsonValue('COMPACT')
  compact,
}

/// Location types for courses
enum Location {
  @JsonValue('ONLINE')
  online,
  @JsonValue('STUDIO_1')
  studio1,
  @JsonValue('STUDIO_2')
  studio2,
  @JsonValue('EXTERNAL')
  external,
}


/// Address information for studio courses
@freezed
class Address with _$Address {
  const factory Address({
    String? line1,
    String? line2,
    String? postCode,
    String? city,
    String? county,
    String? country,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}

/// Zoom meeting details for online courses
@freezed
class ZoomMeeting with _$ZoomMeeting {
  const factory ZoomMeeting({
    required String meetingId,
    String? password,
    String? joinUrl,
  }) = _ZoomMeeting;

  factory ZoomMeeting.fromJson(Map<String, dynamic> json) =>
      _$ZoomMeetingFromJson(json);
}

/// Video content associated with courses
@freezed
class Video with _$Video {
  const factory Video({
    required String id,
    required String name,
    String? description,
    required String url,
    String? provider,
    String? thumbnailUrl,
    int? duration,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) =>
      _$VideoFromJson(json);
}

/// Base course entity with common properties
@freezed
class Course with _$Course {
  const factory Course({
    required String id,
    required String name,
    String? subtitle,
    CourseGroup? courseGroup,
    int? ageFrom,
    int? ageTo,
    @Default(true) bool active,
    Level? level,
    required int price,
    int? originalPrice,
    int? currentPrice,
    int? depositPrice,
    @Default(false) bool fullyBooked,
    String? thumbImage,
    String? image,
    ImagePosition? imagePosition,
    String? shortDescription,
    String? description,
    @Default([AttendanceType.adults]) List<AttendanceType> attendanceTypes,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? weeks,
    int? order,
    CourseListStyle? listStyle,
    List<String>? days,
    Location? location,
    DanceType? danceType,
    @Default([]) List<Video> videos,
    @Default(false) bool hasTasterClasses,
    @Default(0) int tasterPrice,
    @Default(false) bool isAcceptingDeposits,
    @Default([]) List<CourseSession> futureCourseSessions,
    @Default([]) List<CourseSession> sessions,
    String? instructions,
    Address? address,
    DisplayStatus? displayStatus,
    @Default('StudioCourse') String type,
    
    // Studio course specific fields
    String? studioInstructions,
    
    // Online course specific fields  
    ZoomMeeting? zoomMeeting,
    bool? requiresEnrollment,
    
    // Calculated fields
    bool? isFuture,
    bool? isPast,
    bool? isOngoing,
    int? availableSpaces,
    int? totalSpaces,
    double? completionPercentage,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) =>
      _$CourseFromJson(json);
}

/// Studio course variant with physical location
@freezed
class StudioCourse with _$StudioCourse {
  const factory StudioCourse({
    required String id,
    required String name,
    String? subtitle,
    CourseGroup? courseGroup,
    int? ageFrom,
    int? ageTo,
    @Default(true) bool active,
    Level? level,
    required int price,
    int? originalPrice,
    int? currentPrice,
    int? depositPrice,
    @Default(false) bool fullyBooked,
    String? thumbImage,
    String? image,
    ImagePosition? imagePosition,
    String? shortDescription,
    String? description,
    @Default([AttendanceType.adults]) List<AttendanceType> attendanceTypes,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? weeks,
    int? order,
    CourseListStyle? listStyle,
    List<String>? days,
    required Location location,
    DanceType? danceType,
    @Default([]) List<Video> videos,
    @Default(false) bool hasTasterClasses,
    @Default(0) int tasterPrice,
    @Default(false) bool isAcceptingDeposits,
    @Default([]) List<CourseSession> futureCourseSessions,
    @Default([]) List<CourseSession> sessions,
    String? instructions,
    required Address address,
    DisplayStatus? displayStatus,
    
    // Studio-specific fields
    String? studioInstructions,
    String? equipment,
    String? parkingInfo,
    String? accessibilityInfo,
  }) = _StudioCourse;

  factory StudioCourse.fromJson(Map<String, dynamic> json) =>
      _$StudioCourseFromJson(json);
}

/// Online course variant with virtual delivery
@freezed
class OnlineCourse with _$OnlineCourse {
  const factory OnlineCourse({
    required String id,
    required String name,
    String? subtitle,
    CourseGroup? courseGroup,
    int? ageFrom,
    int? ageTo,
    @Default(true) bool active,
    Level? level,
    required int price,
    int? originalPrice,
    int? currentPrice,
    int? depositPrice,
    @Default(false) bool fullyBooked,
    String? thumbImage,
    String? image,
    ImagePosition? imagePosition,
    String? shortDescription,
    String? description,
    @Default([AttendanceType.adults]) List<AttendanceType> attendanceTypes,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? weeks,
    int? order,
    CourseListStyle? listStyle,
    List<String>? days,
    @Default(Location.online) Location location,
    DanceType? danceType,
    @Default([]) List<Video> videos,
    @Default(false) bool hasTasterClasses,
    @Default(0) int tasterPrice,
    @Default(false) bool isAcceptingDeposits,
    @Default([]) List<CourseSession> futureCourseSessions,
    @Default([]) List<CourseSession> sessions,
    String? instructions,
    DisplayStatus? displayStatus,
    
    // Online-specific fields
    ZoomMeeting? zoomMeeting,
    bool? requiresEnrollment,
    String? technicalRequirements,
    String? platformInstructions,
    List<String>? recordingUrls,
  }) = _OnlineCourse;

  factory OnlineCourse.fromJson(Map<String, dynamic> json) =>
      _$OnlineCourseFromJson(json);
}

/// Extension methods for course utilities
extension CourseExtensions on Course {
  /// Check if the course is currently available for booking
  bool get isAvailable {
    return active && 
           displayStatus == DisplayStatus.published && 
           !fullyBooked &&
           (startDateTime == null || startDateTime!.isAfter(DateTime.now()));
  }

  /// Get the effective price (current price if available, otherwise original price)
  int get effectivePrice {
    return currentPrice ?? price;
  }

  /// Check if the course offers taster classes
  bool get offersTasterClasses {
    return hasTasterClasses && tasterPrice > 0;
  }

  /// Get the discounted amount
  int? get discountAmount {
    if (originalPrice != null && currentPrice != null) {
      return originalPrice! - currentPrice!;
    }
    return null;
  }

  /// Check if the course has a discount
  bool get hasDiscount {
    return discountAmount != null && discountAmount! > 0;
  }

  /// Get discount percentage
  double? get discountPercentage {
    if (originalPrice != null && discountAmount != null && originalPrice! > 0) {
      return (discountAmount! / originalPrice!) * 100;
    }
    return null;
  }

  /// Check if course is for children
  bool get isForChildren {
    return attendanceTypes.contains(AttendanceType.children) ||
           (ageFrom != null && ageTo != null && ageTo! <= 16);
  }

  /// Check if course is for adults
  bool get isForAdults {
    return attendanceTypes.contains(AttendanceType.adults) ||
           (ageFrom != null && ageFrom! >= 16);
  }


  /// Get age range description
  String? get ageRangeDescription {
    if (ageFrom != null && ageTo != null) {
      return '$ageFrom-$ageTo years';
    } else if (ageFrom != null) {
      return '$ageFrom+ years';
    } else if (ageTo != null) {
      return 'Up to $ageTo years';
    }
    return null;
  }

  /// Get the number of upcoming sessions
  int get upcomingSessionCount {
    return futureCourseSessions.length;
  }

  /// Check if the course has started
  bool get hasStarted {
    return startDateTime != null && DateTime.now().isAfter(startDateTime!);
  }

  /// Check if the course has ended
  bool get hasEnded {
    return endDateTime != null && DateTime.now().isAfter(endDateTime!);
  }

  /// Get course duration in days
  int? get durationInDays {
    if (startDateTime != null && endDateTime != null) {
      return endDateTime!.difference(startDateTime!).inDays + 1;
    }
    return null;
  }
}