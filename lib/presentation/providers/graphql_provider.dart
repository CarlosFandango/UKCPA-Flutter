import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../data/datasources/graphql_client.dart';

/// Provider for GraphQL client instance
final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  return getGraphQLClient();
});

/// Provider to test GraphQL connection
final graphqlConnectionProvider = FutureProvider<bool>((ref) async {
  return await GraphQLClientUtils.testConnection();
});

/// Provider for GraphQL client utilities
final graphqlUtilsProvider = Provider<Type>((ref) {
  return GraphQLClientUtils;
});

/// Helper provider to reset GraphQL client (useful for logout)
final graphqlResetProvider = Provider<void Function()>((ref) {
  return () {
    GraphQLClientUtils.resetClient();
    // Invalidate the client provider to force recreation
    ref.invalidate(graphqlClientProvider);
  };
});