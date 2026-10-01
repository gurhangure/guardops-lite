import 'package:graphql_flutter/graphql_flutter.dart';

import '../core/graphql/location_queries.dart';
import '../models/continent_model.dart';
import '../models/location_model.dart';

abstract interface class LocationRepository {
  Future<List<LocationModel>> fetchCountries();
  Future<List<ContinentModel>> fetchContinents();

  /// Returns null when the API has no country for [code].
  Future<LocationModel?> fetchCountry(String code);
}

enum LocationFailure { network, graphql, invalidResponse }

class LocationRepositoryException implements Exception {
  const LocationRepositoryException(this.failure);

  final LocationFailure failure;

  String get message => switch (failure) {
    LocationFailure.network =>
      'Unable to connect. Check your connection and try again.',
    LocationFailure.graphql => 'Unable to load locations. Please try again.',
    LocationFailure.invalidResponse =>
      'The location service returned an unexpected response.',
  };

  @override
  String toString() => 'LocationRepositoryException: $message';
}

class GraphQLLocationRepository implements LocationRepository {
  GraphQLLocationRepository(this._client);

  final GraphQLClient _client;

  @override
  Future<List<LocationModel>> fetchCountries() => _fetch(
    LocationQueries.countries,
    (data) => List<LocationModel>.unmodifiable(
      (data['countries'] as List<dynamic>).map(
        (item) => LocationModel.fromJson(item as Map<String, dynamic>),
      ),
    ),
  );

  @override
  Future<List<ContinentModel>> fetchContinents() => _fetch(
    LocationQueries.continents,
    (data) => List<ContinentModel>.unmodifiable(
      (data['continents'] as List<dynamic>).map(
        (item) => ContinentModel.fromJson(item as Map<String, dynamic>),
      ),
    ),
  );

  @override
  Future<LocationModel?> fetchCountry(String code) {
    final normalizedCode = code.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalizedCode)) {
      throw ArgumentError.value(
        code,
        'code',
        'Expected a two-letter country code',
      );
    }
    return _fetch(LocationQueries.country, (data) {
      if (!data.containsKey('country')) {
        throw const FormatException('Missing country field');
      }
      final country = data['country'];
      return country == null
          ? null
          : LocationModel.fromJson(country as Map<String, dynamic>);
    }, variables: {'code': normalizedCode});
  }

  Future<T> _fetch<T>(
    String document,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic> variables = const {},
  }) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(document),
        variables: variables,
        // Every explicit load/refresh reaches the service. No persistent cache.
        fetchPolicy: FetchPolicy.noCache,
        errorPolicy: ErrorPolicy.all,
      ),
    );
    final exception = result.exception;
    if (exception != null) {
      throw LocationRepositoryException(
        exception.linkException != null
            ? LocationFailure.network
            : LocationFailure.graphql,
      );
    }
    final data = result.data;
    if (data == null) {
      throw const LocationRepositoryException(LocationFailure.invalidResponse);
    }
    try {
      return parse(data);
    } on TypeError {
      throw const LocationRepositoryException(LocationFailure.invalidResponse);
    } on FormatException {
      throw const LocationRepositoryException(LocationFailure.invalidResponse);
    }
  }
}
