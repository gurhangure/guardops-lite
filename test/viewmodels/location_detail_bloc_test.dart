import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/repositories/location_repository.dart';
import 'package:guardops_lite/viewmodels/location_detail_bloc.dart';
import 'package:guardops_lite/viewmodels/location_detail_event.dart';
import 'package:guardops_lite/viewmodels/location_detail_state.dart';

import '../helpers/fake_location_repository.dart';
import '../helpers/location_fixtures.dart';

void main() {
  late FakeLocationRepository repository;
  setUp(() => repository = FakeLocationRepository()..detail = germany);

  blocTest<LocationDetailBloc, LocationDetailState>(
    'loads selected country using its code',
    build: () => LocationDetailBloc(repository, countryCode: 'DE'),
    act: (bloc) => bloc.add(const LocationDetailLoadRequested()),
    expect: () => [
      isA<LocationDetailLoading>(),
      isA<LocationDetailLoaded>().having(
        (s) => s.location,
        'location',
        germany,
      ),
    ],
    verify: (_) => expect(repository.detailCodes, ['DE']),
  );

  blocTest<LocationDetailBloc, LocationDetailState>(
    'null country becomes not found',
    setUp: () => repository.detail = null,
    build: () => LocationDetailBloc(repository, countryCode: 'ZZ'),
    act: (bloc) => bloc.add(const LocationDetailLoadRequested()),
    expect: () => [isA<LocationDetailLoading>(), isA<LocationDetailNotFound>()],
  );

  for (final failure in LocationFailure.values) {
    blocTest<LocationDetailBloc, LocationDetailState>(
      'handles $failure',
      setUp: () =>
          repository.detailError = LocationRepositoryException(failure),
      build: () => LocationDetailBloc(repository, countryCode: 'DE'),
      act: (bloc) => bloc.add(const LocationDetailLoadRequested()),
      expect: () => [
        isA<LocationDetailLoading>(),
        isA<LocationDetailFailure>().having(
          (s) => s.message,
          'message',
          LocationRepositoryException(failure).message,
        ),
      ],
    );
  }

  blocTest<LocationDetailBloc, LocationDetailState>(
    'unexpected errors use a safe message',
    setUp: () => repository.detailError = StateError('internal details'),
    build: () => LocationDetailBloc(repository, countryCode: 'DE'),
    act: (bloc) => bloc.add(const LocationDetailLoadRequested()),
    expect: () => [
      isA<LocationDetailLoading>(),
      isA<LocationDetailFailure>().having(
        (s) => s.message,
        'message',
        'Unable to load this country. Please try again.',
      ),
    ],
  );

  test('retry requests the same code and recovers', () async {
    repository.detailError = const LocationRepositoryException(
      LocationFailure.network,
    );
    final bloc = LocationDetailBloc(repository, countryCode: 'DE');
    addTearDown(bloc.close);
    bloc.add(const LocationDetailLoadRequested());
    await bloc.stream.firstWhere((s) => s is LocationDetailFailure);
    repository.detailError = null;
    bloc.add(const LocationDetailLoadRequested());
    await bloc.stream.firstWhere((s) => s is LocationDetailLoaded);
    expect(repository.detailCodes, ['DE', 'DE']);
  });

  test(
    'duplicate loads are ignored and closing during a request is safe',
    () async {
      final pending = Completer<LocationModel?>();
      repository.loadDetail = (_) => pending.future;
      final bloc = LocationDetailBloc(repository, countryCode: 'DE');
      final states = <LocationDetailState>[];
      final subscription = bloc.stream.listen(states.add);
      bloc.add(const LocationDetailLoadRequested());
      await bloc.stream.firstWhere((s) => s is LocationDetailLoading);
      bloc.add(const LocationDetailLoadRequested());
      await Future<void>.delayed(Duration.zero);
      expect(repository.detailCodes, ['DE']);
      await bloc.close();
      pending.complete(germany);
      await Future<void>.delayed(Duration.zero);
      expect(states.whereType<LocationDetailLoaded>(), isEmpty);
      await subscription.cancel();
    },
  );
}
