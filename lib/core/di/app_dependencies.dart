import 'package:flutter/material.dart';

import '../../repositories/location_repository.dart';
import '../../repositories/simulated_operations_repository.dart';
import '../graphql/graphql_client.dart';
import '../theme/app_theme.dart';

/// Composition root for dependencies passed through widget and BLoC constructors.
class AppDependencies {
  const AppDependencies({
    required this.theme,
    required this.locationRepository,
    this.simulatedOperationsRepository = const SimulatedOperationsRepository(),
  });

  factory AppDependencies.create() => AppDependencies(
    theme: AppTheme.light(),
    locationRepository: GraphQLLocationRepository(createGraphQLClient()),
  );

  final ThemeData theme;
  final LocationRepository locationRepository;
  final SimulatedOperationsRepository simulatedOperationsRepository;
}
