import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/location_repository.dart';
import 'location_detail_event.dart';
import 'location_detail_state.dart';

class LocationDetailBloc
    extends Bloc<LocationDetailEvent, LocationDetailState> {
  LocationDetailBloc(this._repository, {required this.countryCode})
    : super(const LocationDetailInitial()) {
    on<LocationDetailLoadRequested>(_load);
  }

  final LocationRepository _repository;
  final String countryCode;

  Future<void> _load(
    LocationDetailLoadRequested event,
    Emitter<LocationDetailState> emit,
  ) async {
    if (state is LocationDetailLoading) return;
    emit(const LocationDetailLoading());
    try {
      final location = await _repository.fetchCountry(countryCode);
      if (emit.isDone) return;
      emit(
        location == null
            ? const LocationDetailNotFound()
            : LocationDetailLoaded(location),
      );
    } on LocationRepositoryException catch (error) {
      if (!emit.isDone) emit(LocationDetailFailure(error.message));
    } catch (_) {
      if (!emit.isDone) {
        emit(
          const LocationDetailFailure(
            'Unable to load this country. Please try again.',
          ),
        );
      }
    }
  }
}
