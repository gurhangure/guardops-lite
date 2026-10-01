import 'package:flutter/material.dart';

import 'core/di/app_dependencies.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'viewmodels/operations_bloc.dart';
import 'viewmodels/operations_event.dart';
import 'views/locations_screen.dart';

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
        create: (_) =>
            OperationsBloc(dependencies.locationRepository)
              ..add(const OperationsLoadRequested()),
        child: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('GuardOps Lite')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.public,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to GuardOps Lite',
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A mobile operations portfolio demo.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      final bloc = context.read<OperationsBloc>();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider.value(
                            value: bloc,
                            child: const LocationsScreen(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.public),
                    label: const Text('View locations'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Operational and device data in this demo are simulated.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
