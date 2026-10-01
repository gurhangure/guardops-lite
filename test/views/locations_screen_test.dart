import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/models/location_model.dart';
import 'package:guardops_lite/repositories/location_repository.dart';
import 'package:guardops_lite/viewmodels/operations_bloc.dart';
import 'package:guardops_lite/viewmodels/operations_event.dart';
import 'package:guardops_lite/views/locations_screen.dart';

import '../helpers/fake_location_repository.dart';
import '../helpers/location_fixtures.dart';

void main() {
  late FakeLocationRepository repository;
  setUp(() {
    repository = FakeLocationRepository()
      ..countries = [germany, japan]
      ..continents = [europe, asia];
  });
  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) =>
              OperationsBloc(repository)..add(const OperationsLoadRequested()),
          child: LocationsScreen(onLocationSelected: (_) {}),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows loading then countries, search and continent filtering', (
    tester,
  ) async {
    final pending = Completer<List<LocationModel>>();
    repository.loadCountries = () => pending.future;
    await show(tester);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pending.complete([germany, japan]);
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'GER');
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Japan'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asia').last);
    await tester.pumpAndSettle();
    expect(
      find.text('No countries match your search and continent filter.'),
      findsOneWidget,
    );
  });
  testWidgets('initial error offers retry and recovers', (tester) async {
    repository.error = const LocationRepositoryException(
      LocationFailure.network,
    );
    await show(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not load locations.'), findsOneWidget);
    repository.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
  testWidgets('pull to refresh retains results on failure', (tester) async {
    await show(tester);
    await tester.pumpAndSettle();
    repository.error = const LocationRepositoryException(
      LocationFailure.network,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(repository.countryCalls, 2);
    expect(
      find.text('Could not refresh. Showing previous results.'),
      findsOneWidget,
    );
    expect(find.text('Germany'), findsOneWidget);
  });
  testWidgets('empty result is refreshable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    repository.countries = [];
    await show(tester);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(
      find.text('No countries available. Pull down to refresh.'),
      findsOneWidget,
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
