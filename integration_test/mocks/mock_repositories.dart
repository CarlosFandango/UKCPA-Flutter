/// Centralized mock repositories for integration tests
/// 
/// This file provides mock implementations of all repositories using the
/// centralized MockDataFactory. When GraphQL schemas change, update the
/// MockDataFactory and these repositories will automatically use the new data.

import 'package:mockito/mockito.dart';
import 'package:ukcpa_flutter/domain/repositories/auth_repository.dart';
import 'package:ukcpa_flutter/domain/repositories/terms_repository.dart';
import 'package:ukcpa_flutter/domain/repositories/basket_repository.dart';
import 'package:ukcpa_flutter/domain/entities/user.dart';
import 'package:ukcpa_flutter/domain/entities/term.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/basket.dart';
import 'mock_data_factory.dart';

// ============================================================================
// AUTH REPOSITORY MOCK
// ============================================================================

/// Mock Auth Repository using centralized data factory
class MockAuthRepository extends Mock implements AuthRepository {
  
  @override
  Future<AuthResponse> login(String email, String password) async {
    // Apply configured delay if enabled
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.authResponseDelay);
    }
    
    // Simulate network error if configured
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    // Simulate server error if configured
    if (MockConfig.simulateServerErrors) {
      throw MockDataFactory.createServerError();
    }
    
    // Check credentials and return appropriate response
    if (MockDataFactory.areValidTestCredentials(email, password)) {
      return MockDataFactory.createSuccessfulAuthResponse();
    }
    
    return MockDataFactory.createFailedAuthResponse();
  }
  
  @override
  Future<User?> getCurrentUser() async {
    // Apply configured delay if enabled
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    
    // Simulate network error if configured
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    // Return authenticated user for post-login testing
    // This ensures tests can access authenticated screens
    return MockDataFactory.createTestUser();
  }
  
  @override
  Future<void> logout() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    // Mock logout - no implementation needed
  }
  
  @override
  Future<void> saveAuthToken(String token) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    // Mock token save - no implementation needed
  }
  
  @override
  Future<String?> getAuthToken() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    // Return mock token for authenticated state
    return 'mock-jwt-token-12345';
  }
  
  @override
  Future<void> clearAuthToken() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    // Mock token clear - no implementation needed
  }
  
  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.authResponseDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    // Return successful registration
    return MockDataFactory.createSuccessfulAuthResponse(
      user: MockDataFactory.createTestUser(
        email: email,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }
}

// ============================================================================
// TERMS REPOSITORY MOCK
// ============================================================================

/// Mock Terms Repository using centralized data factory
class MockTermsRepository extends Mock implements TermsRepository {
  
  @override
  Future<List<Term>> getTerms({String? displayStatus}) async {
    // Apply configured delay if enabled
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.dataLoadDelay);
    }
    
    // Simulate network error if configured
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    // Simulate server error if configured
    if (MockConfig.simulateServerErrors) {
      throw MockDataFactory.createServerError();
    }
    
    // Return empty data if configured
    if (MockConfig.returnEmptyData) {
      return [];
    }
    
    // Return standard mock terms with course groups
    return MockDataFactory.createStandardTerms();
  }
  
  @override
  Future<CourseGroup?> getCourseGroup(int id, {String? displayStatus}) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.dataLoadDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    if (MockConfig.returnEmptyData) {
      return null;
    }
    
    // Return a course group from standard course groups
    final courseGroups = MockDataFactory.createStandardCourseGroups();
    return courseGroups.isNotEmpty ? courseGroups.first : null;
  }
  
  @override
  Future<void> clearCache() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    // Mock cache clear - no implementation needed
  }
  
  @override
  Future<List<Term>> refreshTerms({String displayStatus = 'LIVE'}) async {
    // Same as getTerms - just refresh the data
    return getTerms(displayStatus: displayStatus);
  }
}

// ============================================================================
// BASKET REPOSITORY MOCK
// ============================================================================

/// Mock Basket Repository using centralized data factory
class MockBasketRepository extends Mock implements BasketRepository {
  
  @override
  Future<Basket?> getBasket() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.dataLoadDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    if (MockConfig.simulateServerErrors) {
      throw MockDataFactory.createServerError();
    }
    
    if (MockConfig.returnEmptyData) {
      return MockDataFactory.emptyBasket;
    }
    
    // Return basket with items by default
    return MockDataFactory.basketWithItems;
  }
  
  @override
  Future<Basket> initBasket() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    return MockDataFactory.emptyBasket;
  }
  
  @override
  Future<BasketOperationResult> addItem(
    String itemId, {
    required String itemType,
    bool? payDeposit,
    String? assignToUserId,
    DateTime? chargeFromDate,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    if (MockConfig.simulateServerErrors) {
      return MockDataFactory.failedAddResult;
    }
    
    return MockDataFactory.successfulAddResult;
  }
  
  @override
  Future<BasketOperationResult> removeItem(String itemId, String itemType) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    return MockDataFactory.createBasketOperationResult(
      success: true,
      basket: MockDataFactory.emptyBasket,
      message: 'Item removed successfully',
    );
  }
  
  @override
  Future<bool> destroyBasket() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    return !MockConfig.simulateServerErrors;
  }
  
  @override
  Future<BasketOperationResult> applyPromoCode(String code) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    if (code == 'INVALID' || MockConfig.simulateServerErrors) {
      return MockDataFactory.createBasketOperationResult(
        success: false,
        basket: MockDataFactory.emptyBasket,
        message: 'Invalid promo code',
        errorCode: 'INVALID_PROMO',
      );
    }
    
    return MockDataFactory.createBasketOperationResult(
      success: true,
      basket: MockDataFactory.basketWithDiscounts,
      message: 'Promo code applied successfully',
    );
  }
  
  @override
  Future<BasketOperationResult> useCreditForBasket(bool useCredit) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.quickOperationDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }
    
    final basket = useCredit 
        ? MockDataFactory.basketWithDiscounts
        : MockDataFactory.basketWithItems;
        
    return MockDataFactory.createBasketOperationResult(
      success: true,
      basket: basket,
      message: useCredit ? 'Credit applied' : 'Credit removed',
    );
  }
  
  @override
  Stream<Basket?> watchBasket() {
    // Return a stream that emits the current basket periodically
    return Stream.periodic(
      const Duration(milliseconds: 100),
      (count) => MockDataFactory.basketWithItems,
    ).take(1);
  }
}

// ============================================================================
// COURSE REPOSITORY MOCK (Future Extension)
// ============================================================================

/// Placeholder for future course repository mock
/// Add additional repository mocks here as needed
class MockCourseRepository {
  // TODO: Implement when CourseRepository is defined
}

// ============================================================================
// MOCK REPOSITORY FACTORY
// ============================================================================

/// Factory for creating consistent mock repositories
class MockRepositoryFactory {
  static MockAuthRepository? _authRepository;
  static MockTermsRepository? _termsRepository;
  static MockBasketRepository? _basketRepository;
  
  /// Get or create mock auth repository
  static MockAuthRepository getAuthRepository() {
    return _authRepository ??= MockAuthRepository();
  }
  
  /// Get or create mock terms repository
  static MockTermsRepository getTermsRepository() {
    return _termsRepository ??= MockTermsRepository();
  }
  
  /// Get or create mock basket repository
  static MockBasketRepository getBasketRepository() {
    return _basketRepository ??= MockBasketRepository();
  }
  
  /// Reset all repository instances (useful for test isolation)
  static void resetAll() {
    _authRepository = null;
    _termsRepository = null;
    _basketRepository = null;
  }
  
  /// Configure all repositories for specific test scenarios
  static void configureForSpeed() {
    MockConfig.configureForSpeed();
  }
  
  static void configureForErrorTesting() {
    MockConfig.configureForErrorTesting();
  }
  
  static void configureForEmptyState() {
    MockConfig.configureForEmptyState();
  }
  
  static void resetToDefaults() {
    MockConfig.resetToDefaults();
  }
}