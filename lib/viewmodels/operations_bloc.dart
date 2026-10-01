import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/location_repository.dart';
import '../repositories/simulated_operations_repository.dart';
import 'operations_event.dart';
import 'operations_state.dart';

class OperationsBloc extends Bloc<OperationsEvent, OperationsState> {
  OperationsBloc(
    this._repository, {
    this.simulatedOperationsRepository = const SimulatedOperationsRepository(),
  }) : super(OperationsState()) {
    on<OperationsLoadRequested>(_load);
    on<OperationsSearchChanged>((event, emit) {
      emit(state.copyWith(query: event.query));
    });
    on<OperationsContinentChanged>((event, emit) {
      emit(state.copyWith(continentCode: event.code));
    });
  }

  final LocationRepository _repository;
  final SimulatedOperationsRepository simulatedOperationsRepository;

  /// Lets RefreshIndicator remain visible until the active load finishes.
  Future<void> refresh() async {
    if (isClosed) return;
    var hasStarted = state.isLoading;
    // Ignore queued filter updates before loading; finish safely on disposal.
    final completed = stream
        .where((state) {
          hasStarted = hasStarted || state.isLoading;
          return hasStarted && !state.isLoading;
        })
        .take(1)
        .drain<void>();
    if (!state.isLoading) add(const OperationsLoadRequested());
    await completed;
  }

  Future<void> _load(
    OperationsLoadRequested event,
    Emitter<OperationsState> emit,
  ) async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final (countries, continents) = await (
        _repository.fetchCountries(),
        _repository.fetchContinents(),
      ).wait;
      if (emit.isDone) return;
      final sortedCountries = [...countries]
        ..sort((a, b) => a.name.compareTo(b.name));
      final sortedContinents = [...continents]
        ..sort((a, b) => a.name.compareTo(b.name));
      emit(
        state.copyWith(
          countries: sortedCountries,
          operationalStats: simulatedOperationsRepository.summarize(
            sortedCountries,
          ),
          continents: sortedContinents,
          isLoading: false,
          hasLoaded: true,
          continentCode:
              continents.any((item) => item.code == state.continentCode)
              ? state.continentCode
              : '',
          clearError: true,
        ),
      );
    } catch (error) {
      if (emit.isDone) return;
      // Record.wait wraps failures from either repository call.
      final failure = error is ParallelWaitError
          ? error.errors.$1?.error ?? error.errors.$2?.error
          : error;
      emit(
        state.copyWith(
          isLoading: false,
          error: failure is LocationRepositoryException
              ? failure.message
              : 'Unable to load locations. Please try again.',
        ),
      );
    }
  }
}
