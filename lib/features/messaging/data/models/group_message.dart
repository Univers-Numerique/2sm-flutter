import 'package:json_annotation/json_annotation.dart';

import 'message_participant.dart';

part 'group_message.g.dart';

/// A `messages_conversation` row — group-chat counterpart of [Message].
/// Backend note: this table existed in the schema but had no
/// model/controller/route until the Phase-0 gap was closed (added
/// `MessageController::conversationMessages`/`storeConversationMessage`).
@JsonSerializable(explicitToJson: true)
class GroupMessage {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int authorId;
  @JsonKey(name: 'id_conversation')
  final int conversationId;
  final String message;
  final String? fichier;
  @JsonKey(defaultValue: 0)
  final int statut;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  final MessageParticipant? author;

  const GroupMessage({
    required this.id,
    required this.authorId,
    required this.conversationId,
    required this.message,
    this.fichier,
    this.statut = 0,
    this.createdAt,
    this.author,
  });

  bool sentBy(int userId) => authorId == userId;

  factory GroupMessage.fromJson(Map<String, dynamic> json) => _$GroupMessageFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMessageToJson(this);
}
