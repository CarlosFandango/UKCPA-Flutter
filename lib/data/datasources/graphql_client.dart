import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/services/device_info_service.dart';

GraphQLClient? _client;
final Logger _logger = Logger();

GraphQLClient getGraphQLClient() {
  if (_client != null) return _client!;
  
  // Platform-specific API URL
  String apiUrl = dotenv.env['API_URL'] ?? '';
  if (apiUrl.isEmpty) {
    // Fallback: auto-detect platform
    if (Platform.isIOS) {
      apiUrl = 'http://localhost:4000/graphql';
    } else if (Platform.isAndroid) {
      apiUrl = 'http://10.0.2.2:4000/graphql';
    } else {
      apiUrl = 'http://localhost:4000/graphql';
    }
  }
  
  _logger.d('Using GraphQL API URL: $apiUrl');
  
  // Configure timeout
  final timeout = int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  
  final httpClient = http.Client();
  final HttpLink httpLink = HttpLink(
    apiUrl,
    httpClient: httpClient,
  );
  
  final AuthLink authLink = AuthLink(
    getToken: () async {
      try {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: AppConstants.authTokenKey);
        if (token != null) {
          _logger.d('Auth token found for GraphQL request');
          return 'Bearer $token';
        }
        _logger.d('No auth token found - making unauthenticated request');
        return null;
      } catch (e) {
        _logger.e('Error retrieving auth token: $e');
        return null;
      }
    },
  );
  
  // Add device ID and site ID headers link
  final Link headersLink = Link.function((request, [forward]) {
    return DeviceInfoService.getDeviceId().then((deviceId) {
      _logger.d('Adding device ID and site ID headers to GraphQL request');
      
      request = request.updateContextEntry<HttpLinkHeaders>(
        (headers) => HttpLinkHeaders(
          headers: {
            ...headers?.headers ?? {},
            'siteid': 'UKCPA', // Hard-coded for UKCPA site
            'x-device-id': deviceId, // Device ID for mobile basket support
          },
        ),
      );
      return forward!(request);
    });
  });
  
  // Add error handling link
  final ErrorLink errorLink = ErrorLink(
    onException: (request, forward, exception) {
      _logger.e('GraphQL Error: ${exception.toString()}');
      return forward(request);
    },
  );
  
  // Create link chain with error handling, device ID, and auth
  final Link link = Link.from([
    errorLink,
    headersLink,
    authLink,
    httpLink,
  ]);
  
  _client = GraphQLClient(
    cache: GraphQLCache(store: HiveStore()),
    link: link,
    defaultPolicies: DefaultPolicies(
      watchQuery: Policies(
        fetch: FetchPolicy.cacheAndNetwork,
      ),
      query: Policies(
        fetch: FetchPolicy.cacheFirst,
      ),
      mutate: Policies(
        fetch: FetchPolicy.networkOnly,
      ),
    ),
  );
  
  return _client!;
}

// Helper function to handle GraphQL errors
String parseGraphQLError(OperationException exception) {
  _logger.e('GraphQL Operation Exception: ${exception.toString()}');
  
  // Handle authentication errors
  if (exception.graphqlErrors.isNotEmpty) {
    for (final error in exception.graphqlErrors) {
      _logger.e('GraphQL Error Details: ${error.message}');
      
      // Check for authentication errors
      if (error.extensions?['code'] == 'UNAUTHENTICATED' || 
          error.message.toLowerCase().contains('unauthorized') ||
          error.message.toLowerCase().contains('authentication')) {
        return AppConstants.sessionExpired;
      }
      
      // Check for validation errors
      if (error.extensions?['code'] == 'BAD_USER_INPUT') {
        return error.message;
      }
    }
    
    return exception.graphqlErrors.first.message;
  }
  
  // Handle network errors
  if (exception.linkException != null) {
    final linkException = exception.linkException!;
    _logger.e('Link Exception Details: ${linkException.toString()}');
    
    if (linkException is NetworkException) {
      return AppConstants.networkError;
    }
    
    if (linkException is ServerException) {
      return 'Server error occurred. Please try again later.';
    }
    
    return AppConstants.networkError;
  }
  
  return AppConstants.unknownError;
}

// Auth token management utilities
class AuthTokenManager {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConstants.authTokenKey, value: token);
      _logger.d('Auth token saved successfully');
    } catch (e) {
      _logger.e('Error saving auth token: $e');
      rethrow;
    }
  }
  
  static Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: AppConstants.authTokenKey);
      if (token != null) {
        _logger.d('Auth token retrieved successfully');
      } else {
        _logger.d('No auth token found');
      }
      return token;
    } catch (e) {
      _logger.e('Error retrieving auth token: $e');
      return null;
    }
  }
  
  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: AppConstants.authTokenKey);
      _logger.d('Auth token cleared successfully');
    } catch (e) {
      _logger.e('Error clearing auth token: $e');
      rethrow;
    }
  }
  
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

// GraphQL client utilities
class GraphQLClientUtils {
  // Reset client instance (useful for logout)
  static void resetClient() {
    _client = null;
    _logger.d('GraphQL client reset');
  }
  
  // Clear cache
  static Future<void> clearCache() async {
    try {
      final client = getGraphQLClient();
      client.cache.store.reset();
      _logger.d('GraphQL cache cleared successfully');
    } catch (e) {
      _logger.e('Error clearing GraphQL cache: $e');
    }
  }
  
  // Test connection with a simple query
  static Future<bool> testConnection() async {
    try {
      final client = getGraphQLClient();
      const query = '''
        query TestConnection {
          __typename
        }
      ''';
      
      final result = await client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      
      if (result.hasException) {
        _logger.e('Connection test failed: ${result.exception}');
        return false;
      }
      
      _logger.d('GraphQL connection test successful');
      return true;
    } catch (e) {
      _logger.e('Connection test error: $e');
      return false;
    }
  }
}

// GraphQL Fragments
class GraphQLFragments {
  static const String userBasicFragment = '''
    fragment UserBasicFragment on User {
      id
      firstName
      lastName
      email
      profileImageUrl
      address {
        line1
        line2
        city
        county
        country
        postCode
      }
      stripeCustomerId
      roles
    }
  ''';
  
  static const String studioCourseFragment = '''
    fragment StudioCourseFragment on StudioCourse {
      id
      name
      subtitle
      courseGroup {
        id
        name
      }
      ageFrom
      ageTo
      active
      level
      price
      originalPrice
      currentPrice
      depositPrice
      fullyBooked
      thumbImage
      image
      imagePosition {
        X
        Y
      }
      shortDescription
      description
      attendanceTypes
      startDateTime
      endDateTime
      weeks
      order
      listStyle
      days
      location
      danceType
      videos {
        id
        name
        description
        url
        provider
      }
      hasTasterClasses
      tasterPrice
      isAcceptingDeposits
      futureCourseSessions {
        id
        startDateTime
        endDateTime
      }
      sessions {
        id
        startDateTime
        endDateTime
      }
      instructions
      address {
        line1
        line2
        postCode
        city
        county
      }
    }
  ''';
  
  static const String onlineCourseFragment = '''
    fragment OnlineCourseFragment on OnlineCourse {
      id
      name
      subtitle
      courseGroup {
        id
        name
      }
      ageFrom
      ageTo
      active
      level
      price
      originalPrice
      currentPrice
      depositPrice
      fullyBooked
      thumbImage
      image
      imagePosition {
        X
        Y
      }
      shortDescription
      description
      attendanceTypes
      startDateTime
      endDateTime
      weeks
      order
      listStyle
      days
      hasTasterClasses
      isAcceptingDeposits
      danceType
      location
      tasterPrice
      futureCourseSessions {
        id
        startDateTime
        endDateTime
      }
      sessions {
        id
        startDateTime
        endDateTime
      }
      videos {
        id
        name
        description
        url
        provider
      }
      zoomMeeting {
        meetingId
        password
      }
    }
  ''';
  
  static const String basketFragment = '''
    fragment basketFieldsFragment on Basket {
      id
      items {
        id
        course {
          __typename
          ... on StudioCourse {
            ...StudioCourseFragment
          }
          ... on OnlineCourse {
            ...OnlineCourseFragment
          }
        }
        price
        discountValue
        promoCodeDiscountValue
        totalPrice
      }
      creditItems {
        id
        description
        value
      }
      feeItems {
        id
        description
        value
      }
      discountValue
      discountTotal
      promoCodeDiscountValue
      creditTotal
      subTotal
      tax
      total
      chargeTotal
      payLater
    }
  ''';
}