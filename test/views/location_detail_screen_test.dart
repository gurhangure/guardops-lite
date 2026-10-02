import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/app.dart';
import 'package:guardops_lite/core/di/app_dependencies.dart';
import 'package:guardops_lite/core/theme/app_theme.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/repositories/location_repository.dart';
import 'package:guardops_lite/viewmodels/location_detail_bloc.dart';
import 'package:guardops_lite/viewmodels/location_detail_event.dart';
import 'package:guardops_lite/views/location_detail_screen.dart';

import '../helpers/fake_location_repository.dart';
import '../helpers/location_fixtures.dart';

const detail = LocationModel(
  code: 'DE',
  name: 'Germany',
  emoji: '🇩🇪',
  continent: europe,
  capital: 'Berlin',
  currency: 'EUR',
);

void main() {
  late FakeLocationRepository repository;
  setUp(() => repository = FakeLocationRepository()..detail = detail);
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              LocationDetailBloc(repository, countryCode: 'DE')
                ..add(const LocationDetailLoadRequested()),
          child: const LocationDetailScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('loading transitions to fetched geographic information', (
    tester,
  ) async {
    final pending = Completer<LocationModel?>();
    repository.loadDetail = (_) => pending.future;
    await show(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(detail);
    await tester.pumpAndSettle();
    for (final value in ['Germany', 'DE', 'Europe', 'Berlin', 'EUR']) {
      expect(find.text(value), findsOneWidget);
    }
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error retry loads the same country', (tester) async {
    repository.detailError = const LocationRepositoryException(
      LocationFailure.network,
    );
    await show(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not load country'), findsOneWidget);
    repository.detailError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);
    expect(repository.detailCodes, ['DE', 'DE']);
  });

  testWidgets('missing country offers retry', (tester) async {
    repository.detail = null;
    await show(tester);
    await tester.pumpAndSettle();
    expect(find.text('Country not found'), findsOneWidget);
    repository.detail = detail;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);
  });

  testWidgets('nullable fields and large text fit a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    repository.detail = germany;
    await show(tester);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(find.text('Not available'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'list navigation fetches detail and back preserves search and filter',
    (tester) async {
      repository.countries = [germany, japan];
      repository.continents = [europe, asia];
      await tester.pumpWidget(
        GuardOpsApp(
          dependencies: AppDependencies(
            theme: AppTheme.light(),
            locationRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore all locations'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore all locations'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ger');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Europe').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();
      expect(repository.detailCodes, ['DE']);
      expect(find.text('Berlin'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Locations'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ger',
      );
      expect(find.text('Germany'), findsOneWidget);
      expect(find.text('Japan'), findsNothing);
      expect(repository.countryCalls, 1);
      // A second route owns a fresh detail BLoC and issues its own query.
      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();
      expect(repository.detailCodes, ['DE', 'DE']);
    },
  );
}
