import '../../../matches/data/models/match_game.dart';
import 'competition.dart';

int _i(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  return 0;
}

double _d(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

String? _s(Object? v) => v?.toString();

Map<String, dynamic> _m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _l(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

/// Compteurs du bloc "Statistiques" de la fiche compétition.
class CompetitionStats {
  final int equipes;
  final int matchs;
  final int enCours;
  final int termines;
  final int futurs;
  final int buts;
  final int passes;
  final int cartonsJaunes;
  final int cartonsRouges;

  const CompetitionStats({
    this.equipes = 0,
    this.matchs = 0,
    this.enCours = 0,
    this.termines = 0,
    this.futurs = 0,
    this.buts = 0,
    this.passes = 0,
    this.cartonsJaunes = 0,
    this.cartonsRouges = 0,
  });

  factory CompetitionStats.fromJson(Map<String, dynamic> j) => CompetitionStats(
        equipes: _i(j['equipes_participantes']),
        matchs: _i(j['nb_matchs']),
        enCours: _i(j['en_cours']),
        termines: _i(j['termines']),
        futurs: _i(j['futurs']),
        buts: _i(j['buts']),
        passes: _i(j['passes']),
        cartonsJaunes: _i(j['CJ']),
        cartonsRouges: _i(j['CR']),
      );
}

/// Une ligne du classement d'une compétition (`classement[]`).
class StandingRow {
  final int teamId;
  final String nom;
  final String? logo;
  final int joues;
  final int prevus;
  final int victoires;
  final int nuls;
  final int defaites;
  final int butsPour;
  final int butsContre;
  final int difference;
  final int points;
  final double progression;

  const StandingRow({
    required this.teamId,
    required this.nom,
    this.logo,
    this.joues = 0,
    this.prevus = 0,
    this.victoires = 0,
    this.nuls = 0,
    this.defaites = 0,
    this.butsPour = 0,
    this.butsContre = 0,
    this.difference = 0,
    this.points = 0,
    this.progression = 0,
  });

  factory StandingRow.fromJson(Map<String, dynamic> j) => StandingRow(
        teamId: _i(j['id']),
        nom: _s(j['nom']) ?? '',
        logo: _s(j['logo']),
        joues: _i(j['matchs_joues']),
        prevus: _i(j['nb_matchs']),
        victoires: _i(j['victoire']),
        nuls: _i(j['nul']),
        defaites: _i(j['defaite']),
        butsPour: _i(j['buts_pour']),
        butsContre: _i(j['buts_contre']),
        difference: _i(j['difference_buts']),
        points: _i(j['points']),
        progression: _d(j['progression']),
      );
}

/// Classement d'une compétition (utilisé par l'écran "Classements").
class CompetitionStandings {
  final int competitionId;
  final String nom;
  final String? saison;
  final String? photo;
  final List<StandingRow> rows;

  const CompetitionStandings({required this.competitionId, required this.nom, this.saison, this.photo, required this.rows});

  factory CompetitionStandings.fromJson(Map<String, dynamic> j) => CompetitionStandings(
        competitionId: _i(j['id_competition']),
        nom: _s(j['nom']) ?? '',
        saison: _s(j['saison']),
        photo: _s(j['photo']),
        rows: _l(j['classement']).map(StandingRow.fromJson).toList(),
      );
}

/// Participant (officiel/personne rattachée) de la compétition.
class CompetitionParticipant {
  final int id;
  final String nom;
  final String prenoms;
  final String? avatar;
  final String? poste;
  final int? age;
  final int? liaisonId;

  const CompetitionParticipant({
    required this.id,
    required this.nom,
    required this.prenoms,
    this.avatar,
    this.poste,
    this.age,
    this.liaisonId,
  });

  String get fullName => '$nom $prenoms'.trim();

  factory CompetitionParticipant.fromJson(Map<String, dynamic> j) => CompetitionParticipant(
        id: _i(j['id']),
        nom: _s(j['nom']) ?? '',
        prenoms: _s(j['prenoms']) ?? '',
        avatar: _s(j['avatar']),
        poste: _s(j['poste']),
        age: j['age'] == null ? null : _i(j['age']),
        liaisonId: j['id_liaison'] == null ? null : _i(j['id_liaison']),
      );
}

/// Classement individuel (buteurs, passeurs, cartons).
class PlayerRank {
  final int playerId;
  final String name;
  final String? avatar;
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int buts;
  final int passes;
  final int cartonsJaunes;
  final int cartonsRouges;

  const PlayerRank({
    required this.playerId,
    required this.name,
    this.avatar,
    this.teamId = 0,
    this.teamName = '',
    this.teamLogo,
    this.buts = 0,
    this.passes = 0,
    this.cartonsJaunes = 0,
    this.cartonsRouges = 0,
  });

  factory PlayerRank.fromJson(Map<String, dynamic> j) {
    final p = _m(j['player']);
    final t = _m(j['team']);
    return PlayerRank(
      playerId: _i(p['id']),
      name: '${_s(p['nom']) ?? ''} ${_s(p['prenoms']) ?? ''}'.trim(),
      avatar: _s(p['avatar']),
      teamId: _i(t['id']),
      teamName: _s(t['nom']) ?? '',
      teamLogo: _s(t['logo']),
      buts: _i(j['buts']),
      passes: _i(j['passes']),
      cartonsJaunes: _i(j['CJ']),
      cartonsRouges: _i(j['CR']),
    );
  }
}

/// `GET /competitions/{id}/overview` — tout ce qu'il faut pour les cinq
/// onglets de compte/details-competition.php.
class CompetitionOverview {
  final Competition competition;
  final CompetitionStats stats;
  final double progression;
  final List<StandingRow> classement;
  final List<MatchGame> matchs;
  final List<MatchFieldRef> terrains;
  final List<CompetitionParticipant> participants;
  final List<PlayerRank> joueurs;
  final List<GamePlayerRef> followers;

  const CompetitionOverview({
    required this.competition,
    required this.stats,
    required this.progression,
    required this.classement,
    required this.matchs,
    required this.terrains,
    required this.participants,
    required this.joueurs,
    required this.followers,
  });

  factory CompetitionOverview.fromJson(Map<String, dynamic> j) => CompetitionOverview(
        competition: Competition.fromJson(_m(j['competition'])),
        stats: CompetitionStats.fromJson(_m(j['statistiques'])),
        progression: _d(j['progression']),
        classement: _l(j['classement']).map(StandingRow.fromJson).toList(),
        matchs: _l(j['matchs']).map(MatchGame.fromJson).toList(),
        terrains: _l(j['terrains']).map(MatchFieldRef.fromJson).toList(),
        participants: _l(j['participants']).map(CompetitionParticipant.fromJson).toList(),
        joueurs: _l(j['joueurs']).map(PlayerRank.fromJson).toList(),
        followers: _l(j['followers']).map(GamePlayerRef.fromJson).toList(),
      );
}

/// Une ressource rattachable à une compétition (joueur, équipe ou stade)
/// dans l'écran "Ajouter …".
class CompetitionResource {
  final int id;
  final String title;
  final String? subtitle;
  final String? image;
  final bool linked;

  const CompetitionResource({required this.id, required this.title, this.subtitle, this.image, required this.linked});

  CompetitionResource copyWith({bool? linked}) =>
      CompetitionResource(id: id, title: title, subtitle: subtitle, image: image, linked: linked ?? this.linked);
}

/// Paramètres du formulaire "Programmer plusieurs matchs".
class ScheduleParams {
  final List<String> jours;
  final String matin;
  final String midi;
  final String soir;
  final int matchsSemaine;
  final int foisJour;
  final String dateDebut;

  const ScheduleParams({
    required this.jours,
    required this.matin,
    required this.midi,
    required this.soir,
    required this.matchsSemaine,
    required this.foisJour,
    required this.dateDebut,
  });

  Map<String, dynamic> toJson() => {
        'jours_ouvrables': jours,
        'heures_preferables': {'matin': matin, 'midi': midi, 'soir': soir},
        'matchs_semaine': matchsSemaine,
        'fois_jour': foisJour,
        'date_debut': dateDebut,
      };
}

/// Fiche "sélections" d'une équipe dans une compétition
/// (`GET /competitions/{id}/teams/{teamId}/selections`).
class TeamSelectionInfo {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final String? teamLieu;
  final String responsable;
  final String? telephone;
  final String? email;
  final String competitionName;
  final bool selectionOpen;
  final bool isOwner;
  final List<TeamSelectionPlayer> players;

  const TeamSelectionInfo({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.teamLieu,
    required this.responsable,
    this.telephone,
    this.email,
    required this.competitionName,
    required this.selectionOpen,
    required this.isOwner,
    required this.players,
  });

  factory TeamSelectionInfo.fromJson(Map<String, dynamic> j) {
    final team = _m(j['team']);
    final resp = _m(j['responsable']);
    final comp = _m(j['competition']);
    return TeamSelectionInfo(
      teamId: _i(team['id']),
      teamName: _s(team['nom']) ?? '',
      teamLogo: _s(team['logo']),
      teamLieu: _s(team['lieu']),
      responsable: '${_s(resp['nom']) ?? ''} ${_s(resp['prenoms']) ?? ''}'.trim(),
      telephone: _s(resp['telephone']),
      email: _s(resp['email']),
      competitionName: _s(comp['nom']) ?? '',
      selectionOpen: _i(comp['selection']) != 0,
      isOwner: j['is_owner'] == true,
      players: _l(j['joueurs']).map(TeamSelectionPlayer.fromJson).toList(),
    );
  }
}

class TeamSelectionPlayer {
  final int id;
  final String name;
  final String? avatar;
  final String? poste;
  final int? age;
  final int statut;

  const TeamSelectionPlayer({required this.id, required this.name, this.avatar, this.poste, this.age, this.statut = 0});

  TeamSelectionPlayer copyWith({int? statut}) =>
      TeamSelectionPlayer(id: id, name: name, avatar: avatar, poste: poste, age: age, statut: statut ?? this.statut);

  factory TeamSelectionPlayer.fromJson(Map<String, dynamic> j) => TeamSelectionPlayer(
        id: _i(j['id']),
        name: '${_s(j['nom']) ?? ''} ${_s(j['prenoms']) ?? ''}'.trim(),
        avatar: _s(j['avatar']),
        poste: _s(j['poste']),
        age: j['age'] == null ? null : _i(j['age']),
        statut: _i(j['statut']),
      );
}
