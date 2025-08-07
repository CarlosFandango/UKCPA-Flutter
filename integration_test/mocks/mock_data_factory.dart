/// Centralized mock data factory for integration tests
/// 
/// This file provides a single source of truth for all mock data used across
/// integration tests. When GraphQL schemas or response structures change,
/// update the data here to maintain consistency across all tests.

import 'package:ukcpa_flutter/domain/entities/user.dart';
import 'package:ukcpa_flutter/domain/entities/term.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/course_session.dart';
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
  // RESPONSE TIMING CONFIGURATION
  // ============================================================================
  
  /// Standard delays for mocked responses (realistic but fast)
  static const Duration authResponseDelay = Duration(milliseconds: 100);
  static const Duration dataLoadDelay = Duration(milliseconds: 150);
  static const Duration quickOperationDelay = Duration(milliseconds: 50);
  static const Duration minimalDelay = Duration(milliseconds: 10);
  
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