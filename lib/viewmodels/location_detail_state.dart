import '../models/location_model.dart';

sealed class LocationDetailState {
  const LocationDetailState();
}

class LocationDetailInitial extends LocationDetailState {
  const LocationDetailInitial();
}

class LocationDetailLoading extends LocationDetailState {
  const LocationDetailLoading();
}

class LocationDetailLoaded extends LocationDetailState {
  const LocationDetailLoaded(this.location);
  final LocationModel location;
}

class LocationDetailNotFound extends LocationDetailState {
  const LocationDetailNotFound();
}

class LocationDetailFailure extends LocationDetailState {
  const LocationDetailFailure(this.message);
  final String message;
}
