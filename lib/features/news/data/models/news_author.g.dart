// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_author.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsAuthor _$NewsAuthorFromJson(Map<String, dynamic> json) => NewsAuthor(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  prenoms: json['prenoms'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$NewsAuthorToJson(NewsAuthor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
    };
