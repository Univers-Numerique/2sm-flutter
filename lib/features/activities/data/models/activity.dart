import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

/// Activity statuses, matching the `activites.statut` column.
///
/// Note: the Laravel `ActivityController::store` currently defaults new
/// activities to `statut = 1` ("en cours") rather than `0` ("planifiée") —
/// that's a backend quirk, not something this UI can fix; the label mapping
/// below still follows the documented 0..3 workflow.
class ActivityStatus {
  static const planned = 0;
  static const started = 1;
  static const cancelled = 2;
  static const finished = 3;
}

@JsonSerializable()
class ActivityUserRef {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;

  const ActivityUserRef({required this.id, this.nom, this.prenoms, this.avatar});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  factory ActivityUserRef.fromJson(Map<String, dynamic> json) => _$ActivityUserRefFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityUserRefToJson(this);
}

@JsonSerializable()
class ActivityTeamRef {
  final int id;
  final String nom;
  final String? logo;

  const ActivityTeamRef({required this.id, required this.nom, this.logo});

  factory ActivityTeamRef.fromJson(Map<String, dynamic> json) => _$ActivityTeamRefFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityTeamRefToJson(this);
}

/// The `utilisateurs_liaison_activite` pivot row: `statut` doubles as both
/// "is a participant" and "is present" (1 = present/participating,
/// 0 = registered but absent / left), matching `ActivityController::attendance`.
@JsonSerializable()
class ActivityParticipantPivot {
  @JsonKey(name: 'id_activite')
  final int activityId;
  @JsonKey(name: 'id_utilisateur')
  final int userId;
  @JsonKey(defaultValue: 0)
  final int statut;

  const ActivityParticipantPivot({required this.activityId, required this.userId, this.statut = 0});

  bool get isPresent => statut == 1;

  factory ActivityParticipantPivot.fromJson(Map<String, dynamic> json) => _$ActivityParticipantPivotFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityParticipantPivotToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ActivityParticipant {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;
  final ActivityParticipantPivot? pivot;

  const ActivityParticipant({required this.id, this.nom, this.prenoms, this.avatar, this.pivot});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');
  bool get isPresent => pivot?.isPresent ?? false;

  factory ActivityParticipant.fromJson(Map<String, dynamic> json) => _$ActivityParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityParticipantToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Activity {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int ownerId;
  @JsonKey(name: 'id_equipe')
  final int? teamId;
  final String titre;
  final String? contenu;
  final String? date;
  final String? heure;
  final String? lieu;
  final String? categorie;
  final String? genre;
  @JsonKey(defaultValue: 0)
  final int statut;
  final ActivityUserRef? owner;
  final ActivityTeamRef? team;
  final List<ActivityParticipant>? participants;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const Activity({
    required this.id,
    required this.ownerId,
    this.teamId,
    required this.titre,
    this.contenu,
    this.date,
    this.heure,
    this.lieu,
    this.categorie,
    this.genre,
    this.statut = 0,
    this.owner,
    this.team,
    this.participants,
    this.updatedAt,
  });

  bool get isPlanned => statut == ActivityStatus.planned;
  bool get isStarted => statut == ActivityStatus.started;
  bool get isCancelled => statut == ActivityStatus.cancelled;
  bool get isFinished => statut == ActivityStatus.finished;

  bool isOwnedBy(int userId) => ownerId == userId;

  int get invitedCount => participants?.length ?? 0;
  int get presentCount => (participants ?? const <ActivityParticipant>[]).where((p) => p.isPresent).length;
  int get absentCount => invitedCount - presentCount;

  bool isParticipant(int userId) => (participants ?? const []).any((p) => p.id == userId);

  ActivityParticipant? participant(int userId) {
    for (final p in participants ?? const <ActivityParticipant>[]) {
      if (p.id == userId) return p;
    }
    return null;
  }

  static String statusLabel(int statut) {
    switch (statut) {
      case ActivityStatus.planned:
        return 'Activité future';
      case ActivityStatus.started:
        return 'Activité en cours';
      case ActivityStatus.cancelled:
        return 'Activité annulée';
      case ActivityStatus.finished:
        return 'Activité terminée';
      default:
        return 'Inconnue';
    }
  }

  factory Activity.fromJson(Map<String, dynamic> json) => _$ActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityToJson(this);
}
