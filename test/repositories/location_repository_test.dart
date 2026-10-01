import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:guardops_lite/core/graphql/graphql_client.dart';
import 'package:guardops_lite/core/graphql/location_queries.dart';
import 'package:guardops_lite/repositories/location_repository.dart';

const continent = {'code': 'EU', 'name': 'Europe'};
const country = {
  'code': 'DE',
  'name': 'Germany',
  'emoji': '🇩🇪',
  'capital': 'Berlin',
  'currency': 'EUR',
  'continent': continent,
};

Matcher failsWith(LocationFailure failure) => throwsA(
  isA<LocationRepositoryException>().having(
    (error) => error.failure,
    'failure',
    failure,
  ),
);

void main() {
  late List<Request> requests;
  late Response response;
  late GraphQLLocationRepository repository;
  Object? transportError;

  setUp(() {
    requests = [];
    transportError = null;
    response = const Response(response: {}, data: {});
    final link = Link.function((request, [forward]) async* {
      requests.add(request);
      if (transportError != null) throw transportError!;
      yield response;
    });
    repository = GraphQLLocationRepository(createGraphQLClient(link: link));
    addTearDown(link.dispose);
  });

  test(
    'Maps country fields and nested continent into an immutable list',
    () async {
      response = const Response(
        response: {},
        data: {
          'countries': [country],
        },
      );
      final locations = await repository.fetchCountries();
      final location = locations.single;
      expect(location.code, 'DE');
      expect(location.name, 'Germany');
      expect(location.emoji, '🇩🇪');
      expect(location.capital, 'Berlin');
      expect(location.currency, 'EUR');
      expect(location.continent.code, 'EU');
      expect(location.continent.name, 'Europe');
      expect(() => locations.clear(), throwsUnsupportedError);
      expect(
        requests.single.operation.document,
        gql(LocationQueries.countries),
      );
    },
  );

  test('Maps continents into an immutable list', () async {
    response = const Response(
      response: {},
      data: {
        'continents': [continent],
      },
    );
    final continents = await repository.fetchContinents();
    expect(continents.single.code, 'EU');
    expect(continents.single.name, 'Europe');
    expect(() => continents.clear(), throwsUnsupportedError);
    expect(requests.single.operation.document, gql(LocationQueries.continents));
  });

  test('Empty country and continent lists are successful results', () async {
    response = const Response(
      response: {},
      data: {'countries': [], 'continents': []},
    );
    expect(await repository.fetchCountries(), isEmpty);
    expect(await repository.fetchContinents(), isEmpty);
  });

  test(
    'Detail query passes the normalized country code as a variable',
    () async {
      response = const Response(response: {}, data: {'country': country});
      final location = await repository.fetchCountry(' de ');
      expect(location?.code, 'DE');
      expect(location?.capital, 'Berlin');
      expect(requests.single.variables, {'code': 'DE'});
      expect(requests.single.operation.document, gql(LocationQueries.country));
    },
  );

  test('Nullable capital and currency remain null', () async {
    response = Response(
      response: {},
      data: {
        'country': {...country, 'capital': null, 'currency': null},
      },
    );
    final location = await repository.fetchCountry('DE');
    expect(location, isNotNull);
    expect(location!.capital, isNull);
    expect(location.currency, isNull);
  });

  test('Unknown country returns null', () async {
    response = const Response(response: {}, data: {'country': null});
    expect(await repository.fetchCountry('ZZ'), isNull);
  });

  test('Invalid country code is rejected before transport', () {
    expect(() => repository.fetchCountry(''), throwsArgumentError);
    expect(() => repository.fetchCountry('DEU'), throwsArgumentError);
    expect(requests, isEmpty);
  });

  test('Repeated fetch reaches transport and returns fresh data', () async {
    response = const Response(
      response: {},
      data: {
        'countries': [country],
      },
    );
    expect(await repository.fetchCountries(), hasLength(1));
    response = const Response(response: {}, data: {'countries': []});
    expect(await repository.fetchCountries(), isEmpty);
    expect(requests, hasLength(2));
  });

  test('Transport failure becomes a network failure', () async {
    transportError = Exception('Connection failed');
    await expectLater(
      repository.fetchCountries(),
      failsWith(LocationFailure.network),
    );
  });

  test('GraphQL errors reject even partial data', () async {
    response = const Response(
      response: {},
      data: {
        'countries': [country],
      },
      errors: [GraphQLError(message: 'Internal service details')],
    );
    await expectLater(
      repository.fetchCountries(),
      failsWith(LocationFailure.graphql),
    );
  });

  test('GraphQL errors without data become a GraphQL failure', () async {
    response = const Response(
      response: {},
      errors: [GraphQLError(message: 'Unavailable')],
    );
    await expectLater(
      repository.fetchCountry('DE'),
      failsWith(LocationFailure.graphql),
    );
  });

  test('Missing response data becomes an invalid-response failure', () async {
    response = const Response(response: {});
    await expectLater(
      repository.fetchCountries(),
      failsWith(LocationFailure.invalidResponse),
    );
  });

  test('Missing detail field is not treated as an unknown country', () async {
    await expectLater(
      repository.fetchCountry('DE'),
      failsWith(LocationFailure.invalidResponse),
    );
  });

  for (final invalid in [
    null,
    'invalid',
    [null],
    [
      {'code': 123},
    ],
  ]) {
    test('Malformed country list $invalid is rejected', () async {
      response = Response(response: {}, data: {'countries': invalid});
      await expectLater(
        repository.fetchCountries(),
        failsWith(LocationFailure.invalidResponse),
      );
    });
  }

  test('Malformed nested continent is rejected', () async {
    response = Response(
      response: {},
      data: {
        'country': {
          ...country,
          'continent': {'code': 'EU'},
        },
      },
    );
    await expectLater(
      repository.fetchCountry('DE'),
      failsWith(LocationFailure.invalidResponse),
    );
  });

  test('Malformed continent response is rejected', () async {
    response = const Response(
      response: {},
      data: {
        'continents': [
          {'code': 'EU', 'name': 12},
        ],
      },
    );
    await expectLater(
      repository.fetchContinents(),
      failsWith(LocationFailure.invalidResponse),
    );
  });
}
