import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/app.dart';
import 'package:guardops_lite/core/di/app_dependencies.dart';
import 'package:guardops_lite/core/theme/app_theme.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/repositories/location_repository.dart';

import '../helpers/fake_location_repository.dart';
import '../helpers/location_fixtures.dart';

void main() {
  late FakeLocationRepository repository;
  setUp(
    () => repository = FakeLocationRepository()
      ..countries = [germany, japan]
      ..continents = [europe, asia],
  );
  Future<void> show(WidgetTester tester) => tester.pumpWidget(
    GuardOpsApp(
      dependencies: AppDependencies(
        theme: AppTheme.light(),
        locationRepository: repository,
      ),
    ),
  );
  testWidgets('loading then summary clearly separates API and simulated data', (
    tester,
  ) async {
    final pending = Completer<List<LocationModel>>();
    repository.loadCountries = () => pending.future;
    await show(tester);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Total devices'), findsNothing);
    pending.complete([germany, japan]);
    await tester.pumpAndSettle();
    expect(find.text('Countries'), findsOneWidget);
    expect(find.text('Simulated device status'), findsOneWidget);
    expect(
      find.text('Local demo counts. No real infrastructure is connected.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Continent overview'));
    await tester.pumpAndSettle();
    expect(find.text('Europe'), findsOneWidget);
    expect(find.text('Asia'), findsOneWidget);
    expect(find.text('Explore all locations'), findsOneWidget);
    expect(find.text('Germany'), findsNothing);
    expect(find.text('Japan'), findsNothing);
  });
  testWidgets('failure offers retry and empty success shows zero devices', (
    tester,
  ) async {
    repository.error = const LocationRepositoryException(
      LocationFailure.network,
    );
    await show(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not load overview.'), findsOneWidget);
    repository.error = null;
    repository.countries = [];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load overview.'), findsNothing);
    expect(
      find.text('No countries available. Open Locations to refresh.'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNWidgets(5));
  });
  testWidgets(
    'loaded dashboard fits small screens and large text and opens locations',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await show(tester);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continent overview'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Explore all locations'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Explore all locations'));
      await tester.pumpAndSettle();
      expect(find.text('Locations'), findsOneWidget);
      expect(repository.countryCalls, 1);
    },
  );
}
