import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    String? profileImageUrl,
    String? phone,
    String? mobilePhone,
    @Default([]) List<Address> addresses,
    String? stripeCustomerId,
    @Default([]) List<String> roles,
    DateTime? dateOfBirth,
    String? parentId,
    @Default([]) List<User> children,
    // Enhanced profile fields for Phase 5
    String? title, // Mr, Mrs, Ms, Dr, etc.
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? medicalNotes,
    String? dietaryRequirements,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(true) bool isActive,
    String? notes, // Staff notes
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Address with _$Address {
  const factory Address({
    String? id,
    String? name, // e.g., "Home", "Work"
    String? line1,
    String? line2,
    String? city,
    String? county,
    String? country,
    String? postCode,
    String? countryCode, // ISO country code
    @Default(false) bool isDefault,
    @Default(AddressType.home) AddressType type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Address;
  
  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
}

@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default(true) bool emailNotifications,
    @Default(true) bool smsNotifications,
    @Default(true) bool marketingEmails,
    @Default(true) bool classReminders,
    @Default(true) bool paymentReminders,
    @Default('en') String preferredLanguage,
    @Default('GBP') String preferredCurrency,
    @Default('Europe/London') String timeZone,
  }) = _UserPreferences;
  
  factory UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);
}

enum AddressType {
  @JsonValue('home')
  home,
  @JsonValue('work') 
  work,
  @JsonValue('billing')
  billing,
  @JsonValue('other')
  other,
}

// Extension methods for User entity
extension UserExtensions on User {
  /// Get the user's full name
  String get fullName => '$firstName $lastName';
  
  /// Get the user's display name (includes title if available)
  String get displayName {
    if (title?.isNotEmpty == true) {
      return '$title $firstName $lastName';
    }
    return fullName;
  }
  
  /// Check if user has complete profile information
  bool get hasCompleteProfile {
    return firstName.isNotEmpty &&
           lastName.isNotEmpty &&
           email.isNotEmpty &&
           phone?.isNotEmpty == true &&
           addresses.isNotEmpty;
  }
  
  /// Get the default address
  Address? get defaultAddress {
    if (addresses.isEmpty) return null;
    final defaultAddr = addresses.where((addr) => addr.isDefault).firstOrNull;
    return defaultAddr ?? addresses.first;
  }
  
  /// Get billing address (or default if no billing address exists)
  Address? get billingAddress {
    if (addresses.isEmpty) return null;
    final billingAddr = addresses.where((addr) => addr.type == AddressType.billing).firstOrNull;
    return billingAddr ?? defaultAddress;
  }
  
  /// Check if user is a child account
  bool get isChild => parentId?.isNotEmpty == true;
  
  /// Check if user is a parent (has children)
  bool get isParent => children.isNotEmpty;
  
  /// Calculate user's age if date of birth is available
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
  
  /// Check if user has emergency contact information
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
}

// Extension methods for Address entity
extension AddressExtensions on Address {
  /// Get formatted address as a single line
  String get singleLine {
    final parts = <String>[];
    if (line1?.isNotEmpty == true) parts.add(line1!);
    if (line2?.isNotEmpty == true) parts.add(line2!);
    if (city?.isNotEmpty == true) parts.add(city!);
    if (county?.isNotEmpty == true) parts.add(county!);
    if (postCode?.isNotEmpty == true) parts.add(postCode!);
    return parts.join(', ');
  }
  
  /// Get formatted address as multiple lines
  List<String> get multiLine {
    final lines = <String>[];
    if (line1?.isNotEmpty == true) lines.add(line1!);
    if (line2?.isNotEmpty == true) lines.add(line2!);
    
    final cityCountyPostal = <String>[];
    if (city?.isNotEmpty == true) cityCountyPostal.add(city!);
    if (county?.isNotEmpty == true) cityCountyPostal.add(county!);
    if (postCode?.isNotEmpty == true) cityCountyPostal.add(postCode!);
    
    if (cityCountyPostal.isNotEmpty) {
      lines.add(cityCountyPostal.join(', '));
    }
    
    if (country?.isNotEmpty == true) lines.add(country!);
    
    return lines;
  }
  
  /// Check if address has minimum required fields
  bool get isComplete {
    return line1?.isNotEmpty == true &&
           city?.isNotEmpty == true &&
           postCode?.isNotEmpty == true;
  }
  
  /// Get display name for address (name or type)
  String get displayName {
    if (name?.isNotEmpty == true) return name!;
    switch (type) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.billing:
        return 'Billing';
      case AddressType.other:
        return 'Other';
    }
  }
}