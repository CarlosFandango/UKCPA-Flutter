import 'package:intl/intl.dart';

/// Date utility functions matching the website's date formatting
class DateUtils {
  DateUtils._();

  /// Format date as "1 Jan 2024"
  static String getDateString(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  /// Get day name from date (e.g., "Monday")
  static String getDayFromDate(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Format time as "10:00"
  static String getTimeFromDate(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format time range as "10:00 - 11:30"
  static String getTimeRange(DateTime startTime, DateTime endTime) {
    final start = getTimeFromDate(startTime);
    final end = getTimeFromDate(endTime);
    return '$start - $end';
  }

  /// Format date with day name as "Monday, 1 Jan 2024"
  static String getDateWithDay(DateTime date) {
    final day = getDayFromDate(date);
    final dateStr = getDateString(date);
    return '$day, $dateStr';
  }

  /// Format date range as "1 Jan - 15 Jan 2024"
  static String getDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      // Same month: "1 - 15 Jan 2024"
      final startDay = DateFormat('d').format(startDate);
      final endFormat = DateFormat('d MMM yyyy').format(endDate);
      return '$startDay - $endFormat';
    } else if (startDate.year == endDate.year) {
      // Same year, different month: "1 Jan - 15 Feb 2024"
      final startFormat = DateFormat('d MMM').format(startDate);
      final endFormat = DateFormat('d MMM yyyy').format(endDate);
      return '$startFormat - $endFormat';
    } else {
      // Different years: "1 Jan 2024 - 15 Feb 2025"
      final startFormat = DateFormat('d MMM yyyy').format(startDate);
      final endFormat = DateFormat('d MMM yyyy').format(endDate);
      return '$startFormat - $endFormat';
    }
  }

  /// Format session date and time for dropdown options
  /// e.g., "Monday, 1 Jan 2024 at 10:00"
  static String getSessionDisplayString(DateTime dateTime) {
    final day = getDayFromDate(dateTime);
    final date = getDateString(dateTime);
    final time = getTimeFromDate(dateTime);
    return '$day, $date at $time';
  }

  /// Format course duration display
  /// e.g., "6 weeks" or "1 day"
  static String getDurationString(DateTime startDate, DateTime endDate) {
    final duration = endDate.difference(startDate);
    final days = duration.inDays + 1; // Include both start and end days
    
    if (days == 1) {
      return '1 day';
    } else if (days % 7 == 0) {
      final weeks = days ~/ 7;
      return weeks == 1 ? '1 week' : '$weeks weeks';
    } else if (days < 7) {
      return '$days days';
    } else {
      final weeks = days ~/ 7;
      final remainingDays = days % 7;
      if (remainingDays == 0) {
        return weeks == 1 ? '1 week' : '$weeks weeks';
      } else {
        return '$weeks weeks, $remainingDays days';
      }
    }
  }

  /// Check if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if a date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && 
           date.month == tomorrow.month && 
           date.day == tomorrow.day;
  }

  /// Get relative date string (Today, Tomorrow, or formatted date)
  static String getRelativeDateString(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      return getDateString(date);
    }
  }

  /// Format date for display in course cards
  /// e.g., "Today at 10:00" or "Mon, 1 Jan at 10:00"
  static String getCourseCardDateString(DateTime dateTime) {
    if (isToday(dateTime)) {
      return 'Today at ${getTimeFromDate(dateTime)}';
    } else if (isTomorrow(dateTime)) {
      return 'Tomorrow at ${getTimeFromDate(dateTime)}';
    } else {
      final dayShort = DateFormat('E').format(dateTime); // Mon, Tue, etc.
      final date = DateFormat('d MMM').format(dateTime);
      final time = getTimeFromDate(dateTime);
      return '$dayShort, $date at $time';
    }
  }

  /// Check if a course/session is happening soon (within next 2 hours)
  static bool isHappeningSoon(DateTime startTime) {
    final now = DateTime.now();
    final timeDiff = startTime.difference(now);
    return timeDiff.inMinutes > 0 && timeDiff.inHours < 2;
  }

  /// Check if a course/session is currently active
  static bool isCurrentlyActive(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Format age range display
  static String formatAgeRange(int? ageFrom, int? ageTo) {
    if (ageFrom != null && ageTo != null) {
      return '$ageFrom-$ageTo years';
    } else if (ageFrom != null) {
      return '$ageFrom+ years';
    } else if (ageTo != null) {
      return 'Up to $ageTo years';
    } else {
      return 'All ages';
    }
  }
}