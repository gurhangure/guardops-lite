import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardops_lite/app.dart';
import 'package:guardops_lite/core/di/app_dependencies.dart';
import 'package:guardops_lite/core/theme/app_theme.dart';

import 'helpers/fake_location_repository.dart';

AppDependencies testDependencies() => AppDependencies(
  theme: AppTheme.light(),
  locationRepository: FakeLocationRepository(),
);

void main() {
  testWidgets('Dashboard shows its identity and simulation disclaimer', (
    tester,
  ) async {
    final dependencies = testDependencies();
    await tester.pumpWidget(GuardOpsApp(dependencies: dependencies));

    expect(find.text('GuardOps Lite'), findsOneWidget);
    expect(find.text('Operations overview'), findsOneWidget);
    expect(
      find.text('Operational and device data in this demo are simulated.'),
      findsOneWidget,
    );
    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme, dependencies.theme.colorScheme);
  });

  testWidgets('Dashboard fits a small screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(GuardOpsApp(dependencies: testDependencies()));
    await tester.ensureVisible(
      find.text('Operational and device data in this demo are simulated.'),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
