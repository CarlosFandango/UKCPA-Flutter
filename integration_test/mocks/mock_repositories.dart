/// Centralized mock repositories for integration tests
/// 
/// This file provides mock implementations of all repositories using the
/// centralized MockDataFactory. When GraphQL schemas change, update the
/// MockDataFactory and these repositories will automatically use the new data.

import 'package:mockito/mockito.dart';
import 'package:ukcpa_flutter/domain/repositories/auth_repository.dart';
import 'package:ukcpa_flutter/domain/repositories/terms_repository.dart';
import 'package:ukcpa_flutter/domain/repositories/basket_repository.dart';
import 'package:ukcpa_flutter/domain/repositories/course_repository.dart';
import 'package:ukcpa_flutter/domain/entities/user.dart';
import 'package:ukcpa_flutter/domain/entities/term.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';
import 'package:ukcpa_flutter/domain/entities/course_session.dart';
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
// COURSE REPOSITORY MOCK
// ============================================================================

/// Mock Course Repository using centralized data factory
class MockCourseRepository extends Mock implements CourseRepository {
  
  @override
  Future<CourseSearchResult> getCourses({
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }

    // Return mock course search result
    final courses = <Course>[
      MockDataFactory.createCourse(id: '1', name: 'Ballet Beginners Studio', type: 'StudioCourse'),
      MockDataFactory.createCourse(id: '2', name: 'Jazz Online Classes', type: 'OnlineCourse'),
    ];
    
    return CourseSearchResult(
      courses: courses,
      totalCount: courses.length,
      hasMore: false,
      filters: filters ?? const CourseSearchFilters(),
    );
  }
  
  @override
  Future<Course?> getCourse(String courseId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    
    if (courseId == '1') {
      return MockDataFactory.createCourse(id: '1', name: 'Ballet Beginners Studio', type: 'StudioCourse');
    } else if (courseId == '2') {
      return MockDataFactory.createCourse(id: '2', name: 'Jazz Online Classes', type: 'OnlineCourse');
    }
    return null;
  }
  
  @override
  Future<StudioCourse?> getStudioCourse(String courseId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    
    if (courseId == '1') {
      return MockDataFactory.createTestStudioCourse();
    }
    return null;
  }
  
  @override
  Future<OnlineCourse?> getOnlineCourse(String courseId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    
    if (courseId == '2') {
      return MockDataFactory.createTestOnlineCourse();
    }
    return null;
  }
  
  @override
  Future<List<CourseGroup>> getCourseGroups() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    if (MockConfig.simulateNetworkErrors) {
      throw MockDataFactory.createNetworkError();
    }

    return [MockDataFactory.createTestCourseGroup()];
  }
  
  @override
  Future<CourseGroup?> getCourseGroup(String groupId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    
    if (groupId == '1') {
      return MockDataFactory.createTestCourseGroup();
    }
    return null;
  }
  
  @override
  Future<List<Course>> getCoursesInGroup(String groupId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[
      MockDataFactory.createCourse(name: 'Studio Course in Group', type: 'StudioCourse'),
      MockDataFactory.createCourse(name: 'Online Course in Group', type: 'OnlineCourse'),
    ];
  }
  
  @override
  Future<List<CourseSession>> getCourseSessions(String courseId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return [MockDataFactory.createTestCourseSession()];
  }
  
  @override
  Future<CourseSession?> getCourseSession(String sessionId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    
    if (sessionId == '1') {
      return MockDataFactory.createTestCourseSession();
    }
    return null;
  }
  
  @override
  Future<List<CourseSession>> getUpcomingSessions(String courseId) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return [MockDataFactory.createTestCourseSession()];
  }
  
  @override
  Future<CourseSearchResult> searchCourses(
    String query, {
    CourseSearchFilters? filters,
  }) async {
    return getCourses(filters: filters);
  }
  
  @override
  Future<List<Course>> getFeaturedCourses({int? limit}) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<List<Course>> getPopularCourses({int? limit}) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Online Course', type: 'OnlineCourse')];
  }
  
  @override
  Future<List<Course>> getCoursesByDanceType(
    DanceType danceType, {
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<List<Course>> getCoursesByLevel(
    Level level, {
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<List<Course>> getCoursesByLocation(
    Location location, {
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<List<Course>> getCoursesForAge(
    int age, {
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<List<Course>> getCoursesWithTasters({
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<List<Course>> getRecommendedCourses({
    List<DanceType>? preferredDanceTypes,
    List<Level>? preferredLevels,
    int? age,
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<List<Course>> getCoursesStartingSoon({
    int? days = 7,
    CourseSearchFilters? filters,
  }) async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.searchDelay);
    }
    
    return <Course>[MockDataFactory.createCourse(name: 'Test Studio Course', type: 'StudioCourse')];
  }
  
  @override
  Future<CourseFilterOptions> getFilterOptions() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
    
    return const CourseFilterOptions(
      availableDanceTypes: [DanceType.ballet, DanceType.jazz],
      availableLevels: [Level.beginner, Level.intermediate],
      availableLocations: [Location.studio1, Location.online],
      availableAttendanceTypes: [AttendanceType.adults, AttendanceType.children],
      minPrice: 1000,
      maxPrice: 5000,
      minAge: 5,
      maxAge: 65,
    );
  }
  
  @override
  Future<void> refreshCourses() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.refreshDelay);
    }
  }
  
  @override
  Future<void> clearCache() async {
    if (MockConfig.enableDelays) {
      await Future.delayed(MockDataFactory.minimalDelay);
    }
  }
  
  @override
  Future<List<Course>> getCachedCourses() async {
    return <Course>[
      MockDataFactory.createCourse(name: 'Cached Studio Course', type: 'StudioCourse'),
      MockDataFactory.createCourse(name: 'Cached Online Course', type: 'OnlineCourse'),
    ];
  }
  
  @override
  Future<bool> isDataStale() async {
    return false; // Mock data is never stale
  }
}

// ============================================================================
// MOCK REPOSITORY FACTORY
// ============================================================================

/// Factory for creating consistent mock repositories
class MockRepositoryFactory {
  static MockAuthRepository? _authRepository;
  static MockTermsRepository? _termsRepository;
  static MockBasketRepository? _basketRepository;
  static MockCourseRepository? _courseRepository;
  
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
  
  /// Get or create mock course repository
  static MockCourseRepository getCourseRepository() {
    return _courseRepository ??= MockCourseRepository();
  }
  
  /// Reset all repository instances (useful for test isolation)
  static void resetAll() {
    _authRepository = null;
    _termsRepository = null;
    _basketRepository = null;
    _courseRepository = null;
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