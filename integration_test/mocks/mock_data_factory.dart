/// Centralized mock data factory for integration tests
/// 
/// This file provides a single source of truth for all mock data used across
/// integration tests. When GraphQL schemas or response structures change,
/// update the data here to maintain consistency across all tests.

import 'package:ukcpa_flutter/domain/entities/user.dart' hide Address;
import 'package:ukcpa_flutter/domain/entities/term.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/course_session.dart';
import 'package:ukcpa_flutter/domain/entities/basket.dart';
import 'package:ukcpa_flutter/domain/repositories/auth_repository.dart';

/// Central factory for creating consistent mock data across all tests
class MockDataFactory {
  
  // ============================================================================
  // USER & AUTH DATA
  // ============================================================================
  
  static const String defaultTestEmail = 'test@ukcpa.com';
  static const String defaultTestPassword = 'testpassword';
  static const String invalidTestEmail = 'invalid@test.com';
  static const String invalidTestPassword = 'wrongpassword';
  
  /// Standard authenticated test user
  static User createTestUser({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    return User(
      id: id ?? '123',
      email: email ?? defaultTestEmail,
      firstName: firstName ?? 'Test',
      lastName: lastName ?? 'User',
    );
  }
  
  /// Successful authentication response
  static AuthResponse createSuccessfulAuthResponse({
    User? user,
    String? token,
  }) {
    return AuthResponse(
      user: user ?? createTestUser(),
      token: token ?? 'mock-jwt-token-12345',
    );
  }
  
  /// Failed authentication response
  static AuthResponse createFailedAuthResponse({
    String? errorMessage,
  }) {
    return AuthResponse(
      errors: [
        FieldError(
          path: 'email', 
          message: errorMessage ?? 'Invalid email or password',
        ),
      ],
    );
  }
  
  // ============================================================================
  // COURSE DATA
  // ============================================================================
  
  /// Create a mock course session
  static CourseSession createCourseSession({
    String? id,
    String? courseId,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? location,
    String? sessionTitle,
  }) {
    final now = DateTime.now();
    return CourseSession(
      id: id ?? '1',
      courseId: courseId ?? 'course-1',
      startDateTime: startDateTime ?? now.add(const Duration(days: 7)),
      endDateTime: endDateTime ?? now.add(const Duration(days: 7, hours: 1)),
      location: location ?? 'Studio A',
      sessionTitle: sessionTitle ?? 'Session 1',
    );
  }
  
  /// Create a mock course group
  static CourseGroup createCourseGroup({
    int? id,
    String? name,
    String? description,
    int? minPrice,
    int? maxPrice,
    List<String>? attendanceTypes,
    List<String>? locations,
    String? danceType,
  }) {
    return CourseGroup(
      id: id ?? 1,
      name: name ?? 'Ballet Beginners',
      description: description ?? 'Perfect for beginners who want to learn ballet basics',
      minPrice: minPrice ?? 4500, // £45.00 in pence
      maxPrice: maxPrice ?? 4500,
      attendanceTypes: attendanceTypes ?? ['adults'],
      locations: locations ?? ['Studio A'],
      danceType: danceType ?? 'Ballet',
    );
  }
  
  /// Standard set of course groups for testing
  static List<CourseGroup> createStandardCourseGroups() {
    return [
      createCourseGroup(
        id: 1,
        name: 'Ballet Beginners',
        description: 'Perfect for beginners who want to learn ballet basics',
        minPrice: 4500, // £45.00
        maxPrice: 4500,
        attendanceTypes: ['adults'],
        locations: ['Studio A'],
        danceType: 'Ballet',
      ),
      createCourseGroup(
        id: 2,
        name: 'Jazz Intermediate',
        description: 'Intermediate level jazz dance classes',
        minPrice: 5000, // £50.00
        maxPrice: 5000,
        attendanceTypes: ['teens'],
        locations: ['Studio B'],
        danceType: 'Jazz',
      ),
      createCourseGroup(
        id: 3,
        name: 'Contemporary Advanced',
        description: 'Advanced contemporary dance techniques',
        minPrice: 5500, // £55.00
        maxPrice: 5500,
        attendanceTypes: ['adults'],
        locations: ['Studio A', 'Studio C'],
        danceType: 'Contemporary',
      ),
      createCourseGroup(
        id: 4,
        name: 'Hip Hop Kids',
        description: 'Fun hip hop classes designed for children',
        minPrice: 4000, // £40.00
        maxPrice: 4000,
        attendanceTypes: ['children'],
        locations: ['Studio B'],
        danceType: 'Hip Hop',
      ),
      createCourseGroup(
        id: 5,
        name: 'Tap Dancing All Levels',
        description: 'Tap dancing suitable for all experience levels',
        minPrice: 4800, // £48.00
        maxPrice: 4800,
        attendanceTypes: ['children', 'teens', 'adults'],
        locations: ['Studio A', 'Studio B'],
        danceType: 'Tap',
      ),
    ];
  }
  
  /// Create a mock term with course groups
  static Term createTerm({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    List<CourseGroup>? courseGroups,
  }) {
    final now = DateTime.now();
    return Term(
      id: id ?? 1,
      name: name ?? 'Spring Term 2024',
      startDate: startDate ?? now,
      endDate: endDate ?? now.add(const Duration(days: 90)),
      courseGroups: courseGroups ?? createStandardCourseGroups(),
    );
  }
  
  /// Standard set of terms for testing
  static List<Term> createStandardTerms() {
    final now = DateTime.now();
    return [
      createTerm(
        id: 1,
        name: 'Spring Term 2024',
        startDate: now,
        endDate: now.add(const Duration(days: 90)),
        courseGroups: createStandardCourseGroups(),
      ),
      createTerm(
        id: 2,
        name: 'Summer Term 2024',
        startDate: now.add(const Duration(days: 91)),
        endDate: now.add(const Duration(days: 181)),
        courseGroups: createStandardCourseGroups().take(3).toList(),
      ),
    ];
  }
  
  // ============================================================================
  // COURSE DATA  
  // ============================================================================
  
  /// Create a mock course
  static Course createCourse({
    String? id,
    String? name,
    String? shortDescription,
    String? type,
    int? price,
    DisplayStatus? displayStatus,
    bool? hasTasterClasses,
    int? tasterPrice,
  }) {
    return Course(
      id: id ?? '1',
      name: name ?? 'Test Course',
      shortDescription: shortDescription ?? 'A test course',
      type: type ?? 'StudioCourse',
      price: price ?? 5000,
      displayStatus: displayStatus ?? DisplayStatus.live,
      hasTasterClasses: hasTasterClasses ?? false,
      tasterPrice: tasterPrice ?? 0,
    );
  }
  
  /// Standard set of courses for testing
  static List<Course> createStandardCourses() {
    return [
      createCourse(
        id: '1',
        name: 'Ballet Beginners',
        shortDescription: 'Perfect for beginners',
        price: 4500,
        type: 'StudioCourse',
      ),
      createCourse(
        id: '2', 
        name: 'Jazz Intermediate',
        shortDescription: 'Intermediate jazz dance',
        price: 5000,
        type: 'StudioCourse',
      ),
      createCourse(
        id: '3',
        name: 'Online Contemporary',
        shortDescription: 'Contemporary dance online',
        price: 3000,
        type: 'OnlineCourse',
      ),
      createCourse(
        id: '4',
        name: 'Hip Hop Taster',
        shortDescription: 'Try hip hop dancing',
        price: 2000,
        tasterPrice: 2000,
        hasTasterClasses: true,
        type: 'StudioCourse',
      ),
    ];
  }
  
  /// Create a mock StudioCourse with specific properties
  static StudioCourse createTestStudioCourse({
    String? id,
    String? name,
    String? description,
    int? price,
    DisplayStatus? displayStatus,
    DanceType? danceType,
    Level? level,
    Location? location,
    bool? hasTasterClasses,
    int? tasterPrice,
  }) {
    return StudioCourse(
      id: id ?? '1',
      name: name ?? 'Ballet Beginners Studio',
      description: description ?? 'In-person ballet classes for beginners',
      price: price ?? 4500, // £45.00
      displayStatus: displayStatus ?? DisplayStatus.live,
      danceType: danceType ?? DanceType.ballet,
      level: level ?? Level.beginner,
      location: location ?? Location.studio1,
      hasTasterClasses: hasTasterClasses ?? true,
      tasterPrice: tasterPrice ?? 2500, // £25.00
      attendanceTypes: [AttendanceType.adults],
      address: const Address(
        line1: '123 Dance Street',
        city: 'London',
        postCode: 'SW1 1AA',
      ),
    );
  }
  
  /// Create a mock OnlineCourse with specific properties
  static OnlineCourse createTestOnlineCourse({
    String? id,
    String? name,
    String? description,
    int? price,
    DisplayStatus? displayStatus,
    DanceType? danceType,
    Level? level,
    bool? hasTasterClasses,
    int? tasterPrice,
  }) {
    return OnlineCourse(
      id: id ?? '2',
      name: name ?? 'Jazz Online Classes',
      description: description ?? 'Online jazz dance classes you can join from home',
      price: price ?? 3500, // £35.00
      displayStatus: displayStatus ?? DisplayStatus.live,
      danceType: danceType ?? DanceType.jazz,
      level: level ?? Level.intermediate,
      location: Location.online,
      hasTasterClasses: hasTasterClasses ?? true,
      tasterPrice: tasterPrice ?? 2000, // £20.00
      attendanceTypes: [AttendanceType.adults],
      zoomMeeting: const ZoomMeeting(
        meetingId: '123-456-789',
        password: 'dance123',
      ),
    );
  }
  
  /// Create a mock CourseSession 
  static CourseSession createTestCourseSession({
    String? id,
    String? courseId,
    DateTime? startDateTime,
    DateTime? endDateTime,
  }) {
    final now = DateTime.now();
    return CourseSession(
      id: id ?? '1',
      courseId: courseId ?? '1',
      startDateTime: startDateTime ?? now.add(const Duration(days: 7)),
      endDateTime: endDateTime ?? now.add(const Duration(days: 7, hours: 1)),
    );
  }
  
  /// Create a mock CourseGroup with test courses
  static CourseGroup createTestCourseGroup({
    int? id,
    String? name,
    String? description,
    List<Course>? courses,
  }) {
    return CourseGroup(
      id: id ?? 1,
      name: name ?? 'Test Course Group',
      description: description ?? 'A group of test courses for integration testing',
      courses: courses ?? [
        createCourse(id: '1', name: 'Studio Course in Group', type: 'StudioCourse'),
        createCourse(id: '2', name: 'Online Course in Group', type: 'OnlineCourse'),
      ],
      minPrice: 3500,
      maxPrice: 4500,
      attendanceTypes: ['adults'],
      locations: ['Studio 1', 'Online'],
      danceType: 'Mixed',
    );
  }
  
  // ============================================================================
  // BASKET DATA
  // ============================================================================
  
  /// Create a mock basket item
  static BasketItem createBasketItem({
    String? id,
    Course? course,
    int? price,
    int? totalPrice,
    bool? isTaster,
    int? discountValue,
    int? promoCodeDiscountValue,
  }) {
    return BasketItem(
      id: id ?? '1',
      course: course ?? createCourse(),
      price: price ?? 5000,
      totalPrice: totalPrice ?? 5000,
      isTaster: isTaster ?? false,
      discountValue: discountValue ?? 0,
      promoCodeDiscountValue: promoCodeDiscountValue ?? 0,
    );
  }
  
  /// Create a mock credit item
  static CreditItem createCreditItem({
    String? id,
    String? description,
    int? value,
    String? code,
  }) {
    return CreditItem(
      id: id ?? '1',
      description: description ?? 'Student Discount',
      value: value ?? 500,
      code: code ?? 'STUDENT10',
    );
  }
  
  /// Create a mock fee item
  static FeeItem createFeeItem({
    String? id,
    String? description,
    int? value,
    bool? optional,
  }) {
    return FeeItem(
      id: id ?? '1',
      description: description ?? 'Registration Fee',
      value: value ?? 1000,
      optional: optional ?? false,
    );
  }
  
  /// Create a mock basket
  static Basket createBasket({
    String? id,
    List<BasketItem>? items,
    int? total,
    int? subTotal,
    int? discountTotal,
    int? promoCodeDiscountValue,
    int? creditTotal,
    int? chargeTotal,
    int? payLater,
    List<CreditItem>? creditItems,
    List<FeeItem>? feeItems,
  }) {
    return Basket(
      id: id ?? '1',
      items: items ?? [],
      total: total ?? 0,
      subTotal: subTotal ?? 0,
      discountTotal: discountTotal ?? 0,
      promoCodeDiscountValue: promoCodeDiscountValue ?? 0,
      creditTotal: creditTotal ?? 0,
      chargeTotal: chargeTotal ?? total ?? 0,
      payLater: payLater ?? 0,
      creditItems: creditItems ?? [],
      feeItems: feeItems ?? [],
    );
  }
  
  /// Create a mock basket operation result
  static BasketOperationResult createBasketOperationResult({
    required bool success,
    Basket? basket,
    String? message,
    String? errorCode,
  }) {
    return BasketOperationResult(
      success: success,
      basket: basket ?? createBasket(),
      message: message ?? (success ? 'Operation successful' : 'Operation failed'),
      errorCode: errorCode,
    );
  }
  
  /// Standard empty basket
  static Basket get emptyBasket => createBasket(
    id: '1',
    items: [],
    total: 0,
  );
  
  /// Standard basket with items
  static Basket get basketWithItems => createBasket(
    id: '1',
    items: [
      createBasketItem(
        id: '1',
        course: createCourse(id: '1', name: 'Ballet Beginners', price: 4500),
        price: 4500,
        totalPrice: 4500,
      ),
      createBasketItem(
        id: '2', 
        course: createCourse(id: '4', name: 'Hip Hop Taster', price: 2000, hasTasterClasses: true),
        price: 2000,
        totalPrice: 2000,
        isTaster: true,
      ),
    ],
    subTotal: 6500,
    total: 6500,
    chargeTotal: 6500,
  );
  
  /// Standard basket with discounts
  static Basket get basketWithDiscounts => createBasket(
    id: '1',
    items: [
      createBasketItem(
        id: '1',
        course: createCourse(id: '1', name: 'Ballet Beginners', price: 5000),
        price: 5000,
        discountValue: 500,
        promoCodeDiscountValue: 250,
        totalPrice: 4250,
      ),
    ],
    subTotal: 5000,
    discountTotal: 500,
    promoCodeDiscountValue: 250,
    creditTotal: 100,
    total: 4150,
    chargeTotal: 4150,
    creditItems: [createCreditItem()],
  );
  
  /// Successful add to basket result
  static BasketOperationResult get successfulAddResult => createBasketOperationResult(
    success: true,
    basket: basketWithItems,
    message: 'Item added successfully',
  );
  
  /// Failed add to basket result
  static BasketOperationResult get failedAddResult => createBasketOperationResult(
    success: false,
    basket: emptyBasket,
    message: 'Course is full',
    errorCode: 'COURSE_FULL',
  );
  
  // ============================================================================
  // RESPONSE TIMING CONFIGURATION
  // ============================================================================
  
  /// Standard delays for mocked responses (realistic but fast)
  static const Duration authResponseDelay = Duration(milliseconds: 100);
  static const Duration dataLoadDelay = Duration(milliseconds: 150);
  static const Duration quickOperationDelay = Duration(milliseconds: 50);
  static const Duration minimalDelay = Duration(milliseconds: 10);
  static const Duration searchDelay = Duration(milliseconds: 200);
  static const Duration refreshDelay = Duration(milliseconds: 500);
  
  // ============================================================================
  // ERROR SCENARIOS
  // ============================================================================
  
  /// Common error messages that match real API responses
  static const String invalidCredentialsError = 'Invalid email or password';
  static const String networkError = 'Network request failed';
  static const String serverError = 'Internal server error';
  static const String notFoundError = 'Resource not found';
  static const String unauthorizedError = 'Unauthorized access';
  
  /// Create a network error response
  static Exception createNetworkError([String? message]) {
    return Exception(message ?? networkError);
  }
  
  /// Create a server error response
  static Exception createServerError([String? message]) {
    return Exception(message ?? serverError);
  }
  
  // ============================================================================
  // DATA VALIDATION HELPERS
  // ============================================================================
  
  /// Check if email is valid for testing
  static bool isValidTestEmail(String email) {
    return email == defaultTestEmail;
  }
  
  /// Check if password is valid for testing
  static bool isValidTestPassword(String password) {
    return password == defaultTestPassword;
  }
  
  /// Check if credentials are valid for testing
  static bool areValidTestCredentials(String email, String password) {
    return isValidTestEmail(email) && isValidTestPassword(password);
  }
}

/// Configuration for mock response behaviors
class MockConfig {
  /// Whether to simulate loading delays
  static bool enableDelays = true;
  
  /// Whether to simulate network errors
  static bool simulateNetworkErrors = false;
  
  /// Whether to simulate server errors
  static bool simulateServerErrors = false;
  
  /// Whether to return empty data sets
  static bool returnEmptyData = false;
  
  /// Reset to default testing configuration
  static void resetToDefaults() {
    enableDelays = true;
    simulateNetworkErrors = false;
    simulateServerErrors = false;
    returnEmptyData = false;
  }
  
  /// Configure for ultra-fast testing
  static void configureForSpeed() {
    enableDelays = false;
    simulateNetworkErrors = false;
    simulateServerErrors = false;
    returnEmptyData = false;
  }
  
  /// Configure for error testing
  static void configureForErrorTesting() {
    enableDelays = true;
    simulateNetworkErrors = true;
    simulateServerErrors = true;
    returnEmptyData = false;
  }
  
  /// Configure for empty state testing
  static void configureForEmptyState() {
    enableDelays = false;
    simulateNetworkErrors = false;
    simulateServerErrors = false;
    returnEmptyData = true;
  }
}