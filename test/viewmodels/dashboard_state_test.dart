import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/repositories/location_repository.dart';
import 'package:guardops_lite/viewmodels/operations_bloc.dart';
import 'package:guardops_lite/viewmodels/operations_event.dart';

import '../helpers/fake_location_repository.dart';
import '../helpers/location_fixtures.dart';

void main() {
  test('dashboard totals ignore filters, survive failure, and update after refresh', () async {
    final repository = FakeLocationRepository()
      ..countries = [germany, japan]
      ..continents = [europe, asia];
    final bloc = OperationsBloc(repository);
    addTearDown(bloc.close);
    await bloc.refresh();
    final total = bloc.state.operationalStats.total;
    expect(bloc.state.countryCount, 2);
    expect(bloc.state.continentCount, 2);
    bloc.add(const OperationsSearchChanged('germany'));
    await bloc.stream.first;
    bloc.add(const OperationsContinentChanged('EU'));
    await bloc.stream.first;
    expect(bloc.state.visibleCountries, hasLength(1));
    expect(bloc.state.countryCount, 2);
    expect(bloc.state.locationPreview, [germany, japan]);
    expect(bloc.state.operationalStats.total, total);
    repository.error = const LocationRepositoryException(
      LocationFailure.network,
    );
    await bloc.refresh();
    expect(bloc.state.operationalStats.total, total);
    repository.error = null;
    repository.countries = [];
    await bloc.refresh();
    expect(bloc.state.operationalStats.total, 0);
    expect(bloc.state.countryCount, 0);
  });
}
