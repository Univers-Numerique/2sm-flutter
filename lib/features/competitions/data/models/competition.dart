import 'package:json_annotation/json_annotation.dart';

import '../../../matches/data/models/match_game.dart';

part 'competition.g.dart';

/// Competition statuses, matching the `competitions.statut` column.
class CompetitionStatus {
  static const upcoming = 0;
  static const inProgress = 1;
  static const cancelled = 2;
  static const finished = 3;

  static const all = [upcoming, inProgress, cancelled, finished];

  static String label(int statut) {
    switch (statut) {
      case upcoming:
        return 'À venir';
      case inProgress:
        return 'En cours';
      case cancelled:
        return 'Annulée';
      case finished:
        return 'Terminée';
      default:
        return 'Statut $statut';
    }
  }
}

@JsonSerializable()
class CompetitionOwnerRef {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;

  const CompetitionOwnerRef({required this.id, this.nom, this.prenoms, this.avatar});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  factory CompetitionOwnerRef.fromJson(Map<String, dynamic> json) => _$CompetitionOwnerRefFromJson(json);
  Map<String, dynamic> toJson() => _$CompetitionOwnerRefToJson(this);
}

/// A team linked to a competition (the `teams` pivot on the detail payload).
@JsonSerializable()
class CompetitionTeamRef {
  final int id;
  final String? nom;
  final String? logo;

  const CompetitionTeamRef({required this.id, this.nom, this.logo});

  factory CompetitionTeamRef.fromJson(Map<String, dynamic> json) => _$CompetitionTeamRefFromJson(json);
  Map<String, dynamic> toJson() => _$CompetitionTeamRefToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Competition {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int ownerId;
  final String nom;
  final String? description;
  final String? categorie;
  final String? genre;
  @JsonKey(name: 'date_debut')
  final String? dateDebut;
  @JsonKey(name: 'heure_debut')
  final String? heureDebut;
  @JsonKey(defaultValue: 0)
  final int statut;
  @JsonKey(defaultValue: 0)
  final int selection;
  final String? saison;
  final String? photo;
  final CompetitionOwnerRef? owner;
  @JsonKey(name: 'teams')
  final List<CompetitionTeamRef>? teamsOrNull;
  @JsonKey(name: 'matches')
  final List<MatchGame>? matchesOrNull;
  @JsonKey(name: 'matches_count')
  final int? matchesCount;
  @JsonKey(name: 'finished_matches_count')
  final int? finishedMatchesCount;
  @JsonKey(name: 'fields')
  final List<MatchFieldRef>? fieldsOrNull;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const Competition({
    required this.id,
    required this.ownerId,
    required this.nom,
    this.description,
    this.categorie,
    this.genre,
    this.dateDebut,
    this.heureDebut,
    this.statut = 0,
    this.selection = 0,
    this.saison,
    this.photo,
    this.owner,
    this.teamsOrNull,
    this.matchesOrNull,
    this.matchesCount,
    this.finishedMatchesCount,
    this.fieldsOrNull,
    this.updatedAt,
  });

  List<CompetitionTeamRef> get teams => teamsOrNull ?? const [];
  List<MatchGame> get matches => matchesOrNull ?? const [];

  List<MatchFieldRef> get fields => fieldsOrNull ?? const [];

  /// Nom du (premier) stade rattaché — "Lieu" dans le legacy.
  String? get lieu => fields.isEmpty ? null : fields.first.nomTerrain;

  int get matchesPlayed => matchesOrNull != null ? matches.where((m) => m.isFinished).length : (finishedMatchesCount ?? 0);
  int get matchesTotal => matchesOrNull != null ? matches.length : (matchesCount ?? 0);
  double get progress => matchesTotal == 0 ? 0 : matchesPlayed / matchesTotal;

  /// True when [userId] owns this competition — mirrors [Team.isManagedBy]:
  /// the same detail screen conditionally reveals owner-only actions
  /// (generate/clear fixtures, edit/delete) instead of a separate console.
  bool isOwnedBy(int userId) => ownerId == userId;

  factory Competition.fromJson(Map<String, dynamic> json) => _$CompetitionFromJson(json);
  Map<String, dynamic> toJson() => _$CompetitionToJson(this);
}
