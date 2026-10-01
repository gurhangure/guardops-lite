import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/repositories/location_repository.dart';
import 'package:guardops_lite/viewmodels/operations_bloc.dart';
import 'package:guardops_lite/viewmodels/operations_event.dart';
import 'package:guardops_lite/viewmodels/operations_state.dart';

import '../helpers/fake_location_repository.dart';
import '../helpers/location_fixtures.dart';

void main() {
  late FakeLocationRepository repository;
  setUp(() {
    repository = FakeLocationRepository()
      ..countries = [japan, germany]
      ..continents = [europe, asia];
  });

  blocTest<OperationsBloc, OperationsState>(
    'loads and sorts countries and continents',
    build: () => OperationsBloc(repository),
    act: (bloc) => bloc.add(const OperationsLoadRequested()),
    expect: () => [
      isA<OperationsState>().having((s) => s.isLoading, 'loading', true),
      isA<OperationsState>()
          .having((s) => s.hasLoaded, 'loaded', true)
          .having((s) => s.countries.map((c) => c.code), 'countries', [
            'DE',
            'JP',
          ])
          .having((s) => s.continents.map((c) => c.code), 'continents', [
            'AS',
            'EU',
          ]),
    ],
  );

  test(
    'search is trimmed and case insensitive and combines with continent',
    () async {
      final bloc = OperationsBloc(repository);
      addTearDown(bloc.close);
      await bloc.refresh();
      bloc.add(const OperationsSearchChanged('  GER '));
      await bloc.stream.first;
      expect(bloc.state.visibleCountries, [germany]);
      expect(bloc.state.countries, hasLength(2));
      bloc.add(const OperationsContinentChanged('AS'));
      await bloc.stream.first;
      expect(bloc.state.visibleCountries, isEmpty);
      bloc.add(const OperationsSearchChanged(''));
      await bloc.stream.first;
      expect(bloc.state.visibleCountries, [japan]);
      expect(repository.countryCalls, 1);
      expect(() => bloc.state.countries.clear(), throwsUnsupportedError);
    },
  );

  test('refresh failure retains content and filters; retry recovers', () async {
    final bloc = OperationsBloc(repository);
    addTearDown(bloc.close);
    await bloc.refresh();
    bloc.add(const OperationsContinentChanged('EU'));
    await bloc.stream.first;
    bloc.add(const OperationsSearchChanged('ger'));
    await bloc.stream.first;
    repository.error = const LocationRepositoryException(
      LocationFailure.network,
    );
    await bloc.refresh();
    expect(bloc.state.hasLoaded, isTrue);
    expect(bloc.state.visibleCountries, [germany]);
    expect(bloc.state.query, 'ger');
    expect(bloc.state.continentCode, 'EU');
    expect(bloc.state.error, contains('connection'));
    repository.error = null;
    await bloc.refresh();
    expect(bloc.state.error, isNull);
    expect(bloc.state.visibleCountries, [germany]);
  });

  test('initial failure and retry to an empty result', () async {
    repository.error = const LocationRepositoryException(
      LocationFailure.graphql,
    );
    final bloc = OperationsBloc(repository);
    addTearDown(bloc.close);
    await bloc.refresh();
    expect(bloc.state.hasLoaded, isFalse);
    expect(bloc.state.isLoading, isFalse);
    expect(bloc.state.error, isNotNull);
    repository.error = null;
    repository.countries = [];
    await bloc.refresh();
    expect(bloc.state.hasLoaded, isTrue);
    expect(bloc.state.visibleCountries, isEmpty);
  });

  test(
    'overlapping loads are ignored and filter edits during load survive',
    () async {
      final pending = Completer<List<LocationModel>>();
      repository.loadCountries = () => pending.future;
      final bloc = OperationsBloc(repository);
      addTearDown(bloc.close);
      final finished = bloc.refresh();
      await bloc.stream.firstWhere((s) => s.isLoading);
      bloc.add(const OperationsLoadRequested());
      bloc.add(const OperationsSearchChanged('Japan'));
      await bloc.stream.firstWhere((s) => s.query == 'Japan');
      pending.complete([germany, japan]);
      await finished;
      expect(repository.countryCalls, 1);
      expect(bloc.state.visibleCountries, [japan]);
    },
  );

  test('removed continent selection resets after refresh', () async {
    final bloc = OperationsBloc(repository);
    addTearDown(bloc.close);
    await bloc.refresh();
    bloc.add(const OperationsContinentChanged('EU'));
    await bloc.stream.first;
    repository.continents = [asia];
    await bloc.refresh();
    expect(bloc.state.continentCode, '');
  });
}
