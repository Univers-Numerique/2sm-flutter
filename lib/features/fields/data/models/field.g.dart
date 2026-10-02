// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldOwnerRef _$FieldOwnerRefFromJson(Map<String, dynamic> json) =>
    FieldOwnerRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
    );

Map<String, dynamic> _$FieldOwnerRefToJson(FieldOwnerRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
    };

Field _$FieldFromJson(Map<String, dynamic> json) => Field(
  id: (json['id'] as num).toInt(),
  ownerId: (json['id_utilisateur'] as num).toInt(),
  nomTerrain: json['nom_terrain'] as String,
  lieu: json['lieu'] as String?,
  latitude: _toDouble(json['latitude']),
  longitude: _toDouble(json['longitude']),
  photo: json['photo'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  owner: json['owner'] == null
      ? null
      : FieldOwnerRef.fromJson(json['owner'] as Map<String, dynamic>),
  distanceKm: _toDouble(json['distance_km']),
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$FieldToJson(Field instance) => <String, dynamic>{
  'id': instance.id,
  'id_utilisateur': instance.ownerId,
  'nom_terrain': instance.nomTerrain,
  'lieu': instance.lieu,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'photo': instance.photo,
  'statut': instance.statut,
  'owner': instance.owner?.toJson(),
  'distance_km': instance.distanceKm,
  'updated_at': instance.updatedAt,
};
