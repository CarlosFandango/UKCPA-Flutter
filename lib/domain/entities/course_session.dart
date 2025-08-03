import 'package:freezed_annotation/freezed_annotation.dart';

part 'course_session.freezed.dart';
part 'course_session.g.dart';

/// Individual session of a course
@freezed
class CourseSession with _$CourseSession {
  const factory CourseSession({
    required String id,
    required String courseId,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? meetingId,
    int? price,
    @Default(false) bool purchasedCourse,
    String? sessionTitle,
    String? description,
    String? location,
    String? instructions,
    int? capacity,
    int? bookedCount,
    @Default(false) bool isCancelled,
    String? cancellationReason,
    DateTime? cancellationDate,
    
    // Online session specific
    String? zoomMeetingId,
    String? zoomPassword,
    String? recordingUrl,
    
    // Studio session specific
    String? room,
    String? equipment,
    
    // Status flags
    bool? isCompleted,
    bool? hasAttendance,
    
    // Metadata
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CourseSession;

  factory CourseSession.fromJson(Map<String, dynamic> json) =>
      _$CourseSessionFromJson(json);
}

/// Extension methods for course session utilities
extension CourseSessionExtensions on CourseSession {
  /// Check if the session is in the future
  bool get isFuture {
    return startDateTime.isAfter(DateTime.now());
  }

  /// Check if the session is in the past
  bool get isPast {
    return endDateTime.isBefore(DateTime.now());
  }

  /// Check if the session is currently ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }

  /// Get the duration of the session in minutes
  int get durationInMinutes {
    return endDateTime.difference(startDateTime).inMinutes;
  }

  /// Get the duration of the session in hours
  double get durationInHours {
    return durationInMinutes / 60.0;
  }

  /// Check if the session is fully booked
  bool get isFullyBooked {
    if (capacity != null && bookedCount != null) {
      return bookedCount! >= capacity!;
    }
    return false;
  }

  /// Get available spaces
  int? get availableSpaces {
    if (capacity != null && bookedCount != null) {
      return capacity! - bookedCount!;
    }
    return null;
  }

  /// Check if the session can be booked
  bool get canBeBooked {
    return !isCancelled && 
           isFuture && 
           !isFullyBooked;
  }

  /// Get status description
  String get statusDescription {
    if (isCancelled) return 'Cancelled';
    if (isPast) return 'Completed';
    if (isOngoing) return 'In Progress';
    if (isFullyBooked) return 'Fully Booked';
    return 'Available';
  }

  /// Format the session time for display
  String get timeDisplay {
    final start = startDateTime;
    final end = endDateTime;
    
    // If same day, show as "2:00 PM - 3:00 PM"
    if (start.day == end.day && start.month == end.month && start.year == end.year) {
      return '${_formatTime(start)} - ${_formatTime(end)}';
    }
    
    // If different days, show full date and time
    return '${_formatDateTime(start)} - ${_formatDateTime(end)}';
  }

  /// Format date for display
  String get dateDisplay {
    return _formatDate(startDateTime);
  }

  /// Get time until session starts (for upcoming sessions)
  Duration? get timeUntilStart {
    if (isFuture) {
      return startDateTime.difference(DateTime.now());
    }
    return null;
  }

  /// Get days until session starts
  int? get daysUntilStart {
    final timeUntil = timeUntilStart;
    if (timeUntil != null) {
      return timeUntil.inDays;
    }
    return null;
  }

  /// Check if session is today
  bool get isToday {
    final now = DateTime.now();
    final sessionDate = startDateTime;
    return now.day == sessionDate.day && 
           now.month == sessionDate.month && 
           now.year == sessionDate.year;
  }

  /// Check if session is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final sessionDate = startDateTime;
    return tomorrow.day == sessionDate.day && 
           tomorrow.month == sessionDate.month && 
           tomorrow.year == sessionDate.year;
  }

  /// Check if session is this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return startDateTime.isAfter(startOfWeek) && 
           startDateTime.isBefore(endOfWeek);
  }

  // Helper methods for formatting
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final month = months[dateTime.month - 1];
    return '$month ${dateTime.day}, ${dateTime.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }
}