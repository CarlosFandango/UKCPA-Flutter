class AppConstants {
  // App Info
  static const String appName = 'UKCPA';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String graphQLEndpoint = '/graphql';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Cache Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String basketKey = 'basket_data';
  static const String guestBasketKey = 'guest_basket';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
  
  // Error Messages
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String sessionExpired = 'Your session has expired. Please login again.';
  
  // Success Messages
  static const String loginSuccess = 'Successfully logged in!';
  static const String registrationSuccess = 'Account created successfully!';
  static const String addToBasketSuccess = 'Item added to basket';
  static const String orderSuccess = 'Order placed successfully!';
  
  // Validation Messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String firstNameRequired = 'First name is required';
  static const String lastNameRequired = 'Last name is required';
  
  // Item Types
  static const String courseItemType = 'course';
  static const String courseSessionItemType = 'courseSession';
  static const String examItemType = 'exam';
  static const String eventItemType = 'event';
  
  // Payment Method Types
  static const String cardPayment = 'CARD';
  static const String bankTransferPayment = 'BANK_TRANSFER';
  static const String cashPayment = 'CASH';
  
  // Course Types
  static const String studioCourse = 'StudioCourse';
  static const String onlineCourse = 'OnlineCourse';
  
  // User Roles
  static const String adminRole = 'ADMIN';
  static const String teacherRole = 'TEACHER';
  static const String studentRole = 'STUDENT';
  
  // Sites
  static const String ukcpaSite = 'UKCPA';
  static const String catsSite = 'CATS';
  static const String eventsSite = 'EVENTS';
  
  // Stripe Configuration
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_YOUR_TEST_KEY_HERE', // Fallback for development
  );
  
  static const String stripeMerchantId = 'merchant.com.ukcpa.app';
  static const String stripeReturnUrl = 'stripesdk://payment_return_url/ukcpa';
  static const String stripeCountryCode = 'GB';
  static const String stripeCurrency = 'GBP';
  
  // Stripe Test Cards (for development reference)
  static const String stripeTestCardSuccess = '4242424242424242';
  static const String stripeTestCard3DS = '4000002500003155';
  static const String stripeTestCardDeclined = '4000000000000002';
}