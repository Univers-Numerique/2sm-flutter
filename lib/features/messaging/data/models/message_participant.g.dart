// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageParticipant _$MessageParticipantFromJson(Map<String, dynamic> json) =>
    MessageParticipant(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$MessageParticipantToJson(MessageParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
    };
