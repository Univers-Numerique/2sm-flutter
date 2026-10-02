// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: (json['id'] as num).toInt(),
  senderId: (json['id_expediteur'] as num).toInt(),
  receiverId: (json['id_destinataire'] as num).toInt(),
  message: json['message'] as String,
  statut: (json['statut'] as num?)?.toInt() ?? 0,
  fichier: json['fichier'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  sender: json['sender'] == null
      ? null
      : MessageParticipant.fromJson(json['sender'] as Map<String, dynamic>),
  receiver: json['receiver'] == null
      ? null
      : MessageParticipant.fromJson(json['receiver'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'id_expediteur': instance.senderId,
  'id_destinataire': instance.receiverId,
  'message': instance.message,
  'statut': instance.statut,
  'fichier': instance.fichier,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'sender': instance.sender?.toJson(),
  'receiver': instance.receiver?.toJson(),
};
