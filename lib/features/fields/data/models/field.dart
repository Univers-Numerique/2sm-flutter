import 'package:json_annotation/json_annotation.dart';

part 'field.g.dart';

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

@JsonSerializable()
class FieldOwnerRef {
  final int id;
  final String? nom;
  final String? prenoms;
  const FieldOwnerRef({required this.id, this.nom, this.prenoms});

  String get fullName => [nom, prenoms].where((s) => s != null && s.isNotEmpty).join(' ');

  factory FieldOwnerRef.fromJson(Map<String, dynamic> json) => _$FieldOwnerRefFromJson(json);
  Map<String, dynamic> toJson() => _$FieldOwnerRefToJson(this);
}

/// Mirrors a `terrains` row. Laravel may serialize decimal columns as
/// strings depending on the model's casts, so [latitude]/[longitude] are
/// parsed defensively from either a number or a numeric string.
@JsonSerializable(explicitToJson: true)
class Field {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int ownerId;
  @JsonKey(name: 'nom_terrain')
  final String nomTerrain;
  final String? lieu;
  @JsonKey(fromJson: _toDouble)
  final double? latitude;
  @JsonKey(fromJson: _toDouble)
  final double? longitude;
  final String? photo;
  @JsonKey(defaultValue: 1)
  final int statut;
  final FieldOwnerRef? owner;
  @JsonKey(name: 'distance_km', fromJson: _toDouble)
  final double? distanceKm;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const Field({
    required this.id,
    required this.ownerId,
    required this.nomTerrain,
    this.lieu,
    this.latitude,
    this.longitude,
    this.photo,
    this.statut = 1,
    this.owner,
    this.distanceKm,
    this.updatedAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  /// `https://maps.google.com/?q=<lat>,<lng>` when coordinates are known,
  /// otherwise a text-query fallback on [lieu]/[nomTerrain].
  String get mapsUrl {
    if (hasCoordinates) return 'https://maps.google.com/?q=$latitude,$longitude';
    final query = Uri.encodeComponent(lieu?.isNotEmpty == true ? lieu! : nomTerrain);
    return 'https://maps.google.com/?q=$query';
  }

  bool isOwnedBy(int userId) => ownerId == userId;

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);
  Map<String, dynamic> toJson() => _$FieldToJson(this);
}
