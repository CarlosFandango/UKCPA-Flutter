import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../domain/entities/user.dart';
import '../../domain/entities/child_account.dart';
import '../../domain/entities/profile_dto.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../core/constants/app_constants.dart';
import '../datasources/graphql_client.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final GraphQLClient _client;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();
  
  // Cache for profile data
  User? _cachedProfile;
  List<Address>? _cachedAddresses;
  List<ChildAccount>? _cachedChildren;
  DateTime? _lastProfileUpdate;
  
  static const Duration _cacheTimeout = Duration(minutes: 5);
  
  ProfileRepositoryImpl({
    GraphQLClient? client,
    FlutterSecureStorage? secureStorage,
  })  : _client = client ?? getGraphQLClient(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // ============================================================================
  // USER PROFILE OPERATIONS
  // ============================================================================
  
  @override
  Future<User?> getUserProfile() async {
    _logger.d('Getting user profile');
    
    // Return cached profile if valid and recent
    if (_cachedProfile != null && 
        _lastProfileUpdate != null && 
        DateTime.now().difference(_lastProfileUpdate!) < _cacheTimeout) {
      _logger.d('Returning cached profile');
      return _cachedProfile;
    }
    
    const String query = '''
      query GetUserProfile {
        getCurrentUser {
          id
          email
          firstName
          lastName
          title
          phone
          mobilePhone
          profileImageUrl
          dateOfBirth
          parentId
          emergencyContactName
          emergencyContactPhone
          emergencyContactRelationship
          medicalNotes
          dietaryRequirements
          isActive
          createdAt
          updatedAt
          stripeCustomerId
          roles
          addresses {
            id
            name
            line1
            line2
            city
            county
            country
            postCode
            countryCode
            isDefault
            type
            createdAt
            updatedAt
          }
          preferences {
            emailNotifications
            smsNotifications
            marketingEmails
            classReminders
            paymentReminders
            preferredLanguage
            preferredCurrency
            timeZone
          }
          children {
            id
            firstName
            lastName
            dateOfBirth
            nickname
            schoolName
            schoolYear
            gender
            profileImageUrl
            medicalConditions
            allergies
            medications
            dietaryRequirements
            emergencyContactName
            emergencyContactPhone
            emergencyContactRelationship
            danceExperience
            currentLevel
            previousInstructor
            specialNeeds
            parentNotes
            isActive
            createdAt
            updatedAt
            enrolledCourseIds
            completedCourseIds
            favouriteCourseIds
          }
        }
      }
    ''';
    
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      
      if (result.hasException) {
        _logger.e('Error getting user profile: ${result.exception}');
        return null;
      }
      
      if (result.data?['getCurrentUser'] != null) {
        final user = User.fromJson(result.data!['getCurrentUser']);
        _cachedProfile = user;
        _cachedAddresses = user.addresses;
        _cachedChildren = user.children;
        _lastProfileUpdate = DateTime.now();
        
        _logger.d('Successfully retrieved user profile for: ${user.email}');
        return user;
      }
      
      return null;
    } catch (e) {
      _logger.e('Exception getting user profile: $e');
      return null;
    }
  }
  
  @override
  Future<ProfileOperationResult> updateProfile(UpdateProfileDto dto) async {
    _logger.d('Updating user profile');
    
    const String mutation = '''
      mutation UpdateProfile(\$data: UpdateProfileInput!) {
        updateProfile(data: \$data) {
          user {
            id
            email
            firstName
            lastName
            title
            phone
            mobilePhone
            profileImageUrl
            dateOfBirth
            emergencyContactName
            emergencyContactPhone
            emergencyContactRelationship
            medicalNotes
            dietaryRequirements
            updatedAt
            preferences {
              emailNotifications
              smsNotifications
              marketingEmails
              classReminders
              paymentReminders
              preferredLanguage
              preferredCurrency
              timeZone
            }
          }
          success
          message
          errors {
            path
            message
          }
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'data': {
              if (dto.firstName != null) 'firstName': dto.firstName,
              if (dto.lastName != null) 'lastName': dto.lastName,
              if (dto.title != null) 'title': dto.title,
              if (dto.phone != null) 'phone': dto.phone,
              if (dto.mobilePhone != null) 'mobilePhone': dto.mobilePhone,
              if (dto.dateOfBirth != null) 'dateOfBirth': dto.dateOfBirth!.toIso8601String(),
              if (dto.emergencyContactName != null) 'emergencyContactName': dto.emergencyContactName,
              if (dto.emergencyContactPhone != null) 'emergencyContactPhone': dto.emergencyContactPhone,
              if (dto.emergencyContactRelationship != null) 'emergencyContactRelationship': dto.emergencyContactRelationship,
              if (dto.medicalNotes != null) 'medicalNotes': dto.medicalNotes,
              if (dto.dietaryRequirements != null) 'dietaryRequirements': dto.dietaryRequirements,
              if (dto.preferences != null) 'preferences': {
                'emailNotifications': dto.preferences!.emailNotifications,
                'smsNotifications': dto.preferences!.smsNotifications,
                'marketingEmails': dto.preferences!.marketingEmails,
                'classReminders': dto.preferences!.classReminders,
                'paymentReminders': dto.preferences!.paymentReminders,
                'preferredLanguage': dto.preferences!.preferredLanguage,
                'preferredCurrency': dto.preferences!.preferredCurrency,
                'timeZone': dto.preferences!.timeZone,
              },
            }
          },
        ),
      );
      
      if (result.hasException) {
        _logger.e('Error updating profile: ${result.exception}');
        return ProfileOperationResult.error(
          message: 'Failed to update profile: ${result.exception?.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
      
      final data = result.data?['updateProfile'];
      if (data != null) {
        if (data['success'] == true) {
          final updatedUser = User.fromJson(data['user']);
          
          // Update cache
          _cachedProfile = _cachedProfile?.copyWith(
            firstName: updatedUser.firstName,
            lastName: updatedUser.lastName,
            title: updatedUser.title,
            phone: updatedUser.phone,
            mobilePhone: updatedUser.mobilePhone,
            dateOfBirth: updatedUser.dateOfBirth,
            emergencyContactName: updatedUser.emergencyContactName,
            emergencyContactPhone: updatedUser.emergencyContactPhone,
            emergencyContactRelationship: updatedUser.emergencyContactRelationship,
            medicalNotes: updatedUser.medicalNotes,
            dietaryRequirements: updatedUser.dietaryRequirements,
            preferences: updatedUser.preferences,
            updatedAt: updatedUser.updatedAt,
          );
          _lastProfileUpdate = DateTime.now();
          
          _logger.d('Profile updated successfully');
          return ProfileOperationResult.success(
            user: updatedUser,
            message: data['message'] ?? 'Profile updated successfully',
          );
        } else {
          final errors = (data['errors'] as List?)?.map((e) => e['message'].toString()).toList();
          return ProfileOperationResult.error(
            message: data['message'] ?? 'Failed to update profile',
            errors: errors,
          );
        }
      }
      
      return ProfileOperationResult.error(message: 'Unexpected response format');
    } catch (e) {
      _logger.e('Exception updating profile: $e');
      return ProfileOperationResult.error(
        message: 'Network error occurred while updating profile',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
  
  @override
  Future<ProfileOperationResult> updateProfilePicture(File imageFile) async {
    _logger.d('Updating profile picture');
    
    try {
      // Get current auth token
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null) {
        return ProfileOperationResult.error(
          message: 'Authentication required',
          errorCode: 'AUTH_REQUIRED',
        );
      }
      
      // Create multipart request for file upload
      final uri = Uri.parse('${AppConstants.apiUrl}/upload/profile-picture');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add file
      final fileBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'profilePicture',
          fileBytes,
          filename: 'profile_picture.jpg',
        ),
      );
      
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final responseData = json.decode(responseString);
        
        if (responseData['success'] == true) {
          final imageUrl = responseData['imageUrl'] as String;
          
          // Update cache
          _cachedProfile = _cachedProfile?.copyWith(profileImageUrl: imageUrl);
          _lastProfileUpdate = DateTime.now();
          
          _logger.d('Profile picture updated successfully');
          return ProfileOperationResult.success(
            user: _cachedProfile,
            message: 'Profile picture updated successfully',
          );
        }
      }
      
      final errorData = json.decode(responseString);
      return ProfileOperationResult.error(
        message: errorData['message'] ?? 'Failed to upload profile picture',
        errorCode: 'UPLOAD_ERROR',
      );
    } catch (e) {
      _logger.e('Exception updating profile picture: $e');
      return ProfileOperationResult.error(
        message: 'Failed to upload profile picture',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
  
  @override
  Future<ProfileOperationResult> deleteProfilePicture() async {
    _logger.d('Deleting profile picture');
    
    const String mutation = '''
      mutation DeleteProfilePicture {
        deleteProfilePicture {
          success
          message
          errors {
            path
            message
          }
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(document: gql(mutation)),
      );
      
      if (result.hasException) {
        return ProfileOperationResult.error(
          message: 'Failed to delete profile picture: ${result.exception?.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
      
      final data = result.data?['deleteProfilePicture'];
      if (data?['success'] == true) {
        // Update cache
        _cachedProfile = _cachedProfile?.copyWith(profileImageUrl: null);
        _lastProfileUpdate = DateTime.now();
        
        return ProfileOperationResult.success(
          user: _cachedProfile,
          message: data['message'] ?? 'Profile picture deleted successfully',
        );
      }
      
      return ProfileOperationResult.error(
        message: data?['message'] ?? 'Failed to delete profile picture',
      );
    } catch (e) {
      _logger.e('Exception deleting profile picture: $e');
      return ProfileOperationResult.error(
        message: 'Network error occurred while deleting profile picture',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
  
  @override
  Future<ProfileOperationResult> updatePreferences(UserPreferences preferences) async {
    _logger.d('Updating user preferences');
    
    const String mutation = '''
      mutation UpdateUserPreferences(\$preferences: UserPreferencesInput!) {
        updateUserPreferences(preferences: \$preferences) {
          user {
            id
            preferences {
              emailNotifications
              smsNotifications
              marketingEmails
              classReminders
              paymentReminders
              preferredLanguage
              preferredCurrency
              timeZone
            }
          }
          success
          message
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'preferences': {
              'emailNotifications': preferences.emailNotifications,
              'smsNotifications': preferences.smsNotifications,
              'marketingEmails': preferences.marketingEmails,
              'classReminders': preferences.classReminders,
              'paymentReminders': preferences.paymentReminders,
              'preferredLanguage': preferences.preferredLanguage,
              'preferredCurrency': preferences.preferredCurrency,
              'timeZone': preferences.timeZone,
            },
          },
        ),
      );
      
      if (result.hasException) {
        return ProfileOperationResult.error(
          message: 'Failed to update preferences: ${result.exception?.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
      
      final data = result.data?['updateUserPreferences'];
      if (data?['success'] == true) {
        final updatedUser = User.fromJson(data['user']);
        
        // Update cache
        _cachedProfile = _cachedProfile?.copyWith(preferences: updatedUser.preferences);
        _lastProfileUpdate = DateTime.now();
        
        return ProfileOperationResult.success(
          user: _cachedProfile,
          message: data['message'] ?? 'Preferences updated successfully',
        );
      }
      
      return ProfileOperationResult.error(
        message: data?['message'] ?? 'Failed to update preferences',
      );
    } catch (e) {
      _logger.e('Exception updating preferences: $e');
      return ProfileOperationResult.error(
        message: 'Network error occurred while updating preferences',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }

  // ============================================================================
  // ADDRESS MANAGEMENT OPERATIONS
  // ============================================================================
  
  @override
  Future<List<Address>> getAddresses() async {
    _logger.d('Getting user addresses');
    
    // Return cached addresses if valid
    if (_cachedAddresses != null &&
        _lastProfileUpdate != null &&
        DateTime.now().difference(_lastProfileUpdate!) < _cacheTimeout) {
      return _cachedAddresses!;
    }
    
    const String query = '''
      query GetUserAddresses {
        getUserAddresses {
          id
          name
          line1
          line2
          city
          county
          country
          postCode
          countryCode
          isDefault
          type
          createdAt
          updatedAt
        }
      }
    ''';
    
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      
      if (result.hasException) {
        _logger.e('Error getting addresses: ${result.exception}');
        return [];
      }
      
      if (result.data?['getUserAddresses'] != null) {
        final addressesList = result.data!['getUserAddresses'] as List;
        final addresses = addressesList.map((json) => Address.fromJson(json)).toList();
        
        _cachedAddresses = addresses;
        _lastProfileUpdate = DateTime.now();
        
        return addresses;
      }
      
      return [];
    } catch (e) {
      _logger.e('Exception getting addresses: $e');
      return [];
    }
  }
  
  @override
  Future<Address?> getAddress(String addressId) async {
    final addresses = await getAddresses();
    try {
      return addresses.firstWhere((address) => address.id == addressId);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<AddressOperationResult> addAddress(AddressDto dto) async {
    _logger.d('Adding new address');
    
    const String mutation = '''
      mutation AddAddress(\$data: AddressInput!) {
        addAddress(data: \$data) {
          address {
            id
            name
            line1
            line2
            city
            county
            country
            postCode
            countryCode
            isDefault
            type
            createdAt
            updatedAt
          }
          success
          message
          errors {
            path
            message
          }
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'data': {
              if (dto.name?.isNotEmpty == true) 'name': dto.name,
              'line1': dto.line1,
              if (dto.line2?.isNotEmpty == true) 'line2': dto.line2,
              'city': dto.city,
              if (dto.county?.isNotEmpty == true) 'county': dto.county,
              if (dto.country?.isNotEmpty == true) 'country': dto.country,
              'postCode': dto.postCode,
              if (dto.countryCode?.isNotEmpty == true) 'countryCode': dto.countryCode,
              'isDefault': dto.isDefault,
              'type': dto.type.name,
            }
          },
        ),
      );
      
      if (result.hasException) {
        return AddressOperationResult.error(
          message: 'Failed to add address: ${result.exception?.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
      
      final data = result.data?['addAddress'];
      if (data?['success'] == true) {
        final newAddress = Address.fromJson(data['address']);
        
        // Update cache
        _cachedAddresses = [...(_cachedAddresses ?? []), newAddress];
        _lastProfileUpdate = DateTime.now();
        
        return AddressOperationResult.success(
          address: newAddress,
          message: data['message'] ?? 'Address added successfully',
        );
      }
      
      final errors = (data?['errors'] as List?)?.map((e) => e['message'].toString()).toList();
      return AddressOperationResult.error(
        message: data?['message'] ?? 'Failed to add address',
        errors: errors,
      );
    } catch (e) {
      _logger.e('Exception adding address: $e');
      return AddressOperationResult.error(
        message: 'Network error occurred while adding address',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
  
  @override
  Future<AddressOperationResult> updateAddress(String addressId, AddressDto dto) async {
    _logger.d('Updating address: $addressId');
    
    const String mutation = '''
      mutation UpdateAddress(\$id: ID!, \$data: AddressInput!) {
        updateAddress(id: \$id, data: \$data) {
          address {
            id
            name
            line1
            line2
            city
            county
            country
            postCode
            countryCode
            isDefault
            type
            createdAt
            updatedAt
          }
          success
          message
          errors {
            path
            message
          }
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'id': addressId,
            'data': {
              if (dto.name?.isNotEmpty == true) 'name': dto.name,
              'line1': dto.line1,
              if (dto.line2?.isNotEmpty == true) 'line2': dto.line2,
              'city': dto.city,
              if (dto.county?.isNotEmpty == true) 'county': dto.county,
              if (dto.country?.isNotEmpty == true) 'country': dto.country,
              'postCode': dto.postCode,
              if (dto.countryCode?.isNotEmpty == true) 'countryCode': dto.countryCode,
              'isDefault': dto.isDefault,
              'type': dto.type.name,
            }
          },
        ),
      );
      
      if (result.hasException) {
        return AddressOperationResult.error(
          message: 'Failed to update address: ${result.exception?.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
      
      final data = result.data?['updateAddress'];
      if (data?['success'] == true) {
        final updatedAddress = Address.fromJson(data['address']);
        
        // Update cache
        if (_cachedAddresses != null) {
          final index = _cachedAddresses!.indexWhere((addr) => addr.id == addressId);
          if (index >= 0) {
            _cachedAddresses![index] = updatedAddress;
            _lastProfileUpdate = DateTime.now();
          }
        }
        
        return AddressOperationResult.success(
          address: updatedAddress,
          message: data['message'] ?? 'Address updated successfully',
        );
      }
      
      final errors = (data?['errors'] as List?)?.map((e) => e['message'].toString()).toList();
      return AddressOperationResult.error(
        message: data?['message'] ?? 'Failed to update address',
        errors: errors,
      );
    } catch (e) {
      _logger.e('Exception updating address: $e');
      return AddressOperationResult.error(
        message: 'Network error occurred while updating address',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
  
  @override
  Future<AddressOperationResult> deleteAddress(String addressId) async {
    _logger.d('Deleting address: $addressId');
    
    const String mutation = '''
      mutation DeleteAddress(\$id: ID!) {
        deleteAddress(id: \$id) {
          success
          message
          errors {
            path
            message
          }
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'id': addressId},
        ),
      );
      
      if (result.hasException) {
        return AddressOperationResult.error(
          message: 'Failed to delete address: ${result.exception?.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
      
      final data = result.data?['deleteAddress'];
      if (data?['success'] == true) {
        // Update cache
        if (_cachedAddresses != null) {
          _cachedAddresses!.removeWhere((addr) => addr.id == addressId);
          _lastProfileUpdate = DateTime.now();
        }
        
        return AddressOperationResult.success(
          message: data['message'] ?? 'Address deleted successfully',
        );
      }
      
      final errors = (data?['errors'] as List?)?.map((e) => e['message'].toString()).toList();
      return AddressOperationResult.error(
        message: data?['message'] ?? 'Failed to delete address',
        errors: errors,
      );
    } catch (e) {
      _logger.e('Exception deleting address: $e');
      return AddressOperationResult.error(
        message: 'Network error occurred while deleting address',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
  
  @override
  Future<AddressOperationResult> setDefaultAddress(String addressId) async {
    _logger.d('Setting default address: $addressId');
    
    const String mutation = '''
      mutation SetDefaultAddress(\$id: ID!) {
        setDefaultAddress(id: \$id) {
          addresses {
            id
            name
            line1
            line2
            city
            county
            country
            postCode
            countryCode
            isDefault
            type
            createdAt
            updatedAt
          }
          success
          message
        }
      }
    ''';
    
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'id': addressId},
        ),
      );
      
      if (result.hasException) {
        return AddressOperationResult.error(
          message: 'Failed to set default address: ${result.exception?.toString()}',
          errorCode: 'NETWORK_ERROR',
        );
      }
      
      final data = result.data?['setDefaultAddress'];
      if (data?['success'] == true) {
        // Update cache with all addresses (default flags updated)
        final addressesList = data['addresses'] as List;
        _cachedAddresses = addressesList.map((json) => Address.fromJson(json)).toList();
        _lastProfileUpdate = DateTime.now();
        
        final defaultAddress = _cachedAddresses?.firstWhere((addr) => addr.isDefault);
        
        return AddressOperationResult.success(
          address: defaultAddress,
          addresses: _cachedAddresses,
          message: data['message'] ?? 'Default address updated successfully',
        );
      }
      
      return AddressOperationResult.error(
        message: data?['message'] ?? 'Failed to set default address',
      );
    } catch (e) {
      _logger.e('Exception setting default address: $e');
      return AddressOperationResult.error(
        message: 'Network error occurred while setting default address',
        errorCode: 'NETWORK_ERROR',
      );
    }
  }
  
  @override
  Future<Address?> getDefaultAddress() async {
    final addresses = await getAddresses();
    try {
      return addresses.firstWhere((address) => address.isDefault);
    } catch (e) {
      return addresses.isNotEmpty ? addresses.first : null;
    }
  }
  
  @override
  Future<Address?> getBillingAddress() async {
    final addresses = await getAddresses();
    try {
      // First try to find billing address
      return addresses.firstWhere((address) => address.type == AddressType.billing);
    } catch (e) {
      // Fall back to default address
      return getDefaultAddress();
    }
  }

  // ============================================================================
  // CHILD ACCOUNT MANAGEMENT (SIMPLIFIED IMPLEMENTATION)
  // Note: Full child account implementation would include additional GraphQL operations
  // ============================================================================
  
  @override
  Future<List<ChildAccount>> getChildAccounts() async {
    _logger.d('Getting child accounts');
    
    // Return cached children if valid
    if (_cachedChildren != null &&
        _lastProfileUpdate != null &&
        DateTime.now().difference(_lastProfileUpdate!) < _cacheTimeout) {
      return _cachedChildren!;
    }
    
    // Children are included in the main profile query
    final profile = await getUserProfile();
    return profile?.children ?? [];
  }
  
  @override
  Future<ChildAccount?> getChildAccount(String childId) async {
    final children = await getChildAccounts();
    try {
      return children.firstWhere((child) => child.id == childId);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<ChildAccountOperationResult> addChildAccount(ChildAccountDto dto) async {
    _logger.d('Adding child account');
    
    // For now, return a placeholder implementation
    // Full implementation would include GraphQL mutation for adding children
    return ChildAccountOperationResult.error(
      message: 'Child account management not yet implemented',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }
  
  @override
  Future<ChildAccountOperationResult> updateChildAccount(String childId, ChildAccountDto dto) async {
    return ChildAccountOperationResult.error(
      message: 'Child account management not yet implemented', 
      errorCode: 'NOT_IMPLEMENTED',
    );
  }
  
  @override
  Future<ChildAccountOperationResult> deleteChildAccount(String childId) async {
    return ChildAccountOperationResult.error(
      message: 'Child account management not yet implemented',
      errorCode: 'NOT_IMPLEMENTED', 
    );
  }
  
  @override
  Future<ChildAccountOperationResult> updateChildProfilePicture(String childId, File imageFile) async {
    return ChildAccountOperationResult.error(
      message: 'Child profile picture management not yet implemented',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }
  
  @override
  Future<ChildAccountOperationResult> deleteChildProfilePicture(String childId) async {
    return ChildAccountOperationResult.error(
      message: 'Child profile picture management not yet implemented',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }
  
  @override
  Future<List<ChildAccount>> getChildAccountsByAge(int minAge, int maxAge) async {
    final children = await getChildAccounts();
    return children.where((child) {
      final age = child.age;
      return age >= minAge && age <= maxAge;
    }).toList();
  }
  
  @override
  Future<List<ChildAccount>> getEligibleChildrenForCourse(String courseId) async {
    // This would require course age requirements from the course repository
    final children = await getChildAccounts();
    return children; // Placeholder - return all children for now
  }
  
  // ============================================================================
  // PROFILE VALIDATION & UTILITIES
  // ============================================================================
  
  @override
  Future<bool> isEmailAvailable(String email) async {
    const String query = '''
      query CheckEmailAvailability(\$email: String!) {
        isEmailAvailable(email: \$email)
      }
    ''';
    
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          variables: {'email': email.trim().toLowerCase()},
        ),
      );
      
      return result.data?['isEmailAvailable'] ?? false;
    } catch (e) {
      _logger.e('Exception checking email availability: $e');
      return false;
    }
  }
  
  @override
  Future<bool> validateAddress(AddressDto dto) async {
    // Basic client-side validation
    return dto.line1.isNotEmpty && 
           dto.city.isNotEmpty && 
           dto.postCode.isNotEmpty;
  }
  
  @override
  Future<bool> hasCompleteProfile() async {
    final profile = await getUserProfile();
    return profile?.hasCompleteProfile ?? false;
  }
  
  @override
  Future<double> getProfileCompletionPercentage() async {
    final profile = await getUserProfile();
    if (profile == null) return 0.0;
    
    int completed = 0;
    int total = 8; // Total fields to check
    
    if (profile.firstName.isNotEmpty) completed++;
    if (profile.lastName.isNotEmpty) completed++;
    if (profile.email.isNotEmpty) completed++;
    if (profile.phone?.isNotEmpty == true) completed++;
    if (profile.addresses.isNotEmpty) completed++;
    if (profile.dateOfBirth != null) completed++;
    if (profile.hasEmergencyContact) completed++;
    if (profile.profileImageUrl?.isNotEmpty == true) completed++;
    
    return completed / total;
  }
  
  @override
  Future<List<String>> getMissingProfileFields() async {
    final profile = await getUserProfile();
    if (profile == null) return ['Complete profile information'];
    
    final missing = <String>[];
    
    if (profile.firstName.isEmpty) missing.add('First name');
    if (profile.lastName.isEmpty) missing.add('Last name');
    if (profile.phone?.isEmpty != false) missing.add('Phone number');
    if (profile.addresses.isEmpty) missing.add('Address');
    if (profile.dateOfBirth == null) missing.add('Date of birth');
    if (!profile.hasEmergencyContact) missing.add('Emergency contact');
    if (profile.profileImageUrl?.isEmpty != false) missing.add('Profile picture');
    
    return missing;
  }

  // ============================================================================
  // EMERGENCY CONTACT & MEDICAL INFORMATION (SIMPLIFIED)
  // ============================================================================
  
  @override
  Future<List<EmergencyContact>> getAllEmergencyContacts() async {
    final profile = await getUserProfile();
    final contacts = <EmergencyContact>[];
    
    // Add user's emergency contact
    if (profile?.hasEmergencyContact == true) {
      contacts.add(EmergencyContact(
        id: '${profile!.id}_emergency',
        name: profile.emergencyContactName!,
        phone: profile.emergencyContactPhone!,
        relationship: profile.emergencyContactRelationship ?? 'Emergency Contact',
        isPrimary: true,
      ));
    }
    
    // Add children's emergency contacts
    for (final child in profile?.children ?? []) {
      if (child.hasEmergencyContact) {
        contacts.add(EmergencyContact(
          id: '${child.id}_emergency',
          name: child.emergencyContactName!,
          phone: child.emergencyContactPhone!,
          relationship: child.emergencyContactRelationship ?? 'Child Emergency Contact',
          isPrimary: false,
        ));
      }
    }
    
    return contacts;
  }
  
  @override
  Future<ChildAccountOperationResult> updateChildEmergencyContact(
    String childId,
    String contactName,
    String contactPhone,
    String relationship,
  ) async {
    return ChildAccountOperationResult.error(
      message: 'Child emergency contact management not yet implemented',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }
  
  @override
  Future<Map<String, MedicalInformation>> getChildrenMedicalInfo() async {
    final children = await getChildAccounts();
    final medicalInfo = <String, MedicalInformation>{};
    
    for (final child in children) {
      if (child.hasMedicalConditions) {
        medicalInfo[child.id] = MedicalInformation(
          conditions: child.medicalConditions,
          allergies: child.allergies,
          medications: child.medications,
          dietaryRequirements: child.dietaryRequirements,
          lastUpdated: child.updatedAt ?? DateTime.now(),
        );
      }
    }
    
    return medicalInfo;
  }
  
  @override
  Future<ChildAccountOperationResult> updateChildMedicalInfo(
    String childId,
    MedicalInformation medicalInfo,
  ) async {
    return ChildAccountOperationResult.error(
      message: 'Child medical information management not yet implemented',
      errorCode: 'NOT_IMPLEMENTED',
    );
  }

  // ============================================================================
  // CACHE & REFRESH OPERATIONS
  // ============================================================================
  
  @override
  Future<User?> refreshUserProfile() async {
    _logger.d('Refreshing user profile from server');
    
    // Clear cache and fetch fresh data
    _cachedProfile = null;
    _cachedAddresses = null;
    _cachedChildren = null;
    _lastProfileUpdate = null;
    
    return getUserProfile();
  }
  
  @override
  Future<List<ChildAccount>> refreshChildAccounts() async {
    // Clear cache and fetch fresh data
    _cachedChildren = null;
    _lastProfileUpdate = null;
    
    return getChildAccounts();
  }
  
  @override
  Future<List<Address>> refreshAddresses() async {
    // Clear cache and fetch fresh data
    _cachedAddresses = null;
    _lastProfileUpdate = null;
    
    return getAddresses();
  }
  
  @override
  Future<void> clearProfileCache() async {
    _logger.d('Clearing profile cache');
    
    _cachedProfile = null;
    _cachedAddresses = null;
    _cachedChildren = null;
    _lastProfileUpdate = null;
  }
  
  @override
  Future<bool> syncProfileChanges() async {
    _logger.d('Syncing profile changes with server');
    
    // For now, just refresh the profile
    // In a full implementation, this would sync any locally stored changes
    final profile = await refreshUserProfile();
    return profile != null;
  }
}