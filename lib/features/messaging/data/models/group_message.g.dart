// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMessage _$GroupMessageFromJson(Map<String, dynamic> json) => GroupMessage(
  id: (json['id'] as num).toInt(),
  authorId: (json['id_utilisateur'] as num).toInt(),
  conversationId: (json['id_conversation'] as num).toInt(),
  message: json['message'] as String,
  fichier: json['fichier'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] as String?,
  author: json['author'] == null
      ? null
      : MessageParticipant.fromJson(json['author'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GroupMessageToJson(GroupMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_utilisateur': instance.authorId,
      'id_conversation': instance.conversationId,
      'message': instance.message,
      'fichier': instance.fichier,
      'statut': instance.statut,
      'created_at': instance.createdAt,
      'author': instance.author?.toJson(),
    };
