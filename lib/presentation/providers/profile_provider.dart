import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/user.dart';
import '../../domain/entities/child_account.dart';
import '../../domain/entities/profile_dto.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

final Logger _logger = Logger();

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl();
});

// ============================================================================
// PROFILE STATE CLASSES
// ============================================================================

/// State class for user profile management
class ProfileState {
  final User? user;
  final List<Address> addresses;
  final List<ChildAccount> children;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final double completionPercentage;
  final List<String> missingFields;

  const ProfileState({
    this.user,
    this.addresses = const [],
    this.children = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.completionPercentage = 0.0,
    this.missingFields = const [],
  });

  ProfileState copyWith({
    User? user,
    List<Address>? addresses,
    List<ChildAccount>? children,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    double? completionPercentage,
    List<String>? missingFields,
  }) {
    return ProfileState(
      user: user ?? this.user,
      addresses: addresses ?? this.addresses,
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      missingFields: missingFields ?? this.missingFields,
    );
  }

  bool get hasUser => user != null;
  bool get hasCompleteProfile => user?.hasCompleteProfile ?? false;
  bool get hasAddresses => addresses.isNotEmpty;
  bool get hasChildren => children.isNotEmpty;
  Address? get defaultAddress => user?.defaultAddress;
  Address? get billingAddress => user?.billingAddress;
}

/// State class for address management operations
class AddressState {
  final List<Address> addresses;
  final bool isLoading;
  final bool isAdding;
  final bool isUpdating;
  final bool isDeleting;
  final String? error;
  final String? operationMessage;

  const AddressState({
    this.addresses = const [],
    this.isLoading = false,
    this.isAdding = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.error,
    this.operationMessage,
  });

  AddressState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    bool? isAdding,
    bool? isUpdating,
    bool? isDeleting,
    String? error,
    String? operationMessage,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      isAdding: isAdding ?? this.isAdding,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error,
      operationMessage: operationMessage,
    );
  }

  bool get hasOperationInProgress => isAdding || isUpdating || isDeleting;
  Address? get defaultAddress => addresses.where((addr) => addr.isDefault).firstOrNull;
}

/// State class for child account management
class ChildAccountState {
  final List<ChildAccount> children;
  final bool isLoading;
  final bool isAdding;
  final bool isUpdating;
  final bool isDeleting;
  final String? error;
  final String? operationMessage;

  const ChildAccountState({
    this.children = const [],
    this.isLoading = false,
    this.isAdding = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.error,
    this.operationMessage,
  });

  ChildAccountState copyWith({
    List<ChildAccount>? children,
    bool? isLoading,
    bool? isAdding,
    bool? isUpdating,
    bool? isDeleting,
    String? error,
    String? operationMessage,
  }) {
    return ChildAccountState(
      children: children ?? this.children,
      isLoading: isLoading ?? this.isLoading,
      isAdding: isAdding ?? this.isAdding,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error,
      operationMessage: operationMessage,
    );
  }

  bool get hasOperationInProgress => isAdding || isUpdating || isDeleting;
}

// ============================================================================
// MAIN PROFILE STATE NOTIFIER
// ============================================================================

class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  Timer? _refreshTimer;

  ProfileStateNotifier(this._repository) : super(const ProfileState()) {
    _initializeProfile();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Initialize profile data on startup
  Future<void> _initializeProfile() async {
    await loadProfile();
    _startPeriodicRefresh();
  }

  /// Start periodic profile refresh (every 5 minutes)
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (state.hasUser) {
        refreshProfile();
      }
    });
  }

  /// Load complete user profile with addresses and children
  Future<void> loadProfile() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    _logger.d('Loading user profile');

    try {
      final user = await _repository.getUserProfile();
      
      if (user != null) {
        final completionPercentage = await _repository.getProfileCompletionPercentage();
        final missingFields = await _repository.getMissingProfileFields();

        state = state.copyWith(
          user: user,
          addresses: user.addresses,
          children: user.children,
          completionPercentage: completionPercentage,
          missingFields: missingFields,
          isLoading: false,
          error: null,
        );
        _logger.d('Profile loaded successfully for ${user.email}');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load profile',
        );
        _logger.w('Profile not found');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading profile: ${e.toString()}',
      );
      _logger.e('Error loading profile: $e');
    }
  }

  /// Refresh profile data from server
  Future<void> refreshProfile() async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, error: null);
    _logger.d('Refreshing user profile');

    try {
      final user = await _repository.refreshUserProfile();
      
      if (user != null) {
        final completionPercentage = await _repository.getProfileCompletionPercentage();
        final missingFields = await _repository.getMissingProfileFields();

        state = state.copyWith(
          user: user,
          addresses: user.addresses,
          children: user.children,
          completionPercentage: completionPercentage,
          missingFields: missingFields,
          isRefreshing: false,
          error: null,
        );
        _logger.d('Profile refreshed successfully');
      } else {
        state = state.copyWith(
          isRefreshing: false,
          error: 'Failed to refresh profile',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Error refreshing profile: ${e.toString()}',
      );
      _logger.e('Error refreshing profile: $e');
    }
  }

  /// Update user profile information
  Future<bool> updateProfile(UpdateProfileDto dto) async {
    _logger.d('Updating user profile');

    try {
      final result = await _repository.updateProfile(dto);
      
      if (result.success && result.user != null) {
        // Update local state optimistically
        state = state.copyWith(
          user: result.user,
          error: null,
        );

        // Update completion metrics
        final completionPercentage = await _repository.getProfileCompletionPercentage();
        final missingFields = await _repository.getMissingProfileFields();
        
        state = state.copyWith(
          completionPercentage: completionPercentage,
          missingFields: missingFields,
        );

        _logger.d('Profile updated successfully');
        return true;
      } else {
        state = state.copyWith(error: result.message);
        _logger.e('Failed to update profile: ${result.message}');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error updating profile: ${e.toString()}');
      _logger.e('Error updating profile: $e');
      return false;
    }
  }

  /// Update profile picture
  Future<bool> updateProfilePicture(File imageFile) async {
    _logger.d('Updating profile picture');

    try {
      final result = await _repository.updateProfilePicture(imageFile);
      
      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          error: null,
        );
        _logger.d('Profile picture updated successfully');
        return true;
      } else {
        state = state.copyWith(error: result.message);
        _logger.e('Failed to update profile picture: ${result.message}');
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error updating profile picture: ${e.toString()}');
      _logger.e('Error updating profile picture: $e');
      return false;
    }
  }

  /// Delete profile picture
  Future<bool> deleteProfilePicture() async {
    _logger.d('Deleting profile picture');

    try {
      final result = await _repository.deleteProfilePicture();
      
      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          error: null,
        );
        _logger.d('Profile picture deleted successfully');
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error deleting profile picture: ${e.toString()}');
      return false;
    }
  }

  /// Update user preferences
  Future<bool> updatePreferences(UserPreferences preferences) async {
    _logger.d('Updating user preferences');

    try {
      final result = await _repository.updatePreferences(preferences);
      
      if (result.success && result.user != null) {
        state = state.copyWith(
          user: result.user,
          error: null,
        );
        _logger.d('Preferences updated successfully');
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error updating preferences: ${e.toString()}');
      return false;
    }
  }

  /// Clear any error messages
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear profile cache and reload
  Future<void> clearAndReload() async {
    await _repository.clearProfileCache();
    await loadProfile();
  }
}

// ============================================================================
// ADDRESS STATE NOTIFIER
// ============================================================================

class AddressStateNotifier extends StateNotifier<AddressState> {
  final ProfileRepository _repository;

  AddressStateNotifier(this._repository) : super(const AddressState()) {
    _loadAddresses();
  }

  /// Load all addresses
  Future<void> _loadAddresses() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final addresses = await _repository.getAddresses();
      state = state.copyWith(
        addresses: addresses,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading addresses: ${e.toString()}',
      );
    }
  }

  /// Add new address
  Future<bool> addAddress(AddressDto dto) async {
    if (state.isAdding) return false;

    state = state.copyWith(isAdding: true, error: null, operationMessage: null);
    _logger.d('Adding new address');

    try {
      final result = await _repository.addAddress(dto);
      
      if (result.success && result.address != null) {
        state = state.copyWith(
          addresses: [...state.addresses, result.address!],
          isAdding: false,
          operationMessage: result.message,
          error: null,
        );
        _logger.d('Address added successfully');
        return true;
      } else {
        state = state.copyWith(
          isAdding: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isAdding: false,
        error: 'Error adding address: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update existing address
  Future<bool> updateAddress(String addressId, AddressDto dto) async {
    if (state.isUpdating) return false;

    state = state.copyWith(isUpdating: true, error: null, operationMessage: null);
    _logger.d('Updating address: $addressId');

    try {
      final result = await _repository.updateAddress(addressId, dto);
      
      if (result.success && result.address != null) {
        final updatedAddresses = state.addresses.map((addr) {
          return addr.id == addressId ? result.address! : addr;
        }).toList();

        state = state.copyWith(
          addresses: updatedAddresses,
          isUpdating: false,
          operationMessage: result.message,
          error: null,
        );
        _logger.d('Address updated successfully');
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Error updating address: ${e.toString()}',
      );
      return false;
    }
  }

  /// Delete address
  Future<bool> deleteAddress(String addressId) async {
    if (state.isDeleting) return false;

    state = state.copyWith(isDeleting: true, error: null, operationMessage: null);
    _logger.d('Deleting address: $addressId');

    try {
      final result = await _repository.deleteAddress(addressId);
      
      if (result.success) {
        final updatedAddresses = state.addresses.where((addr) => addr.id != addressId).toList();
        
        state = state.copyWith(
          addresses: updatedAddresses,
          isDeleting: false,
          operationMessage: result.message,
          error: null,
        );
        _logger.d('Address deleted successfully');
        return true;
      } else {
        state = state.copyWith(
          isDeleting: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: 'Error deleting address: ${e.toString()}',
      );
      return false;
    }
  }

  /// Set default address
  Future<bool> setDefaultAddress(String addressId) async {
    _logger.d('Setting default address: $addressId');

    try {
      final result = await _repository.setDefaultAddress(addressId);
      
      if (result.success && result.addresses != null) {
        state = state.copyWith(
          addresses: result.addresses!,
          operationMessage: result.message,
          error: null,
        );
        _logger.d('Default address set successfully');
        return true;
      } else {
        state = state.copyWith(error: result.message);
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: 'Error setting default address: ${e.toString()}');
      return false;
    }
  }

  /// Clear operation messages and errors
  void clearMessages() {
    state = state.copyWith(error: null, operationMessage: null);
  }

  /// Refresh addresses from server
  Future<void> refreshAddresses() async {
    try {
      final addresses = await _repository.refreshAddresses();
      state = state.copyWith(
        addresses: addresses,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error refreshing addresses: ${e.toString()}');
    }
  }
}

// ============================================================================
// CHILD ACCOUNT STATE NOTIFIER
// ============================================================================

class ChildAccountStateNotifier extends StateNotifier<ChildAccountState> {
  final ProfileRepository _repository;

  ChildAccountStateNotifier(this._repository) : super(const ChildAccountState()) {
    _loadChildren();
  }

  /// Load all child accounts
  Future<void> _loadChildren() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final children = await _repository.getChildAccounts();
      state = state.copyWith(
        children: children,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading children: ${e.toString()}',
      );
    }
  }

  /// Add new child account
  Future<bool> addChildAccount(ChildAccountDto dto) async {
    if (state.isAdding) return false;

    state = state.copyWith(isAdding: true, error: null, operationMessage: null);
    _logger.d('Adding new child account');

    try {
      final result = await _repository.addChildAccount(dto);
      
      if (result.success && result.childAccount != null) {
        state = state.copyWith(
          children: [...state.children, result.childAccount!],
          isAdding: false,
          operationMessage: result.message,
          error: null,
        );
        _logger.d('Child account added successfully');
        return true;
      } else {
        state = state.copyWith(
          isAdding: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isAdding: false,
        error: 'Error adding child account: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update existing child account
  Future<bool> updateChildAccount(String childId, ChildAccountDto dto) async {
    if (state.isUpdating) return false;

    state = state.copyWith(isUpdating: true, error: null, operationMessage: null);
    _logger.d('Updating child account: $childId');

    try {
      final result = await _repository.updateChildAccount(childId, dto);
      
      if (result.success && result.childAccount != null) {
        final updatedChildren = state.children.map((child) {
          return child.id == childId ? result.childAccount! : child;
        }).toList();

        state = state.copyWith(
          children: updatedChildren,
          isUpdating: false,
          operationMessage: result.message,
          error: null,
        );
        _logger.d('Child account updated successfully');
        return true;
      } else {
        state = state.copyWith(
          isUpdating: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: 'Error updating child account: ${e.toString()}',
      );
      return false;
    }
  }

  /// Delete child account
  Future<bool> deleteChildAccount(String childId) async {
    if (state.isDeleting) return false;

    state = state.copyWith(isDeleting: true, error: null, operationMessage: null);
    _logger.d('Deleting child account: $childId');

    try {
      final result = await _repository.deleteChildAccount(childId);
      
      if (result.success) {
        final updatedChildren = state.children.where((child) => child.id != childId).toList();
        
        state = state.copyWith(
          children: updatedChildren,
          isDeleting: false,
          operationMessage: result.message,
          error: null,
        );
        _logger.d('Child account deleted successfully');
        return true;
      } else {
        state = state.copyWith(
          isDeleting: false,
          error: result.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: 'Error deleting child account: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear operation messages and errors
  void clearMessages() {
    state = state.copyWith(error: null, operationMessage: null);
  }

  /// Refresh child accounts from server
  Future<void> refreshChildren() async {
    try {
      final children = await _repository.refreshChildAccounts();
      state = state.copyWith(
        children: children,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Error refreshing children: ${e.toString()}');
    }
  }
}

// ============================================================================
// PROVIDER INSTANCES
// ============================================================================

/// Main profile state provider
final profileStateProvider = StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileStateNotifier(repository);
});

/// Address management state provider
final addressStateProvider = StateNotifierProvider<AddressStateNotifier, AddressState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return AddressStateNotifier(repository);
});

/// Child account management state provider
final childAccountStateProvider = StateNotifierProvider<ChildAccountStateNotifier, ChildAccountState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ChildAccountStateNotifier(repository);
});

// ============================================================================
// CONVENIENCE PROVIDERS
// ============================================================================

/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(profileStateProvider).user;
});

/// Provider for user addresses
final userAddressesProvider = Provider<List<Address>>((ref) {
  return ref.watch(profileStateProvider).addresses;
});

/// Provider for child accounts
final childAccountsProvider = Provider<List<ChildAccount>>((ref) {
  return ref.watch(profileStateProvider).children;
});

/// Provider for profile completion percentage
final profileCompletionProvider = Provider<double>((ref) {
  return ref.watch(profileStateProvider).completionPercentage;
});

/// Provider for missing profile fields
final missingProfileFieldsProvider = Provider<List<String>>((ref) {
  return ref.watch(profileStateProvider).missingFields;
});

/// Provider for default address
final defaultAddressProvider = Provider<Address?>((ref) {
  return ref.watch(profileStateProvider).defaultAddress;
});

/// Provider for billing address  
final billingAddressProvider = Provider<Address?>((ref) {
  return ref.watch(profileStateProvider).billingAddress;
});

/// Provider to check if user has complete profile
final hasCompleteProfileProvider = Provider<bool>((ref) {
  return ref.watch(profileStateProvider).hasCompleteProfile;
});

/// Provider for emergency contacts
final emergencyContactsProvider = FutureProvider<List<EmergencyContact>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getAllEmergencyContacts();
});

/// Provider for children medical information
final childrenMedicalInfoProvider = FutureProvider<Map<String, MedicalInformation>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getChildrenMedicalInfo();
});