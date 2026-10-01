import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/app.dart';
import 'package:guardops_lite/core/di/app_dependencies.dart';
import 'package:guardops_lite/core/theme/app_theme.dart';
import 'package:guardops_lite/models/location_model.dart';

import '../helpers/fake_location_repository.dart';
import '../helpers/location_fixtures.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('three-screen flow at $size with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        const country = LocationModel(
          code: 'GB',
          name: 'United Kingdom of Great Britain and Northern Ireland',
          emoji: '🇬🇧',
          continent: europe,
          capital: 'London',
          currency: 'GBP',
        );
        final repository = FakeLocationRepository()
          ..countries = [country]
          ..continents = [europe]
          ..detail = country;
        await tester.pumpWidget(
          GuardOpsApp(
            dependencies: AppDependencies(
              theme: AppTheme.light(),
              locationRepository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Locations summary'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('View locations'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('View locations'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'United');
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('GB')),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const ValueKey('GB')));
        await tester.pumpAndSettle();
        // A long row can exceed the viewport; tap its visible portion.
        final visibleRow = tester
            .getRect(find.byKey(const ValueKey('GB')))
            .intersect(tester.getRect(find.byType(CustomScrollView)));
        expect(visibleRow.height, greaterThan(0));
        await tester.tapAt(visibleRow.center);
        await tester.pumpAndSettle();
        expect(find.text('Location details'), findsOneWidget);
        expect(tester.testTextInput.isVisible, isFalse);
        await tester.ensureVisible(find.text('GBP'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(repository.detailCodes, ['GB']);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Locations'), findsOneWidget);
      });
    }
  }
}
