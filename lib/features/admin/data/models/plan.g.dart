// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String,
  prix: _priceFromJson(json['prix']),
  description: json['description'] as String?,
  image: json['image'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'prix': instance.prix,
  'description': instance.description,
  'image': instance.image,
  'statut': instance.statut,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
