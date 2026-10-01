class ContinentModel {
  const ContinentModel({required this.code, required this.name});

  factory ContinentModel.fromJson(Map<String, dynamic> json) {
    return ContinentModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  final String code;
  final String name;
}
