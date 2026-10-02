import 'package:json_annotation/json_annotation.dart';

part 'match_game.g.dart';

/// The list of `jeu` event-type labels the live console can log, exactly as
/// the Laravel `GameEvent` model's constants expect them (French labels are
/// the actual values stored/matched against in `MatchController::updateScores`).
class GameEventType {
  static const buts = 'Buts Marqués';
  static const tirsCadres = 'Tirs Cadrés';
  static const tirsNonCadres = 'Tirs non Cadrés';
  static const corners = 'Corners';
  static const cartonsJaunes = 'Cartons Jaunes';
  static const cartonsRouges = 'Cartons Rouges';

  static const all = [buts, tirsCadres, tirsNonCadres, corners, cartonsJaunes, cartonsRouges];

  static const passes = 'Passes Décisives';
  static const coupsFrancs = 'Coups Francs';
  static const penalty = 'Tirs au But';
  static const fautes = 'Fautes Comises';

  /// Évènements principaux de la console d'arbitrage (arbitrage.php) puis
  /// statistiques secondaires de jeu.
  static const primary = [buts, passes, tirsCadres, tirsNonCadres, penalty, coupsFrancs, corners, cartonsJaunes, cartonsRouges];
  static const secondary = [
    fautes,
    'Passes Réussies',
    'Passes Longues Réussies',
    'Passes Courtes Réussies',
    'Centres Réussis',
    'Centres Ratés',
    'Interceptions',
    'Tacles Réussis',
    'Tacles Ratés',
    'Duel Gagné',
    'Duel Perdu',
  ];

  static String label(String jeu) {
    switch (jeu) {
      case buts:
        return 'But';
      case passes:
        return 'Passe décisive';
      case coupsFrancs:
        return 'Coup franc';
      case penalty:
        return 'Pénalty';
      case tirsCadres:
        return 'Tir cadré';
      case tirsNonCadres:
        return 'Tir non cadré';
      case corners:
        return 'Corner';
      case cartonsJaunes:
        return 'Carton jaune';
      case cartonsRouges:
        return 'Carton rouge';
      case 'Début de match':
      case 'Debut de match':
        return 'Début de match';
      case 'Fin de match':
        return 'Fin de match';
      default:
        return jeu;
    }
  }
}

/// Match statuses, matching the `matchs.statut` column.
class MatchStatus {
  static const scheduled = 0;
  static const inProgress = 1;
  static const finished = 3;
}

@JsonSerializable()
class MatchTeamRef {
  final int id;
  final String nom;
  final String? logo;
  final String? lieu;

  const MatchTeamRef({required this.id, required this.nom, this.logo, this.lieu});

  factory MatchTeamRef.fromJson(Map<String, dynamic> json) => _$MatchTeamRefFromJson(json);
  Map<String, dynamic> toJson() => _$MatchTeamRefToJson(this);
}

@JsonSerializable()
class MatchCompetitionRef {
  final int id;
  final String nom;

  const MatchCompetitionRef({required this.id, required this.nom});

  factory MatchCompetitionRef.fromJson(Map<String, dynamic> json) => _$MatchCompetitionRefFromJson(json);
  Map<String, dynamic> toJson() => _$MatchCompetitionRefToJson(this);
}

@JsonSerializable()
class MatchFieldRef {
  final int id;
  @JsonKey(name: 'nom_terrain')
  final String? nomTerrain;
  final String? lieu;
  final String? photo;

  const MatchFieldRef({required this.id, this.nomTerrain, this.lieu, this.photo});

  factory MatchFieldRef.fromJson(Map<String, dynamic> json) => _$MatchFieldRefFromJson(json);
  Map<String, dynamic> toJson() => _$MatchFieldRefToJson(this);
}

@JsonSerializable()
class GamePlayerRef {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;

  const GamePlayerRef({required this.id, this.nom, this.prenoms, this.avatar});

  String get fullName => [prenoms, nom].where((s) => s != null && s.isNotEmpty).join(' ');

  factory GamePlayerRef.fromJson(Map<String, dynamic> json) => _$GamePlayerRefFromJson(json);
  Map<String, dynamic> toJson() => _$GamePlayerRefToJson(this);
}

@JsonSerializable(explicitToJson: true)
class GameEvent {
  final int id;
  @JsonKey(name: 'id_match')
  final int matchId;
  @JsonKey(name: 'id_equipe')
  final int teamId;
  @JsonKey(name: 'id_utilisateur')
  final int userId;
  final String jeu;
  final String temps;
  @JsonKey(defaultValue: 1)
  final int statut;
  final GamePlayerRef? player;

  const GameEvent({
    required this.id,
    required this.matchId,
    required this.teamId,
    required this.userId,
    required this.jeu,
    required this.temps,
    this.statut = 1,
    this.player,
  });

  /// statut 1 = validated/active, 0 = voided by an operator/announcer.
  bool get isValid => statut == 1;

  factory GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);
  Map<String, dynamic> toJson() => _$GameEventToJson(this);
}

@JsonSerializable()
class MatchScore {
  final int id;
  @JsonKey(name: 'id_equipe')
  final int teamId;
  @JsonKey(defaultValue: 0)
  final int buts;
  @JsonKey(name: 'buts_encaisses', defaultValue: 0)
  final int butsEncaisses;
  @JsonKey(name: 'tires_cadres', defaultValue: 0)
  final int tiresCadres;
  @JsonKey(name: 'tires_non_cadres', defaultValue: 0)
  final int tiresNonCadres;
  @JsonKey(name: 'tires_au_buts', defaultValue: 0)
  final int tiresAuButs;
  @JsonKey(name: 'coups_francs', defaultValue: 0)
  final int coupsFrancs;
  @JsonKey(defaultValue: 0)
  final int corners;
  @JsonKey(name: 'cartons_jaunes', defaultValue: 0)
  final int cartonsJaunes;
  @JsonKey(name: 'cartons_rouges', defaultValue: 0)
  final int cartonsRouges;
  final String? resultat;

  const MatchScore({
    required this.id,
    required this.teamId,
    this.buts = 0,
    this.butsEncaisses = 0,
    this.tiresCadres = 0,
    this.tiresNonCadres = 0,
    this.tiresAuButs = 0,
    this.coupsFrancs = 0,
    this.corners = 0,
    this.cartonsJaunes = 0,
    this.cartonsRouges = 0,
    this.resultat,
  });

  factory MatchScore.fromJson(Map<String, dynamic> json) => _$MatchScoreFromJson(json);
  Map<String, dynamic> toJson() => _$MatchScoreToJson(this);
}

@JsonSerializable(explicitToJson: true)
class MatchGame {
  final int id;
  @JsonKey(name: 'id_utilisateur')
  final int ownerId;
  @JsonKey(name: 'id_competition')
  final int? competitionId;
  @JsonKey(name: 'id_equipe_domicile')
  final int homeTeamId;
  @JsonKey(name: 'id_equipe_exterieur')
  final int awayTeamId;
  @JsonKey(defaultValue: 0)
  final int statut;
  @JsonKey(name: 'date_debut')
  final String? dateDebut;
  @JsonKey(name: 'heure_debut')
  final String? heureDebut;
  @JsonKey(name: 'id_annonciateur_public')
  final int? announcerId;
  final String? genre;
  final String? categorie;
  final int? lieu;
  final String? saison;
  @JsonKey(name: 'id_arbitre_principal')
  final int? arbitrePrincipalId;
  @JsonKey(name: 'id_arbitre_de_touche_1')
  final int? arbitreTouche1Id;
  @JsonKey(name: 'id_arbitre_de_touche_2')
  final int? arbitreTouche2Id;
  @JsonKey(name: 'id_commentateur_1')
  final int? commentateur1Id;
  @JsonKey(name: 'id_commentateur_2')
  final int? commentateur2Id;
  @JsonKey(name: 'id_chronometreur')
  final int? chronometreurId;
  @JsonKey(name: 'home_team')
  final MatchTeamRef? homeTeam;
  @JsonKey(name: 'away_team')
  final MatchTeamRef? awayTeam;
  final MatchCompetitionRef? competition;
  final MatchFieldRef? field;
  @JsonKey(name: 'game_events')
  final List<GameEvent>? gameEventsOrNull;
  final List<MatchScore>? scores;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const MatchGame({
    required this.id,
    required this.ownerId,
    this.competitionId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.statut = 0,
    this.dateDebut,
    this.heureDebut,
    this.announcerId,
    this.genre,
    this.categorie,
    this.lieu,
    this.saison,
    this.arbitrePrincipalId,
    this.arbitreTouche1Id,
    this.arbitreTouche2Id,
    this.commentateur1Id,
    this.commentateur2Id,
    this.chronometreurId,
    this.homeTeam,
    this.awayTeam,
    this.competition,
    this.field,
    this.gameEventsOrNull,
    this.scores,
    this.updatedAt,
  });

  List<GameEvent> get gameEvents => gameEventsOrNull ?? const [];

  /// Only validated events, oldest first (server already orders by `temps`).
  List<GameEvent> get validEvents => gameEvents.where((e) => e.isValid).toList();

  bool get isScheduled => statut == MatchStatus.scheduled;
  bool get isInProgress => statut == MatchStatus.inProgress;
  bool get isFinished => statut == MatchStatus.finished;

  bool isOwnedBy(int userId) => ownerId == userId;
  bool isAnnouncedBy(int userId) => announcerId != null && announcerId != 0 && announcerId == userId;

  /// Who may run the live-arbitration console: the match's creator, or its
  /// announcer if that role has been assigned (the announcer FK is exposed
  /// by the detail payload as `id_annonciateur_public`).
  bool canOperate(int userId) => isOwnedBy(userId) || isAnnouncedBy(userId);

  /// Who may validate/void individual events — matches
  /// `MatchController::updateEventStatus`'s own authorization rule.
  bool canModerateEvents(int userId) => isOwnedBy(userId) || isAnnouncedBy(userId);

  MatchScore? scoreForTeam(int teamId) {
    for (final s in scores ?? const <MatchScore>[]) {
      if (s.teamId == teamId) return s;
    }
    return null;
  }

  int get homeGoals => scoreForTeam(homeTeamId)?.buts ?? _countGoals(homeTeamId);
  int get awayGoals => scoreForTeam(awayTeamId)?.buts ?? _countGoals(awayTeamId);

  int _countGoals(int teamId) =>
      validEvents.where((e) => e.teamId == teamId && e.jeu == GameEventType.buts).length;

  factory MatchGame.fromJson(Map<String, dynamic> json) => _$MatchGameFromJson(json);
  Map<String, dynamic> toJson() => _$MatchGameToJson(this);
}
