import '../models/continent_model.dart';
import '../models/location_model.dart';
import '../models/operational_stats.dart';

/// API-derived number of countries within a continent.
class ContinentCountryCount {
  const ContinentCountryCount({
    required this.code,
    required this.name,
    required this.count,
  });

  final String code;
  final String name;
  final int count;
}

class OperationsState {
  OperationsState({
    List<LocationModel> countries = const [],
    List<ContinentModel> continents = const [],
    this.isLoading = false,
    this.hasLoaded = false,
    this.query = '',
    this.continentCode = '',
    this.error,
    this.operationalStats = const OperationalStats(),
  }) : countries = List.unmodifiable(countries),
       continents = List.unmodifiable(continents);

  final List<LocationModel> countries;
  final List<ContinentModel> continents;
  final bool isLoading;
  final bool hasLoaded;
  final String query;
  final String continentCode;
  final String? error;
  final OperationalStats operationalStats;
  int get countryCount => countries.length;
  int get continentCount => continents.length;

  /// Uses the complete API dataset, independent of the Locations search/filter.
  /// Includes continents with zero countries when returned by the API.
  List<ContinentCountryCount> get continentCountryCounts {
    final totals = <String, int>{};
    for (final country in countries) {
      totals.update(
        country.continent.code,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return List.unmodifiable([
      for (final continent in continents)
        ContinentCountryCount(
          code: continent.code,
          name: continent.name,
          count: totals[continent.code] ?? 0,
        ),
    ]);
  }

  List<LocationModel> get visibleCountries {
    final search = query.trim().toLowerCase();
    return List.unmodifiable(
      countries.where(
        (country) =>
            country.name.toLowerCase().contains(search) &&
            (continentCode.isEmpty || country.continent.code == continentCode),
      ),
    );
  }

  OperationsState copyWith({
    List<LocationModel>? countries,
    List<ContinentModel>? continents,
    bool? isLoading,
    bool? hasLoaded,
    String? query,
    String? continentCode,
    String? error,
    bool clearError = false,
    OperationalStats? operationalStats,
  }) => OperationsState(
    countries: countries ?? this.countries,
    continents: continents ?? this.continents,
    isLoading: isLoading ?? this.isLoading,
    hasLoaded: hasLoaded ?? this.hasLoaded,
    query: query ?? this.query,
    continentCode: continentCode ?? this.continentCode,
    error: clearError ? null : error ?? this.error,
    operationalStats: operationalStats ?? this.operationalStats,
  );
}
