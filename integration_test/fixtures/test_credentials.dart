/// Test credentials and configuration for integration tests
class TestCredentials {
  // Valid test user credentials
  static const String validEmail = 'test@ukcpa.com';
  static const String validPassword = 'testpassword';
  static const String validFirstName = 'Test';
  static const String validLastName = 'User';
  static const String validPhone = '+44 7700 900123';
  
  // Alternative valid credentials
  static const String altEmail = 'info@carl-stanley.com';
  static const String altPassword = 'password';
  
  // Invalid credentials for negative testing
  static const String invalidEmail = 'invalid@test.com';
  static const String invalidPassword = 'wrongpassword';
  static const String malformedEmail = 'notanemail';
  
  // Test promo codes
  static const String validPromoCode = 'TEST10';
  static const String expiredPromoCode = 'EXPIRED';
  static const String invalidPromoCode = 'INVALID123';
  
  // Test payment details (for mock payments)
  static const String validCardNumber = '4242424242424242';
  static const String validCardExpiry = '12/25';
  static const String validCardCVV = '123';
  static const String validCardZip = 'SW1A 1AA';
  
  // Alternative valid payment details
  static const String testCardNumber = '4242424242424242';
  static const String testCardExpiry = '12/25';
  static const String testCardCvc = '123';
  static const String testCardZip = 'SW1A 1AA';
  
  // Test addresses
  static const Map<String, String> testBillingAddress = {
    'firstName': 'Test',
    'lastName': 'User',
    'addressLine1': '123 Test Street',
    'addressLine2': 'Apt 4B',
    'city': 'London',
    'postcode': 'SW1A 1AA',
    'country': 'United Kingdom',
  };
  
  // Test search terms
  static const String validSearchTerm = 'Ballet';
  static const String noResultsSearchTerm = 'XYZ123ABC';
  
  // API Configuration
  static const String testApiUrl = 'http://localhost:4000/graphql';
  static const String testSiteId = 'UKCPA';
  
  // Timeouts (in seconds)
  static const int networkTimeout = 30;
  static const int animationTimeout = 10;
  static const int pageLoadTimeout = 15;
}

/// Test data for courses and baskets
class TestData {
  // Expected course group names (update based on actual test data)
  static const List<String> expectedCourseGroups = [
    'Adult Ballet',
    'Children\'s Dance',
    'Contemporary Dance',
  ];
  
  // Expected price ranges
  static const double minCoursePrice = 50.0;
  static const double maxCoursePrice = 500.0;
  
  // Basket test data
  static const int maxBasketItems = 10;
  static const double expectedDiscountPercent = 10.0;
  
  // Test user credit amount
  static const double testUserCredit = 25.0;
}

/// Environment configuration for tests
class TestEnvironment {
  /// Check if we're running in CI/CD environment
  static bool get isCI => 
      const String.fromEnvironment('CI', defaultValue: 'false') == 'true';
  
  /// Should take screenshots during tests
  static bool get shouldTakeScreenshots => !isCI || 
      const bool.fromEnvironment('TAKE_SCREENSHOTS', defaultValue: false);
  
  /// Backend server URL
  static String get backendUrl => 
      const String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:4000');
  
  /// GraphQL endpoint
  static String get graphqlEndpoint => '$backendUrl/graphql';
  
  /// Test mode - affects certain behaviors
  static bool get isTestMode => true;
}

/// Test feature flags
class TestFeatureFlags {
  // Enable/disable specific test groups
  static const bool runAuthTests = true;
  static const bool runCourseTests = true;
  static const bool runBasketTests = true;
  static const bool runCheckoutTests = true;
  static const bool runPaymentTests = false; // Disabled until Stripe integration
  
  // Performance optimizations
  static const bool useHeadlessMode = true;
  static const bool skipAnimations = true;
  static const bool reduceNetworkPolling = true;
}

/// Test timing configurations to optimize test speed
class TestTiming {
  // Reduced timeouts for faster tests
  static const Duration shortWait = Duration(milliseconds: 100);
  static const Duration mediumWait = Duration(milliseconds: 500);
  static const Duration longWait = Duration(seconds: 2);
  
  // Network timeouts
  static const Duration networkWait = Duration(seconds: 5);
  static const Duration graphqlTimeout = Duration(seconds: 10);
  
  // Animation durations (can be shortened in tests)
  static const Duration animationWait = Duration(milliseconds: 300);
  static const Duration transitionWait = Duration(milliseconds: 200);
}