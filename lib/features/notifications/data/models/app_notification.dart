import 'package:json_annotation/json_annotation.dart';

part 'app_notification.g.dart';

/// The match proposition embedded by `GET /notifications` when
/// `id_proposition` is set: statut 0 pending, 1 accepted, 2 refused.
@JsonSerializable()
class NotificationProposition {
  final int id;
  @JsonKey(name: 'id_proposeur')
  final int? proposerId;
  @JsonKey(name: 'id_proposee')
  final int? proposedId;
  @JsonKey(defaultValue: 0)
  final int statut;

  const NotificationProposition({required this.id, this.proposerId, this.proposedId, this.statut = 0});

  factory NotificationProposition.fromJson(Map<String, dynamic> json) => _$NotificationPropositionFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPropositionToJson(this);
}

/// A `notifications` row. The API now exposes the current user's read
/// status as a flat `statut_lecture` ('lu'/'non lu') field on every record
/// (backend fix: `GET /notifications` used to run `whereHas('users', ...)`
/// as an existence-only check, without hydrating the
/// `notification_liaison_utilisateur` pivot where that status actually
/// lives). [readLocal] is kept as a client-side fallback/optimistic flag
/// (patched right after a successful mark-as-read call, before the next
/// sync pull confirms it) — see NotificationsRepository.
@JsonSerializable()
class AppNotification {
  final int id;
  final String titre;
  final String? contenu;
  final String? image;
  final String? lien;
  @JsonKey(defaultValue: 0)
  final int statut;
  final String? tables;
  final String? categorie;
  final String? photo;

  /// Present in the `notifications` table's fillable columns but never
  /// actually populated by any code path observed in the Laravel app
  /// (verified in MatchController's friendly-match proposal flow, which
  /// creates the Proposition and the Notification as two separate,
  /// unlinked records) — kept here defensively so accept/refuse actions
  /// light up automatically if a future backend change starts setting it.
  @JsonKey(name: 'id_proposition')
  final int? idProposition;

  final NotificationProposition? proposition;
  @JsonKey(name: 'titre_publication')
  final String? titrePublication;
  @JsonKey(name: 'contenu_publication')
  final String? contenuPublication;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  @JsonKey(name: '_read_local', defaultValue: false)
  final bool readLocal;

  @JsonKey(name: 'statut_lecture', defaultValue: 'non lu')
  final String statutLecture;

  const AppNotification({
    required this.id,
    required this.titre,
    this.contenu,
    this.image,
    this.lien,
    this.statut = 0,
    this.tables,
    this.categorie,
    this.photo,
    this.idProposition,
    this.proposition,
    this.titrePublication,
    this.contenuPublication,
    this.createdAt,
    this.updatedAt,
    this.readLocal = false,
    this.statutLecture = 'non lu',
  });

  bool get isPropositionNotification => idProposition != null;
  bool get isRead => readLocal || statutLecture == 'lu';

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$AppNotificationToJson(this);
}
