import 'package:json_annotation/json_annotation.dart';

part 'activity_task.g.dart';

/// Task statuses, matching the `taches.statut` column.
///
/// Workflow (see `TaskController::updateStatus`): 0 (à faire) -> 1 (prise en
/// charge) -> 2 (terminée). The assignee may only advance one step at a
/// time; the activity/team owner may set any status directly.
class TaskStatus {
  static const todo = 0;
  static const inProgress = 1;
  static const done = 2;
  static const cancelled = 3;
}

@JsonSerializable()
class TaskUserRef {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;

  const TaskUserRef({required this.id, this.nom, this.prenoms, this.avatar});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  factory TaskUserRef.fromJson(Map<String, dynamic> json) => _$TaskUserRefFromJson(json);
  Map<String, dynamic> toJson() => _$TaskUserRefToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ActivityTask {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int assigneeId;
  @JsonKey(name: 'id_activite')
  final int activityId;
  @JsonKey(name: 'id_equipe')
  final int? teamId;
  final String tache;
  @JsonKey(defaultValue: 0)
  final int statut;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  /// The API eager-loads this as `owner` (`Task::owner()` is a `belongsTo`
  /// on `id_utilisateur`) but it's actually the *assignee*'s profile, not a
  /// separate task creator — the schema has no creator column.
  final TaskUserRef? owner;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const ActivityTask({
    required this.id,
    required this.assigneeId,
    required this.activityId,
    this.teamId,
    required this.tache,
    this.statut = 0,
    this.owner,
    this.updatedAt,
    this.createdAt,
  });

  bool get isTodo => statut == TaskStatus.todo;
  bool get isInProgress => statut == TaskStatus.inProgress;
  bool get isDone => statut == TaskStatus.done;
  bool get isCancelled => statut == TaskStatus.cancelled;

  bool isAssignedTo(int userId) => assigneeId == userId;

  static String statusLabel(int statut) {
    switch (statut) {
      case TaskStatus.todo:
        return 'En attente';
      case TaskStatus.inProgress:
        return 'Pigée';
      case TaskStatus.done:
        return 'Effectuée';
      case TaskStatus.cancelled:
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }

  factory ActivityTask.fromJson(Map<String, dynamic> json) => _$ActivityTaskFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityTaskToJson(this);
}
