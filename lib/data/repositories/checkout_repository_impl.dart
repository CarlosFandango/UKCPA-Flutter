import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/entities/basket.dart';
import '../../domain/repositories/checkout_repository.dart';

/// GraphQL-based implementation of checkout repository
/// Integrates with UKCPA-Server checkout and payment endpoints
class CheckoutRepositoryImpl implements CheckoutRepository {
  final GraphQLClient _client;
  final Logger _logger = Logger();

  CheckoutRepositoryImpl(this._client);

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    const query = '''
      query GetPaymentMethods {
        getPaymentMethods {
          paymentMethods {
            id
            type
            last4
            brand
            expiryMonth
            expiryYear
            isDefault
            billingAddress {
              id
              name
              line1
              line2
              city
              county
              postCode
              country
              countryCode
            }
            createdAt
          }
        }
      }
    ''';

    try {
      final result = await _client.query(QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        _logger.e('Error fetching payment methods: ${result.exception}');
        throw Exception('Failed to fetch payment methods');
      }

      final data = result.data?['getPaymentMethods'];
      if (data == null) {
        _logger.w('No payment methods data returned');
        return [];
      }

      final paymentMethodsJson = data['paymentMethods'] as List<dynamic>? ?? [];
      return paymentMethodsJson
          .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error in getPaymentMethods: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<String> getStripePublishableKey() async {
    const query = '''
      query GetStripePK {
        getStripe
      }
    ''';

    try {
      final result = await _client.query(QueryOptions(
        document: gql(query),
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        _logger.e('Error fetching Stripe key: ${result.exception}');
        throw Exception('Failed to fetch Stripe publishable key');
      }

      final stripeKey = result.data?['getStripe'] as String?;
      if (stripeKey == null || stripeKey.isEmpty) {
        throw Exception('No Stripe publishable key returned');
      }

      return stripeKey;
    } catch (e, stackTrace) {
      _logger.e('Error in getStripePublishableKey: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<PaymentMethod> createPaymentMethod({
    required String stripePaymentMethodId,
    required Address billingAddress,
    bool setAsDefault = false,
  }) async {
    const mutation = '''
      mutation CreatePaymentMethod(
        \$stripePaymentMethodId: String!
        \$billingAddress: AddressInput!
        \$setAsDefault: Boolean
      ) {
        createPaymentMethod(
          stripePaymentMethodId: \$stripePaymentMethodId
          billingAddress: \$billingAddress
          setAsDefault: \$setAsDefault
        ) {
          id
          type
          last4
          brand
          expiryMonth
          expiryYear
          isDefault
          billingAddress {
            id
            name
            line1
            line2
            city
            county
            postCode
            country
            countryCode
          }
          createdAt
        }
      }
    ''';

    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {
          'stripePaymentMethodId': stripePaymentMethodId,
          'billingAddress': {
            'name': billingAddress.name,
            'line1': billingAddress.line1,
            'line2': billingAddress.line2,
            'city': billingAddress.city,
            'county': billingAddress.county,
            'postCode': billingAddress.postCode,
            'country': billingAddress.country,
            'countryCode': billingAddress.countryCode,
          },
          'setAsDefault': setAsDefault,
        },
      ));

      if (result.hasException) {
        _logger.e('Error creating payment method: ${result.exception}');
        throw Exception('Failed to create payment method');
      }

      final data = result.data?['createPaymentMethod'];
      if (data == null) {
        throw Exception('No payment method data returned');
      }

      return PaymentMethod.fromJson(data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      _logger.e('Error in createPaymentMethod: $e');
      _logger.e('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<bool> deletePaymentMethod(String paymentMethodId) async {
    const mutation = '''
      mutation DeletePaymentMethod(\$paymentMethodId: String!) {
        deletePaymentMethod(paymentMethodId: \$paymentMethodId)
      }
    ''';

    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'paymentMethodId': paymentMethodId},
      ));

      if (result.hasException) {
        _logger.e('Error deleting payment method: ${result.exception}');
        return false;
      }

      return result.data?['deletePaymentMethod'] == true;
    } catch (e, stackTrace) {
      _logger.e('Error in deletePaymentMethod: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    const mutation = '''
      mutation SetDefaultPaymentMethod(\$paymentMethodId: String!) {
        setDefaultPaymentMethod(paymentMethodId: \$paymentMethodId)
      }
    ''';

    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'paymentMethodId': paymentMethodId},
      ));

      if (result.hasException) {
        _logger.e('Error setting default payment method: ${result.exception}');
        return false;
      }

      return result.data?['setDefaultPaymentMethod'] == true;
    } catch (e, stackTrace) {
      _logger.e('Error in setDefaultPaymentMethod: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<PaymentResult> placeOrder({
    required Basket basket,
    String? paymentMethodId,
    required String paymentMethodType,
    Address? billingAddress,
    Map<String, dynamic>? lineItemInfo,
  }) async {
    const mutation = '''
      mutation PlaceOrder(\$data: PlaceOrderInput!) {
        placeOrder(data: \$data) {
          order {
            id
            userId
            items {
              id
              itemId
              itemType
              itemName
              price
              totalPrice
              discountValue
              promoCodeDiscountValue
              assignToUserId
              assignToUserName
              chargeFromDate
              extraInfo
              createdAt
            }
            subTotal
            discountTotal
            promoCodeDiscountValue
            creditTotal
            tax
            total
            chargeTotal
            payLater
            status
            paymentMethodId
            paymentMethodType
            paymentIntentId
            paymentTransactionStatus
            billingAddress {
              id
              name
              line1
              line2
              city
              county
              postCode
              country
              countryCode
            }
            notes
            createdAt
            updatedAt
          }
          nextAction {
            clientSecret
            type
          }
          paymentTransactionStatus
          errors {
            field
            message
          }
        }
      }
    ''';

    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {
          'data': {
            'amount': basket.chargeTotal,
            'currency': 'gbp',
            'paymentMethod': paymentMethodId,
            'paymentMethodType': paymentMethodType,
            'lineItemInfo': lineItemInfo ?? {},
            if (billingAddress != null) 'billingAddress': {
              'name': billingAddress.name,
              'line1': billingAddress.line1,
              'line2': billingAddress.line2,
              'city': billingAddress.city,
              'county': billingAddress.county,
              'postCode': billingAddress.postCode,
              'country': billingAddress.country,
              'countryCode': billingAddress.countryCode,
            },
          },
        },
      ));

      if (result.hasException) {
        _logger.e('Error placing order: ${result.exception}');
        return const PaymentResult(
          success: false,
          error: 'Failed to place order',
          errorCode: 'NETWORK_ERROR',
        );
      }

      final data = result.data?['placeOrder'];
      if (data == null) {
        return const PaymentResult(
          success: false,
          error: 'No order data returned',
          errorCode: 'NO_DATA',
        );
      }

      final errors = data['errors'] as List<dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final errorMessage = errors.first['message'] as String? ?? 'Unknown error';
        return PaymentResult(
          success: false,
          error: errorMessage,
          errorCode: 'ORDER_ERROR',
        );
      }

      final orderData = data['order'];
      final nextAction = data['nextAction'];
      final paymentTransactionStatus = data['paymentTransactionStatus'];

      if (orderData == null) {
        return const PaymentResult(
          success: false,
          error: 'No order created',
          errorCode: 'NO_ORDER',
        );
      }

      final order = Order.fromJson(orderData as Map<String, dynamic>);

      return PaymentResult(
        success: true,
        order: order,
        clientSecret: nextAction?['clientSecret'] as String?,
        nextAction: nextAction?['type'] as String? ?? 'none',
        paymentTransactionStatus: paymentTransactionStatus as String?,
      );
    } catch (e, stackTrace) {
      _logger.e('Error in placeOrder: $e');
      _logger.e('Stack trace: $stackTrace');
      return PaymentResult(
        success: false,
        error: e.toString(),
        errorCode: 'EXCEPTION_ERROR',
      );
    }
  }

  @override
  Future<bool> updatePaymentIntent(String paymentIntentId) async {
    const mutation = '''
      mutation UpdatePaymentIntent(\$id: String!) {
        updatePaymentIntent(id: \$id)
      }
    ''';

    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'id': paymentIntentId},
      ));

      if (result.hasException) {
        _logger.e('Error updating payment intent: ${result.exception}');
        return false;
      }

      return result.data?['updatePaymentIntent'] == true;
    } catch (e, stackTrace) {
      _logger.e('Error in updatePaymentIntent: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<Order?> getOrder(String orderId) async {
    const query = '''
      query GetOrder(\$orderId: String!) {
        getOrder(orderId: \$orderId) {
          id
          userId
          items {
            id
            itemId
            itemType
            itemName
            price
            totalPrice
            discountValue
            promoCodeDiscountValue
            assignToUserId
            assignToUserName
            chargeFromDate
            extraInfo
            createdAt
          }
          subTotal
          discountTotal
          promoCodeDiscountValue
          creditTotal
          tax
          total
          chargeTotal
          payLater
          status
          paymentMethodId
          paymentMethodType
          paymentIntentId
          paymentTransactionStatus
          billingAddress {
            id
            name
            line1
            line2
            city
            county
            postCode
            country
            countryCode
          }
          notes
          createdAt
          updatedAt
        }
      }
    ''';

    try {
      final result = await _client.query(QueryOptions(
        document: gql(query),
        variables: {'orderId': orderId},
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        _logger.e('Error fetching order: ${result.exception}');
        return null;
      }

      final data = result.data?['getOrder'];
      if (data == null) {
        return null;
      }

      return Order.fromJson(data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      _logger.e('Error in getOrder: $e');
      _logger.e('Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<List<Order>> getOrderHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    const query = '''
      query GetOrderHistory(\$limit: Int, \$offset: Int) {
        getOrderHistory(limit: \$limit, offset: \$offset) {
          orders {
            id
            userId
            items {
              id
              itemId
              itemType
              itemName
              price
              totalPrice
              discountValue
              promoCodeDiscountValue
              assignToUserId
              assignToUserName
              chargeFromDate
              extraInfo
              createdAt
            }
            subTotal
            discountTotal
            promoCodeDiscountValue
            creditTotal
            tax
            total
            chargeTotal
            payLater
            status
            paymentMethodId
            paymentMethodType
            paymentIntentId
            paymentTransactionStatus
            billingAddress {
              id
              name
              line1
              line2
              city
              county
              postCode
              country
              countryCode
            }
            notes
            createdAt
            updatedAt
          }
          totalCount
        }
      }
    ''';

    try {
      final result = await _client.query(QueryOptions(
        document: gql(query),
        variables: {
          'limit': limit,
          'offset': offset,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ));

      if (result.hasException) {
        _logger.e('Error fetching order history: ${result.exception}');
        return [];
      }

      final data = result.data?['getOrderHistory'];
      if (data == null) {
        return [];
      }

      final ordersJson = data['orders'] as List<dynamic>? ?? [];
      return ordersJson
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _logger.e('Error in getOrderHistory: $e');
      _logger.e('Stack trace: $stackTrace');
      return [];
    }
  }

  @override
  Future<bool> cancelOrder(String orderId) async {
    const mutation = '''
      mutation CancelOrder(\$orderId: String!) {
        cancelOrder(orderId: \$orderId)
      }
    ''';

    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'orderId': orderId},
      ));

      if (result.hasException) {
        _logger.e('Error cancelling order: ${result.exception}');
        return false;
      }

      return result.data?['cancelOrder'] == true;
    } catch (e, stackTrace) {
      _logger.e('Error in cancelOrder: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<bool> processRefund({
    required String orderId,
    required int amount,
    String? reason,
  }) async {
    const mutation = '''
      mutation ProcessRefund(
        \$orderId: String!
        \$amount: Int!
        \$reason: String
      ) {
        processRefund(
          orderId: \$orderId
          amount: \$amount
          reason: \$reason
        )
      }
    ''';

    try {
      final result = await _client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {
          'orderId': orderId,
          'amount': amount,
          'reason': reason,
        },
      ));

      if (result.hasException) {
        _logger.e('Error processing refund: ${result.exception}');
        return false;
      }

      return result.data?['processRefund'] == true;
    } catch (e, stackTrace) {
      _logger.e('Error in processRefund: $e');
      _logger.e('Stack trace: $stackTrace');
      return false;
    }
  }
}