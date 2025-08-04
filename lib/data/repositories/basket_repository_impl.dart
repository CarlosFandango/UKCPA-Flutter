import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart' as logger;
import '../../domain/entities/basket.dart';
import '../../domain/repositories/basket_repository.dart';
import '../datasources/graphql_client.dart';

/// Implementation of BasketRepository using GraphQL API
/// Follows the same patterns as UKCPA-Website basket management
class BasketRepositoryImpl implements BasketRepository {
  final GraphQLClient _client;
  final logger.Logger _logger = logger.Logger();

  BasketRepositoryImpl({GraphQLClient? client})
      : _client = client ?? getGraphQLClient();

  @override
  Future<Basket?> getCurrentBasket() async {
    try {
      _logger.d('Fetching current basket');

      const query = '''
        query GetBasket {
          getBasket {
            basket {
              ...basketFieldsFragment
            }
            errors {
              path
              message
            }
          }
        }
        ${GraphQLFragments.basketFragment}
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in getCurrentBasket: ${result.exception}');
        throw BasketException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final basketResponse = result.data?['getBasket'];
      if (basketResponse == null) {
        return null;
      }

      final basketData = basketResponse['basket'];
      if (basketData == null) {
        return null;
      }

      final basket = Basket.fromJson(basketData);
      _logger.d('Successfully fetched basket with ${basket.itemCount} items');
      return basket;
    } catch (e) {
      _logger.e('Error fetching current basket: $e');
      
      if (e is BasketException) {
        rethrow;
      }
      
      throw BasketException(
        message: 'Failed to fetch basket: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<Basket> createAnonymousBasket() async {
    try {
      _logger.d('Creating anonymous basket');

      const mutation = '''
        mutation InitBasket {
          initBasket {
            basket {
              ...basketFieldsFragment
            }
            errors {
              path
              message
            }
          }
        }
        ${GraphQLFragments.basketFragment}
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in createAnonymousBasket: ${result.exception}');
        throw BasketException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final basketResponse = result.data?['initBasket'];
      if (basketResponse == null) {
        throw const BasketException(
          message: 'Invalid response format from server',
        );
      }

      // Check for errors in response
      final errors = basketResponse['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final error = errors.first as Map<String, dynamic>;
        throw BasketException(
          message: error['message'] as String,
        );
      }

      final basketData = basketResponse['basket'];
      if (basketData == null) {
        throw const BasketException(
          message: 'No basket data returned from server',
        );
      }

      final basket = Basket.fromJson(basketData);
      _logger.d('Successfully created anonymous basket');
      return basket;
    } catch (e) {
      _logger.e('Error creating anonymous basket: $e');
      
      if (e is BasketException) {
        rethrow;
      }
      
      throw BasketException(
        message: 'Failed to create basket: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<BasketOperationResult> addCourse(
    String courseId, {
    bool isTaster = false,
    String? sessionId,
  }) async {
    try {
      _logger.d('Adding course to basket: $courseId, isTaster: $isTaster, sessionId: $sessionId');

      // Determine item type and ID based on whether it's a taster session
      final String itemType;
      final int itemId;
      
      if (isTaster && sessionId != null) {
        itemType = 'CourseSession';
        itemId = int.parse(sessionId);
      } else {
        // Need to determine if it's StudioCourse or OnlineCourse
        // For now, we'll use a generic approach and let the server handle it
        itemType = 'Course'; // Server will determine the specific type
        itemId = int.parse(courseId);
      }

      const mutation = '''
        mutation AddItem(\$itemId: Float!, \$itemType: String!, \$payDeposit: Boolean) {
          addItem(itemId: \$itemId, itemType: \$itemType, payDeposit: \$payDeposit) {
            basket {
              ...basketFieldsFragment
            }
            errors {
              path
              message
            }
          }
        }
        ${GraphQLFragments.basketFragment}
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'itemId': itemId.toDouble(),
            'itemType': itemType,
            'payDeposit': false, // Default to full payment
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in addCourse: ${result.exception}');
        throw BasketException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final basketResponse = result.data?['addItem'];
      if (basketResponse == null) {
        throw const BasketException(
          message: 'Invalid response format from server',
        );
      }

      // Check for errors in response
      final errors = basketResponse['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final error = errors.first as Map<String, dynamic>;
        throw BasketException(
          message: error['message'] as String,
        );
      }

      final basketData = basketResponse['basket'];
      if (basketData == null) {
        throw const BasketException(
          message: 'No basket data returned from server',
        );
      }

      final basket = Basket.fromJson(basketData);
      _logger.d('Successfully added course to basket');
      
      return BasketOperationResult(
        success: true,
        basket: basket,
        message: 'Course added to basket',
      );
    } catch (e) {
      _logger.e('Error adding course to basket: $e');
      
      if (e is BasketException) {
        // Return failed operation result instead of throwing
        return BasketOperationResult(
          success: false,
          basket: const Basket(id: ''),
          message: e.message,
          errorCode: e.errorCode,
        );
      }
      
      return BasketOperationResult(
        success: false,
        basket: const Basket(id: ''),
        message: 'Failed to add course: ${e.toString()}',
      );
    }
  }

  @override
  Future<BasketOperationResult> removeCourse(String courseId) async {
    try {
      _logger.d('Removing course from basket: $courseId');

      const mutation = '''
        mutation RemoveItem(\$itemId: Float!, \$itemType: String!) {
          removeItem(itemId: \$itemId, itemType: \$itemType) {
            basket {
              ...basketFieldsFragment
            }
            errors {
              path
              message
            }
          }
        }
        ${GraphQLFragments.basketFragment}
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'itemId': int.parse(courseId).toDouble(),
            'itemType': 'Course',
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in removeCourse: ${result.exception}');
        throw BasketException(
          message: parseGraphQLError(result.exception!),
          originalError: result.exception,
        );
      }

      final basketResponse = result.data?['removeItem'];
      if (basketResponse == null) {
        throw const BasketException(
          message: 'Invalid response format from server',
        );
      }

      // Check for errors in response
      final errors = basketResponse['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final error = errors.first as Map<String, dynamic>;
        throw BasketException(
          message: error['message'] as String,
        );
      }

      final basketData = basketResponse['basket'];
      if (basketData == null) {
        throw const BasketException(
          message: 'No basket data returned from server',
        );
      }

      final basket = Basket.fromJson(basketData);
      _logger.d('Successfully removed course from basket');
      
      return BasketOperationResult(
        success: true,
        basket: basket,
        message: 'Course removed from basket',
      );
    } catch (e) {
      _logger.e('Error removing course from basket: $e');
      
      if (e is BasketException) {
        return BasketOperationResult(
          success: false,
          basket: const Basket(id: ''),
          message: e.message,
          errorCode: e.errorCode,
        );
      }
      
      return BasketOperationResult(
        success: false,
        basket: const Basket(id: ''),
        message: 'Failed to remove course: ${e.toString()}',
      );
    }
  }

  @override
  Future<BasketOperationResult> updateBasketItem(
    String itemId, {
    bool? isTaster,
    String? sessionId,
  }) async {
    // For now, implement as remove and add
    // TODO: Implement proper update mutation if available
    throw UnimplementedError('updateBasketItem not yet implemented');
  }

  @override
  Future<BasketOperationResult> clearBasket() async {
    // TODO: Implement clearBasket if mutation is available
    throw UnimplementedError('clearBasket not yet implemented');
  }

  @override
  Future<BasketOperationResult> applyPromoCode(String promoCode) async {
    // TODO: Implement applyPromoCode mutation
    throw UnimplementedError('applyPromoCode not yet implemented');
  }

  @override
  Future<BasketOperationResult> removePromoCode(String promoCode) async {
    // TODO: Implement removePromoCode mutation
    throw UnimplementedError('removePromoCode not yet implemented');
  }

  @override
  Future<BasketOperationResult> transferBasketToUser(
    String sessionId,
    String userId,
  ) async {
    // TODO: Implement basket transfer on user login
    throw UnimplementedError('transferBasketToUser not yet implemented');
  }

  @override
  Future<BasketOperationResult> refreshBasket() async {
    try {
      final basket = await getCurrentBasket();
      if (basket == null) {
        throw const BasketNotFoundException();
      }
      
      return BasketOperationResult(
        success: true,
        basket: basket,
        message: 'Basket refreshed',
      );
    } catch (e) {
      return BasketOperationResult(
        success: false,
        basket: const Basket(id: ''),
        message: 'Failed to refresh basket: ${e.toString()}',
      );
    }
  }

  @override
  Future<Basket?> getBasket(String basketId) async {
    // TODO: Implement getBasket by ID if needed
    throw UnimplementedError('getBasket by ID not yet implemented');
  }

  @override
  Future<void> saveBasketLocally(Basket basket) async {
    // TODO: Implement local storage for offline support
    throw UnimplementedError('saveBasketLocally not yet implemented');
  }

  @override
  Future<Basket?> loadBasketFromLocal() async {
    // TODO: Implement loading from local storage
    throw UnimplementedError('loadBasketFromLocal not yet implemented');
  }

  @override
  Future<void> clearLocalBasket() async {
    // TODO: Implement clearing local storage
    throw UnimplementedError('clearLocalBasket not yet implemented');
  }

  @override
  Future<DateTime?> getBasketExpiryTime() async {
    // TODO: Implement basket expiry time if available
    throw UnimplementedError('getBasketExpiryTime not yet implemented');
  }

  @override
  Future<BasketOperationResult> extendBasketExpiry() async {
    // TODO: Implement basket expiry extension if available
    throw UnimplementedError('extendBasketExpiry not yet implemented');
  }
}