import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/location_model.dart';
import '../viewmodels/location_detail_bloc.dart';
import '../viewmodels/location_detail_event.dart';
import '../viewmodels/location_detail_state.dart';

class LocationDetailScreen extends StatelessWidget {
  const LocationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location details')),
      body: SafeArea(
        child: BlocBuilder<LocationDetailBloc, LocationDetailState>(
          builder: (context, state) => switch (state) {
            LocationDetailInitial() || LocationDetailLoading() => const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading country details',
              ),
            ),
            LocationDetailLoaded(:final location) => _CountryDetails(
              location: location,
            ),
            LocationDetailNotFound() => const _DetailMessage(
              title: 'Country not found',
              message:
                  'This country is no longer available from the Countries API.',
            ),
            LocationDetailFailure(:final message) => _DetailMessage(
              title: 'Could not load country',
              message: message,
            ),
          },
        ),
      ),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<LocationDetailBloc>().add(
                const LocationDetailLoadRequested(),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryDetails extends StatelessWidget {
  const _CountryDetails({required this.location});
  final LocationModel location;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Text(
                  location.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                location.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CountryField(
                        label: 'Country code',
                        value: location.code,
                      ),
                      _CountryField(
                        label: 'Continent',
                        value: location.continent.name,
                      ),
                      _CountryField(label: 'Capital', value: location.capital),
                      _CountryField(
                        label: 'Currency',
                        value: location.currency,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Geographic information provided by the Countries API.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          value == null || value!.trim().isEmpty ? 'Not available' : value!,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}
