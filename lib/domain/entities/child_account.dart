import 'package:freezed_annotation/freezed_annotation.dart';

part 'child_account.freezed.dart';
part 'child_account.g.dart';

/// Child account entity for managing children's profile information
/// and course enrollments
@freezed
class ChildAccount with _$ChildAccount {
  const factory ChildAccount({
    required String id,
    required String parentId,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    String? profileImageUrl,
    String? nickname,
    String? schoolName,
    String? schoolYear,
    ChildGender? gender,
    // Medical and emergency information
    String? medicalConditions,
    String? allergies,
    String? medications,
    String? dietaryRequirements,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    // Dance experience and preferences
    @Default([]) List<String> danceExperience, // Ballet, Jazz, Contemporary, etc.
    Level? currentLevel, // Beginner, Intermediate, Advanced
    String? previousInstructor,
    String? specialNeeds,
    String? parentNotes,
    // Administrative
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Course enrollment tracking
    @Default([]) List<String> enrolledCourseIds,
    @Default([]) List<String> completedCourseIds,
    @Default([]) List<String> favouriteCourseIds,
  }) = _ChildAccount;
  
  factory ChildAccount.fromJson(Map<String, dynamic> json) => _$ChildAccountFromJson(json);
}

/// Emergency contact information for a child
@freezed
class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    required String id,
    required String name,
    required String phone,
    required String relationship,
    String? email,
    bool? isPrimary,
    String? notes,
  }) = _EmergencyContact;
  
  factory EmergencyContact.fromJson(Map<String, dynamic> json) => _$EmergencyContactFromJson(json);
}

/// Medical information for a child
@freezed
class MedicalInformation with _$MedicalInformation {
  const factory MedicalInformation({
    String? conditions,
    String? allergies,
    String? medications,
    String? dietaryRequirements,
    String? doctorName,
    String? doctorPhone,
    String? insuranceProvider,
    String? insuranceNumber,
    DateTime? lastUpdated,
    String? notes,
  }) = _MedicalInformation;
  
  factory MedicalInformation.fromJson(Map<String, dynamic> json) => _$MedicalInformationFromJson(json);
}

enum ChildGender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('other')
  other,
  @JsonValue('prefer_not_to_say')
  preferNotToSay,
}

enum Level {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
  @JsonValue('professional')
  professional,
}

// Extension methods for ChildAccount
extension ChildAccountExtensions on ChildAccount {
  /// Get the child's full name
  String get fullName => '$firstName $lastName';
  
  /// Get the display name (nickname if available, otherwise full name)
  String get displayName => nickname?.isNotEmpty == true ? nickname! : fullName;
  
  /// Calculate child's current age
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
  
  /// Check if child is old enough for a specific age requirement
  bool isOldEnoughFor(int minimumAge) => age >= minimumAge;
  
  /// Get age category for course filtering
  AgeCategory get ageCategory {
    if (age <= 5) return AgeCategory.preschool;
    if (age <= 8) return AgeCategory.children;
    if (age <= 12) return AgeCategory.juniors;
    if (age <= 17) return AgeCategory.teens;
    return AgeCategory.adults;
  }
  
  /// Check if child has medical conditions that need attention
  bool get hasMedicalConditions {
    return medicalConditions?.isNotEmpty == true ||
           allergies?.isNotEmpty == true ||
           medications?.isNotEmpty == true;
  }
  
  /// Check if child has emergency contact information
  bool get hasEmergencyContact {
    return emergencyContactName?.isNotEmpty == true &&
           emergencyContactPhone?.isNotEmpty == true;
  }
  
  /// Get formatted emergency contact info
  String? get formattedEmergencyContact {
    if (!hasEmergencyContact) return null;
    final relationship = emergencyContactRelationship?.isNotEmpty == true 
        ? ' ($emergencyContactRelationship)'
        : '';
    return '$emergencyContactName$relationship - $emergencyContactPhone';
  }
  
  /// Check if profile has complete required information
  bool get hasCompleteProfile {
    return firstName.isNotEmpty &&
           lastName.isNotEmpty &&
           hasEmergencyContact;
  }
  
  /// Get dance experience as formatted string
  String get formattedDanceExperience {
    if (danceExperience.isEmpty) return 'No previous experience';
    return danceExperience.join(', ');
  }
  
  /// Get current level display name
  String get levelDisplayName {
    switch (currentLevel) {
      case Level.beginner:
        return 'Beginner';
      case Level.intermediate:
        return 'Intermediate';
      case Level.advanced:
        return 'Advanced';
      case Level.professional:
        return 'Professional';
      case null:
        return 'Not specified';
    }
  }
  
  /// Check if child is currently enrolled in any courses
  bool get hasActiveCourses => enrolledCourseIds.isNotEmpty;
  
  /// Get total number of completed courses
  int get completedCoursesCount => completedCourseIds.length;
}

enum AgeCategory {
  preschool,  // 0-5
  children,   // 6-8
  juniors,    // 9-12
  teens,      // 13-17
  adults,     // 18+
}