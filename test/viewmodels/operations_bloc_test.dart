import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/models/continent_model.dart';
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
  test('queued filter event cannot finish refresh before loading', () async {
    final pending = Completer<List<LocationModel>>();
    repository.loadCountries = () => pending.future;
    final bloc = OperationsBloc(repository);
    addTearDown(bloc.close);
    bloc.add(const OperationsSearchChanged('Japan'));
    var completed = false;
    final refreshing = bloc.refresh().then((_) => completed = true);
    await bloc.stream.firstWhere((state) => state.isLoading);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    pending.complete([japan]);
    await refreshing;
    expect(bloc.state.visibleCountries, [japan]);
  });

  test('refresh completes safely if the BLoC closes during loading', () async {
    final pending = Completer<List<LocationModel>>();
    repository.loadCountries = () => pending.future;
    final bloc = OperationsBloc(repository);
    final refreshing = bloc.refresh();
    await bloc.stream.firstWhere((state) => state.isLoading);
    await bloc.close();
    await refreshing;
    pending.complete([japan]);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.hasLoaded, isFalse);
  });
  test(
    'refresh joins an active load and waits for both repository requests',
    () async {
      final countries = Completer<List<LocationModel>>();
      final continents = Completer<List<ContinentModel>>();
      repository.loadCountries = () => countries.future;
      repository.loadContinents = () => continents.future;
      final bloc = OperationsBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const OperationsLoadRequested());
      await bloc.stream.firstWhere((state) => state.isLoading);
      var completed = false;
      final refreshing = bloc.refresh().then((_) => completed = true);
      bloc.add(const OperationsSearchChanged('Japan'));
      await bloc.stream.firstWhere((state) => state.query == 'Japan');
      countries.complete([germany, japan]);
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(bloc.state.isLoading, isTrue);
      expect(repository.countryCalls, 1);
      expect(repository.continentCalls, 1);
      continents.complete([europe, asia]);
      await refreshing;

      expect(completed, isTrue);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.visibleCountries, [japan]);
      expect(repository.countryCalls, 1);
      expect(repository.continentCalls, 1);
    },
  );

  test(
    'overlapping refresh callers share a load without premature completion',
    () async {
      final countries = Completer<List<LocationModel>>();
      final continents = Completer<List<ContinentModel>>();
      repository.loadCountries = () => countries.future;
      repository.loadContinents = () => continents.future;
      final bloc = OperationsBloc(repository);
      addTearDown(bloc.close);
      final completed = <int>[];

      // Two callers arrive before the load event runs; another joins during loading.
      final first = bloc.refresh().then((_) => completed.add(1));
      final second = bloc.refresh().then((_) => completed.add(2));
      await bloc.stream.firstWhere((state) => state.isLoading);
      final third = bloc.refresh().then((_) => completed.add(3));
      bloc.add(const OperationsContinentChanged('EU'));
      await bloc.stream.firstWhere((state) => state.continentCode == 'EU');
      continents.complete([europe, asia]);
      await Future<void>.delayed(Duration.zero);

      expect(completed, isEmpty);
      expect(bloc.state.isLoading, isTrue);
      expect(repository.countryCalls, 1);
      expect(repository.continentCalls, 1);
      countries.complete([germany, japan]);
      await Future.wait([first, second, third]);
      await Future<void>.delayed(Duration.zero);

      expect(completed, unorderedEquals([1, 2, 3]));
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.hasLoaded, isTrue);
      expect(bloc.state.visibleCountries, [germany]);
      expect(repository.countryCalls, 1);
      expect(repository.continentCalls, 1);
    },
  );
}
