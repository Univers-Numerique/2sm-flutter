import 'package:json_annotation/json_annotation.dart';

part 'message_participant.g.dart';

/// Minimal embedded user info, as eager-loaded on messages
/// (`sender:id,nom,prenoms,avatar` / `receiver:...`) and conversations
/// (`owner:...`).
@JsonSerializable()
class MessageParticipant {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;

  const MessageParticipant({required this.id, this.nom, this.prenoms, this.avatar});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  factory MessageParticipant.fromJson(Map<String, dynamic> json) => _$MessageParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$MessageParticipantToJson(this);
}
