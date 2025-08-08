import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/basket.dart';
import '../../domain/repositories/basket_repository.dart';
import '../datasources/graphql_client.dart';

/// Implementation of BasketRepository using GraphQL API
/// Based on UKCPA website basket functionality
class BasketRepositoryImpl implements BasketRepository {
  final GraphQLClient _client;
  final Logger _logger = Logger();

  BasketRepositoryImpl({GraphQLClient? client})
      : _client = client ?? getGraphQLClient();

  @override
  Future<Basket> initBasket() async {
    try {
      _logger.d('Initializing new basket');

      const mutation = '''
        mutation InitBasket {
          initBasket {
            basket {
              id
              items { id price totalPrice }
              subTotal
              total
              chargeTotal
              payLater
              createdAt
            }
            errors {
              path
              message
            }
          }
        }
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in initBasket: ${result.exception}');
        throw BasketException('Failed to initialize basket: ${result.exception}');
      }

      final basketResponse = result.data?['initBasket'];
      if (basketResponse == null || basketResponse['basket'] == null) {
        throw const BasketException('Invalid response from server');
      }

      final basket = Basket.fromJson(basketResponse['basket']);
      _logger.d('Successfully initialized basket: ${basket.id}');
      return basket;
    } catch (e) {
      _logger.e('Error initializing basket: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to initialize basket: $e');
    }
  }

  @override
  Future<Basket?> getBasket() async {
    try {
      _logger.d('Fetching current basket');

      const query = '''
        query GetBasket {
          getBasket {
            basket {
              id
              items {
                id
                course { id name price }
                price
                totalPrice
                isTaster
                sessionId
              }
              subTotal
              total
              chargeTotal
              payLater
              discountTotal
              creditTotal
              createdAt
            }
            errors {
              path
              message
            }
          }
        }
      ''';

      final result = await _client.query(
        QueryOptions(
          document: gql(query),
          fetchPolicy: FetchPolicy.cacheAndNetwork,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in getBasket: ${result.exception}');
        throw BasketException('Failed to fetch basket: ${result.exception}');
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
      _logger.e('Error fetching basket: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to fetch basket: $e');
    }
  }

  @override
  Future<BasketOperationResult> addItem(
    String itemId, {
    required String itemType,
    bool? payDeposit,
    String? assignToUserId,
    DateTime? chargeFromDate,
  }) async {
    try {
      _logger.d('Adding item to basket: $itemId ($itemType)');

      const mutation = '''
        mutation AddItem(
          \$itemId: Float!
          \$itemType: String!
          \$payDeposit: Boolean
          \$assignToUserId: String
          \$chargeFromDate: Float
        ) {
          addItem(
            itemId: \$itemId
            itemType: \$itemType
            payDeposit: \$payDeposit
            assignToUserId: \$assignToUserId
            chargeFromDate: \$chargeFromDate
          ) {
            basket {
              id
              items { id price totalPrice }
              subTotal
              total
              chargeTotal
              payLater
            }
            errors {
              path
              message
            }
          }
        }
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'itemId': double.parse(itemId), // Convert string ID to Float
            'itemType': itemType,
            'payDeposit': payDeposit,
            'assignToUserId': assignToUserId,
            'chargeFromDate': chargeFromDate?.millisecondsSinceEpoch.toDouble(),
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in addItem: ${result.exception}');
        throw BasketException('Failed to add item to basket: ${result.exception}');
      }

      final response = result.data?['addItem'];
      if (response == null) {
        throw const BasketException('Invalid response from server');
      }

      // Convert backend response format to expected format
      final errors = response['errors'] as List<dynamic>?;
      final success = errors == null || errors.isEmpty;
      final message = errors != null && errors.isNotEmpty
          ? errors.first['message'] as String?
          : null;
      
      final operationResult = BasketOperationResult(
        success: success,
        basket: Basket.fromJson(response['basket']),
        message: message,
        errorCode: errors != null && errors.isNotEmpty
            ? errors.first['path'] as String?
            : null,
      );
      
      _logger.d('Add item result: ${operationResult.success}');
      return operationResult;
    } catch (e) {
      _logger.e('Error adding item to basket: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to add item to basket: $e');
    }
  }

  @override
  Future<BasketOperationResult> removeItem(String itemId, String itemType) async {
    try {
      _logger.d('Removing item from basket: $itemId ($itemType)');

      const mutation = '''
        mutation RemoveItem(\$itemId: Float!, \$itemType: String!) {
          removeItem(itemId: \$itemId, itemType: \$itemType) {
            basket {
              id
              items { id price totalPrice }
              subTotal
              total
              chargeTotal
              payLater
            }
            errors {
              path
              message
            }
          }
        }
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'itemId': double.parse(itemId), // Convert string ID to Float
            'itemType': itemType,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in removeItem: ${result.exception}');
        throw BasketException('Failed to remove item from basket: ${result.exception}');
      }

      final response = result.data?['removeItem'];
      if (response == null) {
        throw const BasketException('Invalid response from server');
      }

      // Convert backend response format to expected format
      final errors = response['errors'] as List<dynamic>?;
      final success = errors == null || errors.isEmpty;
      final message = errors != null && errors.isNotEmpty
          ? errors.first['message'] as String?
          : null;
      
      final operationResult = BasketOperationResult(
        success: success,
        basket: Basket.fromJson(response['basket']),
        message: message,
        errorCode: errors != null && errors.isNotEmpty
            ? errors.first['path'] as String?
            : null,
      );
      
      _logger.d('Remove item result: ${operationResult.success}');
      return operationResult;
    } catch (e) {
      _logger.e('Error removing item from basket: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to remove item from basket: $e');
    }
  }

  @override
  Future<bool> destroyBasket() async {
    try {
      _logger.d('Destroying current basket');

      const mutation = '''
        mutation DestroyBasket {
          destroyBasket
        }
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in destroyBasket: ${result.exception}');
        throw BasketException('Failed to destroy basket: ${result.exception}');
      }

      final success = result.data?['destroyBasket'] as bool? ?? false;
      
      _logger.d('Destroy basket result: $success');
      return success;
    } catch (e) {
      _logger.e('Error destroying basket: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to destroy basket: $e');
    }
  }

  @override
  Future<BasketOperationResult> useCreditForBasket(bool useCredit) async {
    try {
      _logger.d('Setting credit usage for basket: $useCredit');

      const mutation = '''
        mutation UseCreditForBasket(\$useCredit: Boolean!) {
          useCreditForBasket(useCredit: \$useCredit) {
            basket {
              id
              creditTotal
              total
              chargeTotal
            }
            errors {
              path
              message
            }
          }
        }
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'useCredit': useCredit},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in useCreditForBasket: ${result.exception}');
        throw BasketException('Failed to update credit usage: ${result.exception}');
      }

      final response = result.data?['useCreditForBasket'];
      if (response == null) {
        throw const BasketException('Invalid response from server');
      }

      // Convert backend response format to expected format
      final errors = response['errors'] as List<dynamic>?;
      final success = errors == null || errors.isEmpty;
      final message = errors != null && errors.isNotEmpty
          ? errors.first['message'] as String?
          : null;
      
      final operationResult = BasketOperationResult(
        success: success,
        basket: Basket.fromJson(response['basket']),
        message: message,
        errorCode: errors != null && errors.isNotEmpty
            ? errors.first['path'] as String?
            : null,
      );
      
      _logger.d('Credit usage result: ${operationResult.success}');
      return operationResult;
    } catch (e) {
      _logger.e('Error updating credit usage: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to update credit usage: $e');
    }
  }

  @override
  Future<BasketOperationResult> applyPromoCode(String code) async {
    try {
      _logger.d('Applying promo code: $code');

      const mutation = '''
        mutation ApplyPromoCode(\$code: String!) {
          applyPromoCode(code: \$code) {
            id
            promoCodeDiscountValue
            discountTotal
            total
            chargeTotal
          }
        }
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {'code': code},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in applyPromoCode: ${result.exception}');
        throw BasketException('Failed to apply promo code: ${result.exception}');
      }

      final basketData = result.data?['applyPromoCode'];
      if (basketData == null) {
        throw const BasketException('Invalid response from server');
      }

      // Since mutation returns Basket directly, wrap it in operation result
      final operationResult = BasketOperationResult(
        success: true,
        basket: Basket.fromJson(basketData),
        message: 'Promo code applied successfully',
      );
      
      _logger.d('Apply promo code result: ${operationResult.success}');
      return operationResult;
    } catch (e) {
      _logger.e('Error applying promo code: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to apply promo code: $e');
    }
  }

  @override
  Future<BasketOperationResult> removePromoCode() async {
    try {
      _logger.d('Removing promo codes from basket');

      const mutation = '''
        mutation RemovePromoCode {
          removePromoCode {
            id
            promoCodeDiscountValue
            discountTotal
            total
            chargeTotal
          }
        }
      ''';

      final result = await _client.mutate(
        MutationOptions(
          document: gql(mutation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );

      if (result.hasException) {
        _logger.e('GraphQL error in removePromoCode: ${result.exception}');
        throw BasketException('Failed to remove promo code: ${result.exception}');
      }

      final basketData = result.data?['removePromoCode'];
      if (basketData == null) {
        throw const BasketException('Invalid response from server');
      }

      // Since mutation returns Basket directly, wrap it in operation result
      final operationResult = BasketOperationResult(
        success: true,
        basket: Basket.fromJson(basketData),
        message: 'Promo code removed successfully',
      );
      
      _logger.d('Remove promo code result: ${operationResult.success}');
      return operationResult;
    } catch (e) {
      _logger.e('Error removing promo code: $e');
      if (e is BasketException) rethrow;
      throw BasketException('Failed to remove promo code: $e');
    }
  }

  @override
  Stream<Basket?> watchBasket() {
    // For now, implement a simple polling approach
    // In a production app, this could use GraphQL subscriptions
    return Stream.periodic(const Duration(seconds: 30))
        .asyncMap((_) => getBasket())
        .distinct();
  }

  @override
  Future<int> getBasketItemCount() async {
    try {
      final basket = await getBasket();
      return basket?.itemCount ?? 0;
    } catch (e) {
      _logger.w('Error fetching basket item count: $e');
      return 0;
    }
  }

  @override
  Future<bool> isItemInBasket(String itemId, String itemType) async {
    try {
      final basket = await getBasket();
      if (basket == null) return false;
      
      return basket.items.any((item) => 
        item.course.id == itemId && 
        (itemType == 'taster' ? item.isTaster : !item.isTaster)
      );
    } catch (e) {
      _logger.w('Error checking if item is in basket: $e');
      return false;
    }
  }
}