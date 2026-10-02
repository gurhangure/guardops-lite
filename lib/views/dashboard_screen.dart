import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../viewmodels/operations_bloc.dart';
import '../viewmodels/operations_event.dart';
import '../viewmodels/operations_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.onViewLocations, super.key});
  final VoidCallback onViewLocations;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GuardOps Lite')),
    body: SafeArea(
      child: BlocBuilder<OperationsBloc, OperationsState>(
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Operations overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Operational and device data in this demo are simulated.',
                  ),
                  const SizedBox(height: 16),
                  if (state.isLoading)
                    const LinearProgressIndicator(
                      semanticsLabel: 'Loading overview',
                    ),
                  if (state.error != null) ...[
                    Text(
                      state.hasLoaded
                          ? 'Could not refresh. Showing previous overview.'
                          : 'Could not load overview.',
                    ),
                    Text(state.error!),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () => context.read<OperationsBloc>().add(
                                const OperationsLoadRequested(),
                              ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                  if (state.hasLoaded) ...[
                    Text(
                      'Geographic coverage',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Country and continent counts from the Countries API.',
                    ),
                    const SizedBox(height: 12),
                    _MetricGroup(
                      children: [
                        _MetricCard(
                          label: 'Countries',
                          value: state.countryCount,
                          icon: Icons.public,
                        ),
                        _MetricCard(
                          label: 'Continents',
                          value: state.continentCount,
                          icon: Icons.map_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Simulated device status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Text(
                      'Local demo counts. No real infrastructure is connected.',
                    ),
                    const SizedBox(height: 12),
                    _MetricGroup(
                      children: [
                        _MetricCard(
                          label: 'Total devices',
                          value: state.operationalStats.total,
                          icon: Icons.devices,
                        ),
                        _MetricCard(
                          label: 'Online',
                          value: state.operationalStats.online,
                          icon: Icons.check_circle_outline,
                        ),
                        _MetricCard(
                          label: 'Needs attention',
                          value: state.operationalStats.warning,
                          icon: Icons.warning_amber,
                        ),
                        _MetricCard(
                          label: 'Offline',
                          value: state.operationalStats.offline,
                          icon: Icons.cloud_off_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Continent overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Countries by continent, from the live Countries API.',
                    ),
                    const SizedBox(height: 12),
                    if (state.countries.isEmpty)
                      const Text(
                        'No countries available. Open Locations to refresh.',
                      )
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              for (final summary
                                  in state.continentCountryCounts)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: _ContinentRow(
                                    name: summary.name,
                                    count: summary.count,
                                    total: state.countryCount,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.center,
                      child: FilledButton.icon(
                        onPressed: onViewLocations,
                        icon: const Icon(Icons.public),
                        label: const Text('Explore all locations'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MetricGroup extends StatelessWidget {
  const _MetricGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 500
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text('$value', style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}

/// A responsive data row; distribution uses the full API country count.
class _ContinentRow extends StatelessWidget {
  const _ContinentRow({
    required this.name,
    required this.count,
    required this.total,
  });

  final String name;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(name)),
            const SizedBox(width: 12),
            Text('$count', style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
          semanticsLabel: '$name: $count of $total countries',
        ),
      ],
    );
  }
}
