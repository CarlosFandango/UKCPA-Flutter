import 'dart:io';
import '../entities/user.dart';
import '../entities/child_account.dart';
import '../entities/profile_dto.dart';

/// Repository interface for user profile management operations
abstract class ProfileRepository {
  // ============================================================================
  // USER PROFILE OPERATIONS
  // ============================================================================
  
  /// Get the current user's complete profile information
  Future<User?> getUserProfile();
  
  /// Update the current user's profile information
  Future<ProfileOperationResult> updateProfile(UpdateProfileDto dto);
  
  /// Update the current user's profile picture
  Future<ProfileOperationResult> updateProfilePicture(File imageFile);
  
  /// Delete the current user's profile picture
  Future<ProfileOperationResult> deleteProfilePicture();
  
  /// Update user preferences (notifications, language, etc.)
  Future<ProfileOperationResult> updatePreferences(UserPreferences preferences);
  
  // ============================================================================
  // ADDRESS MANAGEMENT OPERATIONS  
  // ============================================================================
  
  /// Get all addresses for the current user
  Future<List<Address>> getAddresses();
  
  /// Get a specific address by ID
  Future<Address?> getAddress(String addressId);
  
  /// Add a new address for the current user
  Future<AddressOperationResult> addAddress(AddressDto dto);
  
  /// Update an existing address
  Future<AddressOperationResult> updateAddress(String addressId, AddressDto dto);
  
  /// Delete an address
  Future<AddressOperationResult> deleteAddress(String addressId);
  
  /// Set an address as the default address
  Future<AddressOperationResult> setDefaultAddress(String addressId);
  
  /// Get the user's default address
  Future<Address?> getDefaultAddress();
  
  /// Get the user's billing address (or default if no billing address)
  Future<Address?> getBillingAddress();
  
  // ============================================================================
  // CHILD ACCOUNT MANAGEMENT OPERATIONS
  // ============================================================================
  
  /// Get all child accounts for the current user
  Future<List<ChildAccount>> getChildAccounts();
  
  /// Get a specific child account by ID
  Future<ChildAccount?> getChildAccount(String childId);
  
  /// Add a new child account
  Future<ChildAccountOperationResult> addChildAccount(ChildAccountDto dto);
  
  /// Update an existing child account
  Future<ChildAccountOperationResult> updateChildAccount(String childId, ChildAccountDto dto);
  
  /// Delete a child account
  Future<ChildAccountOperationResult> deleteChildAccount(String childId);
  
  /// Update child account profile picture
  Future<ChildAccountOperationResult> updateChildProfilePicture(String childId, File imageFile);
  
  /// Delete child account profile picture
  Future<ChildAccountOperationResult> deleteChildProfilePicture(String childId);
  
  /// Get child accounts within a specific age range
  Future<List<ChildAccount>> getChildAccountsByAge(int minAge, int maxAge);
  
  /// Get child accounts eligible for specific course requirements
  Future<List<ChildAccount>> getEligibleChildrenForCourse(String courseId);
  
  // ============================================================================
  // PROFILE VALIDATION & UTILITIES
  // ============================================================================
  
  /// Validate email address availability (for profile updates)
  Future<bool> isEmailAvailable(String email);
  
  /// Validate address information
  Future<bool> validateAddress(AddressDto dto);
  
  /// Check if user profile has all required information
  Future<bool> hasCompleteProfile();
  
  /// Get profile completion percentage
  Future<double> getProfileCompletionPercentage();
  
  /// Get missing profile fields
  Future<List<String>> getMissingProfileFields();
  
  // ============================================================================
  // EMERGENCY CONTACT & MEDICAL INFORMATION
  // ============================================================================
  
  /// Get emergency contact information for user and all children
  Future<List<EmergencyContact>> getAllEmergencyContacts();
  
  /// Update emergency contact information for a child
  Future<ChildAccountOperationResult> updateChildEmergencyContact(
    String childId,
    String contactName,
    String contactPhone,
    String relationship,
  );
  
  /// Get medical information summary for all children
  Future<Map<String, MedicalInformation>> getChildrenMedicalInfo();
  
  /// Update medical information for a child
  Future<ChildAccountOperationResult> updateChildMedicalInfo(
    String childId,
    MedicalInformation medicalInfo,
  );
  
  // ============================================================================
  // CACHE & REFRESH OPERATIONS
  // ============================================================================
  
  /// Refresh user profile data from server
  Future<User?> refreshUserProfile();
  
  /// Refresh child accounts data from server  
  Future<List<ChildAccount>> refreshChildAccounts();
  
  /// Refresh addresses data from server
  Future<List<Address>> refreshAddresses();
  
  /// Clear all cached profile data
  Future<void> clearProfileCache();
  
  /// Sync local profile changes with server
  Future<bool> syncProfileChanges();
}