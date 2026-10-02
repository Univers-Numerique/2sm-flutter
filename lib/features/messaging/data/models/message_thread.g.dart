// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageThread _$MessageThreadFromJson(Map<String, dynamic> json) =>
    MessageThread(
      user: MessageParticipant.fromJson(json['user'] as Map<String, dynamic>),
      lastMessage: Message.fromJson(
        json['last_message'] as Map<String, dynamic>,
      ),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MessageThreadToJson(MessageThread instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'last_message': instance.lastMessage.toJson(),
      'unread_count': instance.unreadCount,
    };
