import 'date_utils.dart' as date_utils;
import '../../domain/entities/course.dart';

/// Schedule formatting utilities matching the website's formatScheduleForCard functionality
/// Based on UKCPA-Website/utils/scheduleUtils.ts
class ScheduleUtils {
  ScheduleUtils._();

  /// Format schedule information for course cards, matching website behavior
  static ScheduleInfo formatScheduleForCard(Course course) {
    // Extract schedule data from course
    final startDateTime = course.startDateTime;
    final endDateTime = course.endDateTime;
    final days = course.days;
    
    String timeText = '';
    String daysText = '';
    
    // Format time information
    if (startDateTime != null && endDateTime != null) {
      // Check if start and end are on same day (time range)
      if (startDateTime.day == endDateTime.day && 
          startDateTime.month == endDateTime.month && 
          startDateTime.year == endDateTime.year) {
        // Same day - show time range
        timeText = date_utils.DateUtils.getTimeRange(startDateTime, endDateTime);
      } else {
        // Different days - show individual times
        timeText = date_utils.DateUtils.getTimeFromDate(startDateTime);
      }
    }
    
    // Format days information
    if (days != null && days.isNotEmpty) {
      daysText = _formatDaysForCard(days);
    } else if (startDateTime != null) {
      // Fallback to day from start date
      daysText = date_utils.DateUtils.getDayFromDate(startDateTime);
    }
    
    return ScheduleInfo(
      timeText: timeText,
      daysText: daysText,
      fullScheduleText: _buildFullScheduleText(timeText, daysText),
    );
  }

  /// Format days array for display in cards
  static String _formatDaysForCard(List<String> days) {
    if (days.isEmpty) return '';
    
    // Convert full day names to short forms
    final shortDays = days.map(_getDayAbbreviation).toList();
    
    // Handle common patterns
    if (shortDays.length == 1) {
      return shortDays.first;
    } else if (shortDays.length == 2) {
      return shortDays.join(' & ');
    } else if (shortDays.length <= 3) {
      return shortDays.join(', ');
    } else {
      // Many days - show first few + count
      return '${shortDays.take(2).join(', ')} + ${shortDays.length - 2} more';
    }
  }

  /// Convert full day name to abbreviation
  static String _getDayAbbreviation(String day) {
    final dayLower = day.toLowerCase();
    if (dayLower.contains('monday') || dayLower.contains('mon')) return 'Mon';
    if (dayLower.contains('tuesday') || dayLower.contains('tue')) return 'Tue';
    if (dayLower.contains('wednesday') || dayLower.contains('wed')) return 'Wed';
    if (dayLower.contains('thursday') || dayLower.contains('thu')) return 'Thu';
    if (dayLower.contains('friday') || dayLower.contains('fri')) return 'Fri';
    if (dayLower.contains('saturday') || dayLower.contains('sat')) return 'Sat';
    if (dayLower.contains('sunday') || dayLower.contains('sun')) return 'Sun';
    
    // Return first 3 characters if no match
    return day.length >= 3 ? day.substring(0, 3) : day;
  }

  /// Build full schedule text combining days and times
  static String _buildFullScheduleText(String timeText, String daysText) {
    if (daysText.isNotEmpty && timeText.isNotEmpty) {
      return '$daysText at $timeText';
    } else if (daysText.isNotEmpty) {
      return daysText;
    } else if (timeText.isNotEmpty) {
      return timeText;
    } else {
      return 'Schedule TBD';
    }
  }

  /// Format course duration for display
  static String formatCourseDuration(Course course) {
    if (course.weeks != null && course.weeks! > 0) {
      return course.weeks == 1 ? '1 week' : '${course.weeks} weeks';
    } else if (course.startDateTime != null && course.endDateTime != null) {
      return date_utils.DateUtils.getDurationString(
        course.startDateTime!, 
        course.endDateTime!
      );
    } else {
      return 'Duration TBD';
    }
  }

  /// Check if course has specific schedule information
  static bool hasScheduleInfo(Course course) {
    return course.startDateTime != null || 
           course.endDateTime != null || 
           (course.days != null && course.days!.isNotEmpty);
  }

  /// Get display text for course availability status
  static String getAvailabilityText(Course course) {
    if (course.fullyBooked) {
      return 'Fully booked';
    } else if (course.availableSpaces != null && course.totalSpaces != null) {
      if (course.availableSpaces! <= 2) {
        return '${course.availableSpaces} spaces left';
      } else {
        return '${course.availableSpaces} available';
      }
    } else if (!course.active) {
      return 'Not available';
    } else {
      return 'Available';
    }
  }

  /// Format level display matching website style
  static String formatLevelDisplay(Level? level) {
    if (level == null) return 'All levels';
    
    switch (level) {
      case Level.beginner:
        return 'Beginner';
      case Level.intermediate:
        return 'Intermediate';
      case Level.advanced:
        return 'Advanced';
      case Level.kidsFoundation:
        return 'Kids Foundation';
      case Level.kids1:
        return 'Kids 1';
      case Level.kids2:
        return 'Kids 2';
    }
  }

  /// Format attendance types for age group display
  static String formatAttendanceTypes(List<AttendanceType> attendanceTypes, {int? ageFrom, int? ageTo}) {
    // If specific ages provided, use those
    if (ageFrom != null && ageTo != null) {
      return '$ageFrom-$ageTo years';
    } else if (ageFrom != null) {
      return '$ageFrom+ years';
    } else if (ageTo != null) {
      return 'Up to $ageTo years';
    }
    
    // Otherwise format attendance types
    if (attendanceTypes.isEmpty) return 'All ages';
    
    final formattedTypes = attendanceTypes.map((type) {
      switch (type) {
        case AttendanceType.children:
          return 'Children';
        case AttendanceType.adults:
          return 'Adults';
      }
    }).toList();
    
    if (formattedTypes.length == 1) {
      return formattedTypes.first;
    } else {
      return formattedTypes.join(' & ');
    }
  }
}

/// Schedule information for course cards
class ScheduleInfo {
  final String timeText;
  final String daysText;
  final String fullScheduleText;
  
  const ScheduleInfo({
    required this.timeText,
    required this.daysText,
    required this.fullScheduleText,
  });
}

/// Extension methods for Course to add schedule-related convenience methods
extension CourseScheduleExtensions on Course {
  /// Get formatted schedule info for this course
  ScheduleInfo get scheduleInfo => ScheduleUtils.formatScheduleForCard(this);
  
  /// Get formatted duration for this course
  String get formattedDuration => ScheduleUtils.formatCourseDuration(this);
  
  /// Check if this course has schedule information
  bool get hasScheduleInfo => ScheduleUtils.hasScheduleInfo(this);
  
  /// Get availability status text
  String get availabilityText => ScheduleUtils.getAvailabilityText(this);
  
  /// Get formatted level display
  String get levelDisplay => ScheduleUtils.formatLevelDisplay(level);
  
  /// Get formatted age group display
  String get ageGroupDisplay => ScheduleUtils.formatAttendanceTypes(
    attendanceTypes, 
    ageFrom: ageFrom, 
    ageTo: ageTo
  );
}