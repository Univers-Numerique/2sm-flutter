import 'package:json_annotation/json_annotation.dart';

part 'plan.g.dart';

double _priceFromJson(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

/// Mirrors a `plan_abonnements` row (`PlanController`). `prix` is a decimal
/// column, which Laravel may serialize as a numeric string depending on the
/// model's casts, so it's parsed defensively like `Field.latitude`.
@JsonSerializable(explicitToJson: true)
class Plan {
  final int id;
  final String nom;
  @JsonKey(fromJson: _priceFromJson)
  final double prix;
  final String? description;
  final String? image;
  @JsonKey(defaultValue: 1)
  final int statut;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const Plan({
    required this.id,
    required this.nom,
    required this.prix,
    this.description,
    this.image,
    this.statut = 1,
    this.createdAt,
    this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);
  Map<String, dynamic> toJson() => _$PlanToJson(this);
}
