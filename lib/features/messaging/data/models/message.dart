import 'package:json_annotation/json_annotation.dart';

import 'message_participant.dart';

part 'message.g.dart';

/// A private 1:1 `messages` row (`id_expediteur` -> `id_destinataire`).
/// There is no `id_conversation` on this table — group messaging is a
/// separate, currently-unimplemented concern; see ConversationsRepository.
@JsonSerializable(explicitToJson: true)
class Message {
  final int id;
  @JsonKey(name: 'id_expediteur')
  final int senderId;
  @JsonKey(name: 'id_destinataire')
  final int receiverId;
  final String message;
  @JsonKey(defaultValue: 0)
  final int statut; // 0 = non lu, 1 = lu
  final String? fichier;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final MessageParticipant? sender;
  final MessageParticipant? receiver;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.statut = 0,
    this.fichier,
    this.createdAt,
    this.updatedAt,
    this.sender,
    this.receiver,
  });

  bool get isRead => statut == 1;

  bool sentBy(int userId) => senderId == userId;

  /// The id of the other participant in this 1:1 thread, from [userId]'s
  /// point of view.
  int otherUserId(int userId) => senderId == userId ? receiverId : senderId;

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
