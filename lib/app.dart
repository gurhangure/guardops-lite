import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/app_dependencies.dart';
import 'repositories/location_repository.dart';
import 'viewmodels/location_detail_bloc.dart';
import 'viewmodels/location_detail_event.dart';
import 'views/location_detail_screen.dart';

import 'viewmodels/operations_bloc.dart';
import 'viewmodels/operations_event.dart';
import 'views/locations_screen.dart';
import 'views/dashboard_screen.dart';

class GuardOpsApp extends StatelessWidget {
  const GuardOpsApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuardOps Lite',
      debugShowCheckedModeBanner: false,
      theme: dependencies.theme,
      home: BlocProvider(
        create: (_) => OperationsBloc(
          dependencies.locationRepository,
          simulatedOperationsRepository:
              dependencies.simulatedOperationsRepository,
        )..add(const OperationsLoadRequested()),
        child: _AppShell(repository: dependencies.locationRepository),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.repository});

  final LocationRepository repository;

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(
      onViewLocations: () {
        final bloc = context.read<OperationsBloc>();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: LocationsScreen(
                onLocationSelected: (code) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider(
                        create: (_) =>
                            LocationDetailBloc(repository, countryCode: code)
                              ..add(const LocationDetailLoadRequested()),
                        child: const LocationDetailScreen(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
