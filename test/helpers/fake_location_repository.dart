import 'package:guardops_lite/models/continent_model.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/repositories/location_repository.dart';

class FakeLocationRepository implements LocationRepository {
  List<LocationModel> countries = [];
  List<ContinentModel> continents = [];
  Object? error;
  Future<List<LocationModel>> Function()? loadCountries;
  int countryCalls = 0;
  int continentCalls = 0;
  Future<List<ContinentModel>> Function()? loadContinents;
  LocationModel? detail;
  Object? detailError;
  Future<LocationModel?> Function(String)? loadDetail;
  final List<String> detailCodes = [];

  @override
  Future<List<LocationModel>> fetchCountries() async {
    countryCalls++;
    if (error != null) throw error!;
    return loadCountries == null ? countries : await loadCountries!();
  }

  @override
  Future<List<ContinentModel>> fetchContinents() async {
    continentCalls++;
    if (error != null) throw error!;
    return loadContinents == null ? continents : await loadContinents!();
  }

  @override
  Future<LocationModel?> fetchCountry(String code) async {
    detailCodes.add(code);
    if (detailError != null) throw detailError!;
    return loadDetail == null ? detail : await loadDetail!(code);
  }
}
