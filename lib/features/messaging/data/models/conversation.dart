import 'package:json_annotation/json_annotation.dart';

import 'group_message.dart';
import 'message_participant.dart';

part 'conversation.g.dart';

/// A group `conversations` row. Note: the `statut` column is stored as a
/// SQL `string` but the create endpoint echoes it back as a bare JSON
/// integer while the list endpoint returns it as a JSON string — [statut]
/// is normalized to a String here to tolerate either shape.
@JsonSerializable(explicitToJson: true)
class Conversation {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int ownerId;
  final String? sujet;
  final String? description;
  final String? photo;
  final String? type;
  @JsonKey(fromJson: _statutFromJson)
  final String? statut;
  @JsonKey(name: 'users_count')
  final int? usersCount;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final MessageParticipant? owner;
  @JsonKey(name: 'unread_count', defaultValue: 0)
  final int unreadCount;

  /// Current user's link to the group: 0 left/banned, 1 member, 2 admin.
  @JsonKey(name: 'my_statut')
  final int? myStatut;
  @JsonKey(name: 'last_message')
  final GroupMessage? lastMessage;
  final List<ConversationMember>? users;

  const Conversation({
    required this.id,
    required this.ownerId,
    this.sujet,
    this.description,
    this.photo,
    this.type,
    this.statut,
    this.usersCount,
    this.createdAt,
    this.updatedAt,
    this.owner,
    this.unreadCount = 0,
    this.myStatut,
    this.lastMessage,
    this.users,
  });

  bool get isPublic => (type ?? '').toLowerCase() == 'public';
  bool get isMember => (myStatut ?? 0) >= 1;
  bool get isAdminMember => myStatut == 2;
  int get memberCount => usersCount ?? users?.length ?? 0;

  static String? _statutFromJson(Object? value) => value?.toString();

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}


/// A user linked to a group. Pivot `statut`: 0 banned/left, 1 member, 2 admin.
@JsonSerializable(explicitToJson: true)
class ConversationMember {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;
  final ConversationMemberPivot? pivot;

  const ConversationMember({required this.id, this.nom, this.prenoms, this.avatar, this.pivot});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');
  int get statut => pivot?.statut ?? 1;
  String get statutLabel => const ['Banni', 'Membre', 'Administrateur'][statut.clamp(0, 2)];

  factory ConversationMember.fromJson(Map<String, dynamic> json) => _$ConversationMemberFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationMemberToJson(this);
}

@JsonSerializable()
class ConversationMemberPivot {
  @JsonKey(defaultValue: 1)
  final int statut;
  const ConversationMemberPivot({this.statut = 1});

  factory ConversationMemberPivot.fromJson(Map<String, dynamic> json) => _$ConversationMemberPivotFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationMemberPivotToJson(this);
}
