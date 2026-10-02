// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'competition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CompetitionOwnerRef _$CompetitionOwnerRefFromJson(Map<String, dynamic> json) =>
    CompetitionOwnerRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$CompetitionOwnerRefToJson(
  CompetitionOwnerRef instance,
) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'prenoms': instance.prenoms,
  'avatar': instance.avatar,
};

CompetitionTeamRef _$CompetitionTeamRefFromJson(Map<String, dynamic> json) =>
    CompetitionTeamRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      logo: json['logo'] as String?,
    );

Map<String, dynamic> _$CompetitionTeamRefToJson(CompetitionTeamRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'logo': instance.logo,
    };

Competition _$CompetitionFromJson(Map<String, dynamic> json) => Competition(
  id: (json['id'] as num).toInt(),
  ownerId: (json['id_utilisateur'] as num).toInt(),
  nom: json['nom'] as String,
  description: json['description'] as String?,
  categorie: json['categorie'] as String?,
  genre: json['genre'] as String?,
  dateDebut: json['date_debut'] as String?,
  heureDebut: json['heure_debut'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 0,
  selection: (json['selection'] as num?)?.toInt() ?? 0,
  saison: json['saison'] as String?,
  photo: json['photo'] as String?,
  owner: json['owner'] == null
      ? null
      : CompetitionOwnerRef.fromJson(json['owner'] as Map<String, dynamic>),
  teamsOrNull: (json['teams'] as List<dynamic>?)
      ?.map((e) => CompetitionTeamRef.fromJson(e as Map<String, dynamic>))
      .toList(),
  matchesOrNull: (json['matches'] as List<dynamic>?)
      ?.map((e) => MatchGame.fromJson(e as Map<String, dynamic>))
      .toList(),
  matchesCount: (json['matches_count'] as num?)?.toInt(),
  finishedMatchesCount: (json['finished_matches_count'] as num?)?.toInt(),
  fieldsOrNull: (json['fields'] as List<dynamic>?)
      ?.map((e) => MatchFieldRef.fromJson(e as Map<String, dynamic>))
      .toList(),
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$CompetitionToJson(Competition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_utilisateur': instance.ownerId,
      'nom': instance.nom,
      'description': instance.description,
      'categorie': instance.categorie,
      'genre': instance.genre,
      'date_debut': instance.dateDebut,
      'heure_debut': instance.heureDebut,
      'statut': instance.statut,
      'selection': instance.selection,
      'saison': instance.saison,
      'photo': instance.photo,
      'owner': instance.owner?.toJson(),
      'teams': instance.teamsOrNull?.map((e) => e.toJson()).toList(),
      'matches': instance.matchesOrNull?.map((e) => e.toJson()).toList(),
      'matches_count': instance.matchesCount,
      'finished_matches_count': instance.finishedMatchesCount,
      'fields': instance.fieldsOrNull?.map((e) => e.toJson()).toList(),
      'updated_at': instance.updatedAt,
    };
