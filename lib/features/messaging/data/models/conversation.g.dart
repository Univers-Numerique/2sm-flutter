// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: (json['id'] as num).toInt(),
  ownerId: (json['id_utilisateur'] as num).toInt(),
  sujet: json['sujet'] as String?,
  description: json['description'] as String?,
  photo: json['photo'] as String?,
  type: json['type'] as String?,
  statut: Conversation._statutFromJson(json['statut']),
  usersCount: (json['users_count'] as num?)?.toInt(),
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  owner: json['owner'] == null
      ? null
      : MessageParticipant.fromJson(json['owner'] as Map<String, dynamic>),
  unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
  myStatut: (json['my_statut'] as num?)?.toInt(),
  lastMessage: json['last_message'] == null
      ? null
      : GroupMessage.fromJson(json['last_message'] as Map<String, dynamic>),
  users: (json['users'] as List<dynamic>?)
      ?.map((e) => ConversationMember.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_utilisateur': instance.ownerId,
      'sujet': instance.sujet,
      'description': instance.description,
      'photo': instance.photo,
      'type': instance.type,
      'statut': instance.statut,
      'users_count': instance.usersCount,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'owner': instance.owner?.toJson(),
      'unread_count': instance.unreadCount,
      'my_statut': instance.myStatut,
      'last_message': instance.lastMessage?.toJson(),
      'users': instance.users?.map((e) => e.toJson()).toList(),
    };

ConversationMember _$ConversationMemberFromJson(Map<String, dynamic> json) =>
    ConversationMember(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
      pivot: json['pivot'] == null
          ? null
          : ConversationMemberPivot.fromJson(
              json['pivot'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ConversationMemberToJson(ConversationMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
      'pivot': instance.pivot?.toJson(),
    };

ConversationMemberPivot _$ConversationMemberPivotFromJson(
  Map<String, dynamic> json,
) => ConversationMemberPivot(statut: (json['statut'] as num?)?.toInt() ?? 1);

Map<String, dynamic> _$ConversationMemberPivotToJson(
  ConversationMemberPivot instance,
) => <String, dynamic>{'statut': instance.statut};
