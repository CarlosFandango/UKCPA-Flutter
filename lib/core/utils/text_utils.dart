/// Text utility functions for formatting and display
class TextUtils {
  TextUtils._();

  /// Convert text to PascalCase (e.g., "hello world" -> "Hello World")
  static String toPascalCase(String text) {
    return text
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Convert text to camelCase (e.g., "hello world" -> "helloWorld")
  static String toCamelCase(String text) {
    final words = text.split(' ');
    if (words.isEmpty) return text;
    
    final first = words.first.toLowerCase();
    final rest = words.skip(1).map((word) => 
        word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}');
    
    return first + rest.join('');
  }

  /// Format location name for display
  static String formatLocationName(String location) {
    switch (location.toUpperCase()) {
      case 'ONLINE':
        return 'Online';
      case 'STUDIO_1':
      case 'STUDIO1':
        return 'Studio 1';
      case 'STUDIO_2':
      case 'STUDIO2':
        return 'Studio 2';
      case 'EXTERNAL':
        return 'External Venue';
      default:
        return toPascalCase(location.replaceAll('_', ' '));
    }
  }

  /// Format dance type for display
  static String formatDanceType(String danceType) {
    switch (danceType.toUpperCase()) {
      case 'CHINESE':
        return 'Chinese Dance';
      case 'BALLET':
        return 'Ballet';
      case 'LATIN':
        return 'Latin Dance';
      case 'KPOP':
        return 'K-Pop';
      case 'BELLY':
        return 'Belly Dance';
      case 'JAZZ':
        return 'Jazz';
      case 'HIPHOP':
        return 'Hip Hop';
      default:
        return toPascalCase(danceType.replaceAll('_', ' '));
    }
  }

  /// Format attendance type for display
  static String formatAttendanceType(String attendanceType) {
    switch (attendanceType.toUpperCase()) {
      case 'CHILDREN':
        return 'Children';
      case 'ADULTS':
        return 'Adults';
      default:
        return toPascalCase(attendanceType);
    }
  }

  /// Format level for display
  static String formatLevel(String level) {
    switch (level.toUpperCase()) {
      case 'BEGINNER':
        return 'Beginner';
      case 'INTERMEDIATE':
        return 'Intermediate';
      case 'ADVANCED':
        return 'Advanced';
      case 'KIDS_FOUNDATION':
        return 'Kids Foundation';
      case 'KIDS_1':
        return 'Kids Level 1';
      case 'KIDS_2':
        return 'Kids Level 2';
      default:
        return toPascalCase(level.replaceAll('_', ' '));
    }
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get initials from name (e.g., "John Doe" -> "JD")
  static String getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.isNotEmpty ? words.first[0].toUpperCase() : '';
    }
    return words.take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join('');
  }

  /// Format price display (pence to pounds)
  static String formatPrice(int priceInPence) {
    final pounds = priceInPence / 100;
    return '£${pounds.toStringAsFixed(2)}';
  }

  /// Format price range display
  static String formatPriceRange(int minPriceInPence, int maxPriceInPence) {
    if (minPriceInPence == maxPriceInPence) {
      return formatPrice(minPriceInPence);
    }
    return '${formatPrice(minPriceInPence)} - ${formatPrice(maxPriceInPence)}';
  }

  /// Join list items with proper grammar (e.g., ["A", "B", "C"] -> "A, B and C")
  static String joinWithAnd(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    if (items.length == 2) return '${items.first} and ${items.last}';
    
    final allButLast = items.take(items.length - 1).join(', ');
    return '$allButLast and ${items.last}';
  }

  /// Format course type display based on available course types
  static String formatCourseTypes(List<String> courseTypes) {
    if (courseTypes.isEmpty) return 'Course';
    
    final hasStudio = courseTypes.any((type) => type.contains('Studio'));
    final hasOnline = courseTypes.any((type) => type.contains('Online'));
    
    if (hasStudio && hasOnline) {
      return 'Online & Studio';
    } else if (hasOnline) {
      return 'Online';
    } else if (hasStudio) {
      return 'Studio';
    } else {
      return 'Course';
    }
  }

  /// Format location list for display
  static String formatLocationsList(List<String> locations) {
    if (locations.isEmpty) return '';
    
    final formatted = locations.map(formatLocationName).toList();
    return joinWithAnd(formatted);
  }

  /// Format attendance types list for display
  static String formatAttendanceTypesList(List<String> attendanceTypes) {
    if (attendanceTypes.isEmpty) return 'All';
    
    final formatted = attendanceTypes.map(formatAttendanceType).toList();
    return joinWithAnd(formatted);
  }

  /// Clean and format description text
  static String cleanDescription(String description) {
    return description
        .trim()
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Clean up multiple newlines
        .replaceAll(RegExp(r'[ \t]+'), ' '); // Clean up multiple spaces
  }

  /// Extract summary from description (first sentence or first 150 chars)
  static String extractSummary(String description, {int maxLength = 150}) {
    final cleaned = cleanDescription(description);
    
    // Try to find first sentence
    final sentenceEnd = RegExp(r'[.!?]\s').firstMatch(cleaned);
    if (sentenceEnd != null && sentenceEnd.end <= maxLength) {
      return cleaned.substring(0, sentenceEnd.end - 1).trim();
    }
    
    // Otherwise truncate at maxLength
    return truncate(cleaned, maxLength);
  }

  /// Format weeks display (e.g., 1 -> "1 week", 6 -> "6 weeks")
  static String formatWeeks(int weeks) {
    if (weeks == 1) return '1 week';
    return '$weeks weeks';
  }

  /// Pluralize word based on count
  static String pluralize(String word, int count) {
    if (count == 1) return word;
    
    // Simple pluralization rules
    if (word.endsWith('y')) return '${word.substring(0, word.length - 1)}ies';
    if (word.endsWith('s') || word.endsWith('x') || word.endsWith('ch') || word.endsWith('sh')) {
      return '${word}es';
    }
    return '${word}s';
  }

  /// Format course count display
  static String formatCourseCount(int count) {
    return '$count ${pluralize('course', count)}';
  }

  /// Format session count display
  static String formatSessionCount(int count) {
    return '$count ${pluralize('session', count)}';
  }

  /// Check if string contains only whitespace
  static bool isBlank(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Get safe string (return empty string if null)
  static String safe(String? text) {
    return text ?? '';
  }

  /// Capitalize first letter of string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}