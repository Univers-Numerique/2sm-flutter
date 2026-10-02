// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityUserRef _$ActivityUserRefFromJson(Map<String, dynamic> json) =>
    ActivityUserRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$ActivityUserRefToJson(ActivityUserRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
    };

ActivityTeamRef _$ActivityTeamRefFromJson(Map<String, dynamic> json) =>
    ActivityTeamRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
      logo: json['logo'] as String?,
    );

Map<String, dynamic> _$ActivityTeamRefToJson(ActivityTeamRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'logo': instance.logo,
    };

ActivityParticipantPivot _$ActivityParticipantPivotFromJson(
  Map<String, dynamic> json,
) => ActivityParticipantPivot(
  activityId: (json['id_activite'] as num).toInt(),
  userId: (json['id_utilisateur'] as num).toInt(),
  statut: (json['statut'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ActivityParticipantPivotToJson(
  ActivityParticipantPivot instance,
) => <String, dynamic>{
  'id_activite': instance.activityId,
  'id_utilisateur': instance.userId,
  'statut': instance.statut,
};

ActivityParticipant _$ActivityParticipantFromJson(Map<String, dynamic> json) =>
    ActivityParticipant(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
      pivot: json['pivot'] == null
          ? null
          : ActivityParticipantPivot.fromJson(
              json['pivot'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ActivityParticipantToJson(
  ActivityParticipant instance,
) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'prenoms': instance.prenoms,
  'avatar': instance.avatar,
  'pivot': instance.pivot?.toJson(),
};

Activity _$ActivityFromJson(Map<String, dynamic> json) => Activity(
  id: (json['id'] as num).toInt(),
  ownerId: (json['id_utilisateur'] as num).toInt(),
  teamId: (json['id_equipe'] as num?)?.toInt(),
  titre: json['titre'] as String,
  contenu: json['contenu'] as String?,
  date: json['date'] as String?,
  heure: json['heure'] as String?,
  lieu: json['lieu'] as String?,
  categorie: json['categorie'] as String?,
  genre: json['genre'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 0,
  owner: json['owner'] == null
      ? null
      : ActivityUserRef.fromJson(json['owner'] as Map<String, dynamic>),
  team: json['team'] == null
      ? null
      : ActivityTeamRef.fromJson(json['team'] as Map<String, dynamic>),
  participants: (json['participants'] as List<dynamic>?)
      ?.map((e) => ActivityParticipant.fromJson(e as Map<String, dynamic>))
      .toList(),
  updatedAt: json['updated_at'] as String?,
);

Map<String, dynamic> _$ActivityToJson(Activity instance) => <String, dynamic>{
  'id': instance.id,
  'id_utilisateur': instance.ownerId,
  'id_equipe': instance.teamId,
  'titre': instance.titre,
  'contenu': instance.contenu,
  'date': instance.date,
  'heure': instance.heure,
  'lieu': instance.lieu,
  'categorie': instance.categorie,
  'genre': instance.genre,
  'statut': instance.statut,
  'owner': instance.owner?.toJson(),
  'team': instance.team?.toJson(),
  'participants': instance.participants?.map((e) => e.toJson()).toList(),
  'updated_at': instance.updatedAt,
};
