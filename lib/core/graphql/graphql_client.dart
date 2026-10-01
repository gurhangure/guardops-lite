import 'package:graphql_flutter/graphql_flutter.dart';

GraphQLClient createGraphQLClient({Link? link}) {
  return GraphQLClient(
    link: link ?? HttpLink('https://countries.trevorblades.com/'),
    cache: GraphQLCache(store: InMemoryStore()),
    queryRequestTimeout: const Duration(seconds: 15),
  );
}
