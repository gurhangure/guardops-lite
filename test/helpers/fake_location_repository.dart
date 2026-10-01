import 'package:guardops_lite/models/continent_model.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/repositories/location_repository.dart';

class FakeLocationRepository implements LocationRepository {
  List<LocationModel> countries = [];
  List<ContinentModel> continents = [];
  Object? error;
  Future<List<LocationModel>> Function()? loadCountries;
  int countryCalls = 0;

  @override
  Future<List<LocationModel>> fetchCountries() async {
    countryCalls++;
    if (error != null) throw error!;
    return loadCountries == null ? countries : await loadCountries!();
  }

  @override
  Future<List<ContinentModel>> fetchContinents() async {
    if (error != null) throw error!;
    return continents;
  }

  @override
  Future<LocationModel?> fetchCountry(String code) async => null;
}
