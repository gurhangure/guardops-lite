import 'continent_model.dart';

/// Geographic information from the Countries API, without simulated statistics.
class LocationModel {
  const LocationModel({
    required this.code,
    required this.name,
    required this.emoji,
    required this.continent,
    this.capital,
    this.currency,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      code: json['code'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      continent: ContinentModel.fromJson(
        json['continent'] as Map<String, dynamic>,
      ),
      capital: json['capital'] as String?,
      currency: json['currency'] as String?,
    );
  }

  final String code;
  final String name;
  final String emoji;
  final ContinentModel continent;
  final String? capital;
  final String? currency;
}
