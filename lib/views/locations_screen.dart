import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../viewmodels/operations_bloc.dart';
import '../viewmodels/operations_event.dart';
import '../viewmodels/operations_state.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({required this.onLocationSelected, super.key});

  final ValueChanged<String> onLocationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: SafeArea(
        child: BlocBuilder<OperationsBloc, OperationsState>(
          builder: (context, state) {
            final bloc = context.read<OperationsBloc>();
            final locations = state.visibleCountries;
            return RefreshIndicator(
              onRefresh: bloc.refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.list(
                      children: [
                        const Text(
                          'Country information from the Countries API.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: state.query,
                          decoration: const InputDecoration(
                            labelText: 'Search countries',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) =>
                              bloc.add(OperationsSearchChanged(value)),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(state.continentCode),
                          initialValue: state.continentCode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Continent',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All continents'),
                            ),
                            ...state.continents.map(
                              (continent) => DropdownMenuItem(
                                value: continent.code,
                                child: Text(continent.name),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              bloc.add(OperationsContinentChanged(value ?? '')),
                        ),
                        const SizedBox(height: 16),
                        if (state.isLoading)
                          const LinearProgressIndicator(
                            semanticsLabel: 'Loading locations',
                          ),
                        if (state.error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            state.hasLoaded
                                ? 'Could not refresh. Showing previous results.'
                                : 'Could not load locations.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(state.error!),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: state.isLoading
                                  ? null
                                  : () => bloc.add(
                                      const OperationsLoadRequested(),
                                    ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ),
                        ],
                        if (state.hasLoaded)
                          Text('${locations.length} countries'),
                      ],
                    ),
                  ),
                  if (state.hasLoaded && locations.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.countries.isEmpty
                              ? 'No countries available. Pull down to refresh.'
                              : 'No countries match your search and continent filter.',
                        ),
                      ),
                    ),
                  SliverList.builder(
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      final country = locations[index];
                      return ListTile(
                        key: ValueKey(country.code),
                        onTap: () => onLocationSelected(country.code),
                        leading: ExcludeSemantics(
                          child: Text(
                            country.emoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        title: Text(country.name),
                        subtitle: Text(country.continent.name),
                        trailing: Text(country.code),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
