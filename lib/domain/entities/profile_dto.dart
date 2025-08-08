import 'package:freezed_annotation/freezed_annotation.dart';
import 'user.dart';
import 'child_account.dart';

part 'profile_dto.freezed.dart';
part 'profile_dto.g.dart';

/// Data Transfer Object for updating user profile
@freezed
class UpdateProfileDto with _$UpdateProfileDto {
  const factory UpdateProfileDto({
    String? firstName,
    String? lastName,
    String? title,
    String? phone,
    String? mobilePhone,
    DateTime? dateOfBirth,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? medicalNotes,
    String? dietaryRequirements,
    UserPreferences? preferences,
    String? profileImageUrl,
  }) = _UpdateProfileDto;
  
  factory UpdateProfileDto.fromJson(Map<String, dynamic> json) => _$UpdateProfileDtoFromJson(json);
  
  /// Create DTO from existing user for editing
  factory UpdateProfileDto.fromUser(User user) {
    return UpdateProfileDto(
      firstName: user.firstName,
      lastName: user.lastName,
      title: user.title,
      phone: user.phone,
      mobilePhone: user.mobilePhone,
      dateOfBirth: user.dateOfBirth,
      emergencyContactName: user.emergencyContactName,
      emergencyContactPhone: user.emergencyContactPhone,
      emergencyContactRelationship: user.emergencyContactRelationship,
      medicalNotes: user.medicalNotes,
      dietaryRequirements: user.dietaryRequirements,
      preferences: user.preferences,
      profileImageUrl: user.profileImageUrl,
    );
  }
}

/// Data Transfer Object for creating/updating addresses
@freezed
class AddressDto with _$AddressDto {
  const factory AddressDto({
    String? id,
    String? name,
    required String line1,
    String? line2,
    required String city,
    String? county,
    String? country,
    required String postCode,
    String? countryCode,
    @Default(false) bool isDefault,
    @Default(AddressType.home) AddressType type,
  }) = _AddressDto;
  
  factory AddressDto.fromJson(Map<String, dynamic> json) => _$AddressDtoFromJson(json);
  
  /// Create DTO from existing address for editing
  factory AddressDto.fromAddress(Address address) {
    return AddressDto(
      id: address.id,
      name: address.name,
      line1: address.line1 ?? '',
      line2: address.line2,
      city: address.city ?? '',
      county: address.county,
      country: address.country,
      postCode: address.postCode ?? '',
      countryCode: address.countryCode,
      isDefault: address.isDefault,
      type: address.type,
    );
  }
  
  /// Convert DTO to Address entity
  Address toAddress() {
    return Address(
      id: id,
      name: name,
      line1: line1,
      line2: line2,
      city: city,
      county: county,
      country: country,
      postCode: postCode,
      countryCode: countryCode,
      isDefault: isDefault,
      type: type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

/// Data Transfer Object for creating/updating child accounts
@freezed
class ChildAccountDto with _$ChildAccountDto {
  const factory ChildAccountDto({
    String? id,
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    String? nickname,
    String? schoolName,
    String? schoolYear,
    ChildGender? gender,
    String? medicalConditions,
    String? allergies,
    String? medications,
    String? dietaryRequirements,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    @Default([]) List<String> danceExperience,
    Level? currentLevel,
    String? previousInstructor,
    String? specialNeeds,
    String? parentNotes,
    String? profileImageUrl,
  }) = _ChildAccountDto;
  
  factory ChildAccountDto.fromJson(Map<String, dynamic> json) => _$ChildAccountDtoFromJson(json);
  
  /// Create DTO from existing child account for editing
  factory ChildAccountDto.fromChildAccount(ChildAccount child) {
    return ChildAccountDto(
      id: child.id,
      firstName: child.firstName,
      lastName: child.lastName,
      dateOfBirth: child.dateOfBirth,
      nickname: child.nickname,
      schoolName: child.schoolName,
      schoolYear: child.schoolYear,
      gender: child.gender,
      medicalConditions: child.medicalConditions,
      allergies: child.allergies,
      medications: child.medications,
      dietaryRequirements: child.dietaryRequirements,
      emergencyContactName: child.emergencyContactName,
      emergencyContactPhone: child.emergencyContactPhone,
      emergencyContactRelationship: child.emergencyContactRelationship,
      danceExperience: child.danceExperience,
      currentLevel: child.currentLevel,
      previousInstructor: child.previousInstructor,
      specialNeeds: child.specialNeeds,
      parentNotes: child.parentNotes,
      profileImageUrl: child.profileImageUrl,
    );
  }
}

/// Response object for profile operations
@freezed
class ProfileOperationResult with _$ProfileOperationResult {
  const factory ProfileOperationResult({
    required bool success,
    String? message,
    String? errorCode,
    User? user,
    List<String>? errors,
  }) = _ProfileOperationResult;
  
  factory ProfileOperationResult.fromJson(Map<String, dynamic> json) => _$ProfileOperationResultFromJson(json);
  
  /// Create successful result
  factory ProfileOperationResult.success({
    User? user,
    String? message,
  }) {
    return ProfileOperationResult(
      success: true,
      user: user,
      message: message ?? 'Operation completed successfully',
    );
  }
  
  /// Create error result
  factory ProfileOperationResult.error({
    required String message,
    String? errorCode,
    List<String>? errors,
  }) {
    return ProfileOperationResult(
      success: false,
      message: message,
      errorCode: errorCode,
      errors: errors,
    );
  }
}

/// Response object for address operations
@freezed
class AddressOperationResult with _$AddressOperationResult {
  const factory AddressOperationResult({
    required bool success,
    String? message,
    String? errorCode,
    Address? address,
    List<Address>? addresses,
    List<String>? errors,
  }) = _AddressOperationResult;
  
  factory AddressOperationResult.fromJson(Map<String, dynamic> json) => _$AddressOperationResultFromJson(json);
  
  /// Create successful result
  factory AddressOperationResult.success({
    Address? address,
    List<Address>? addresses,
    String? message,
  }) {
    return AddressOperationResult(
      success: true,
      address: address,
      addresses: addresses,
      message: message ?? 'Address operation completed successfully',
    );
  }
  
  /// Create error result
  factory AddressOperationResult.error({
    required String message,
    String? errorCode,
    List<String>? errors,
  }) {
    return AddressOperationResult(
      success: false,
      message: message,
      errorCode: errorCode,
      errors: errors,
    );
  }
}

/// Response object for child account operations
@freezed
class ChildAccountOperationResult with _$ChildAccountOperationResult {
  const factory ChildAccountOperationResult({
    required bool success,
    String? message,
    String? errorCode,
    ChildAccount? childAccount,
    List<ChildAccount>? children,
    List<String>? errors,
  }) = _ChildAccountOperationResult;
  
  factory ChildAccountOperationResult.fromJson(Map<String, dynamic> json) => _$ChildAccountOperationResultFromJson(json);
  
  /// Create successful result
  factory ChildAccountOperationResult.success({
    ChildAccount? childAccount,
    List<ChildAccount>? children,
    String? message,
  }) {
    return ChildAccountOperationResult(
      success: true,
      childAccount: childAccount,
      children: children,
      message: message ?? 'Child account operation completed successfully',
    );
  }
  
  /// Create error result
  factory ChildAccountOperationResult.error({
    required String message,
    String? errorCode,
    List<String>? errors,
  }) {
    return ChildAccountOperationResult(
      success: false,
      message: message,
      errorCode: errorCode,
      errors: errors,
    );
  }
}