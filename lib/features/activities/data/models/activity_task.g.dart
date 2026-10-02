// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskUserRef _$TaskUserRefFromJson(Map<String, dynamic> json) => TaskUserRef(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  prenoms: json['prenoms'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$TaskUserRefToJson(TaskUserRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
    };

ActivityTask _$ActivityTaskFromJson(Map<String, dynamic> json) => ActivityTask(
  id: (json['id'] as num).toInt(),
  assigneeId: (json['id_utilisateur'] as num).toInt(),
  activityId: (json['id_activite'] as num).toInt(),
  teamId: (json['id_equipe'] as num?)?.toInt(),
  tache: json['tache'] as String,
  statut: (json['statut'] as num?)?.toInt() ?? 0,
  owner: json['owner'] == null
      ? null
      : TaskUserRef.fromJson(json['owner'] as Map<String, dynamic>),
  updatedAt: json['updated_at'] as String?,
  createdAt: json['created_at'] as String?,
);

Map<String, dynamic> _$ActivityTaskToJson(ActivityTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_utilisateur': instance.assigneeId,
      'id_activite': instance.activityId,
      'id_equipe': instance.teamId,
      'tache': instance.tache,
      'statut': instance.statut,
      'created_at': instance.createdAt,
      'owner': instance.owner?.toJson(),
      'updated_at': instance.updatedAt,
    };
