import 'package:json_annotation/json_annotation.dart';

import 'message.dart';
import 'message_participant.dart';

part 'message_thread.g.dart';

/// One private contact from `GET /messages/threads`: the other user, the
/// last message exchanged and the number of unread incoming messages.
@JsonSerializable(explicitToJson: true)
class MessageThread {
  final MessageParticipant user;
  @JsonKey(name: 'last_message')
  final Message lastMessage;
  @JsonKey(name: 'unread_count', defaultValue: 0)
  final int unreadCount;

  const MessageThread({required this.user, required this.lastMessage, this.unreadCount = 0});

  factory MessageThread.fromJson(Map<String, dynamic> json) => _$MessageThreadFromJson(json);
  Map<String, dynamic> toJson() => _$MessageThreadToJson(this);
}
