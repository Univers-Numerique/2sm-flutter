import '../../../media/data/models/media_item.dart';
import 'match_game.dart';

int _i(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _d(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

Map<String, dynamic> _m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _l(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

/// Officiels affichés sur la fiche du match (noms résolus côté serveur).
class MatchOfficials {
  final String? arbitrePrincipal;
  final String? arbitreTouche1;
  final String? arbitreTouche2;
  final String? commentateur1;
  final String? commentateur2;
  final String? chronometreur;
  final String? annonciateur;

  const MatchOfficials({
    this.arbitrePrincipal,
    this.arbitreTouche1,
    this.arbitreTouche2,
    this.commentateur1,
    this.commentateur2,
    this.chronometreur,
    this.annonciateur,
  });

  factory MatchOfficials.fromJson(Map<String, dynamic> j) => MatchOfficials(
        arbitrePrincipal: j['arbitre_principal'] as String?,
        arbitreTouche1: j['arbitre_touche_1'] as String?,
        arbitreTouche2: j['arbitre_touche_2'] as String?,
        commentateur1: j['commentateur_1'] as String?,
        commentateur2: j['commentateur_2'] as String?,
        chronometreur: j['chronometreur'] as String?,
        annonciateur: j['annonciateur_public'] as String?,
      );
}

/// Ligne du classement des joueurs du match.
class MatchPlayerRank {
  final int playerId;
  final String name;
  final String? avatar;
  final String teamName;
  final String? teamLogo;
  final int buts;
  final int passes;
  final int cartonsJaunes;
  final int cartonsRouges;

  const MatchPlayerRank({
    required this.playerId,
    required this.name,
    this.avatar,
    this.teamName = '',
    this.teamLogo,
    this.buts = 0,
    this.passes = 0,
    this.cartonsJaunes = 0,
    this.cartonsRouges = 0,
  });

  factory MatchPlayerRank.fromJson(Map<String, dynamic> j) {
    final p = _m(j['player']);
    final t = _m(j['team']);
    return MatchPlayerRank(
      playerId: _i(p['id']),
      name: '${p['nom'] ?? ''} ${p['prenoms'] ?? ''}'.trim(),
      avatar: p['avatar'] as String?,
      teamName: (t['nom'] as String?) ?? '',
      teamLogo: t['logo'] as String?,
      buts: _i(j['buts']),
      passes: _i(j['passes']),
      cartonsJaunes: _i(j['CJ']),
      cartonsRouges: _i(j['CR']),
    );
  }
}

/// Joueur d'un onglet "Les sélections" (statut 1 = convoqué).
class SelectedPlayer {
  final int id;
  final String name;
  final String? avatar;
  final String? poste;
  final int? age;
  final int statut;

  const SelectedPlayer({required this.id, required this.name, this.avatar, this.poste, this.age, this.statut = 0});

  SelectedPlayer copyWith({int? statut}) =>
      SelectedPlayer(id: id, name: name, avatar: avatar, poste: poste, age: age, statut: statut ?? this.statut);

  factory SelectedPlayer.fromJson(Map<String, dynamic> j) => SelectedPlayer(
        id: _i(j['id']),
        name: '${j['nom'] ?? ''} ${j['prenoms'] ?? ''}'.trim(),
        avatar: j['avatar'] as String?,
        poste: j['poste'] as String?,
        age: j['age'] == null ? null : _i(j['age']),
        statut: _i(j['statut']),
      );
}

/// `GET /matches/{id}/overview`.
class MatchOverview {
  final MatchGame match;
  final List<GameEvent> events;
  final MatchOfficials officials;
  final Map<String, int> homeStats;
  final Map<String, int> awayStats;
  final double homePossession;
  final double awayPossession;
  final List<GamePlayerRef> homeScorers;
  final List<GamePlayerRef> awayScorers;
  final List<MatchPlayerRank> ranking;
  final List<MediaItem> medias;
  final List<SelectedPlayer> homeSelection;
  final List<SelectedPlayer> awaySelection;

  const MatchOverview({
    required this.match,
    required this.events,
    required this.officials,
    required this.homeStats,
    required this.awayStats,
    required this.homePossession,
    required this.awayPossession,
    required this.homeScorers,
    required this.awayScorers,
    required this.ranking,
    required this.medias,
    required this.homeSelection,
    required this.awaySelection,
  });

  static Map<String, int> _stats(Object? v) => _m(v).map((k, val) => MapEntry(k, _i(val)));

  factory MatchOverview.fromJson(Map<String, dynamic> j) => MatchOverview(
        match: MatchGame.fromJson(_m(j['match'])),
        events: _l(j['evenements']).map(GameEvent.fromJson).toList(),
        officials: MatchOfficials.fromJson(_m(j['officiels'])),
        homeStats: _stats(j['stats_domicile']),
        awayStats: _stats(j['stats_exterieur']),
        homePossession: _d(j['possession_domicile']),
        awayPossession: _d(j['possession_exterieur']),
        homeScorers: _l(j['buteurs_domicile']).map(GamePlayerRef.fromJson).toList(),
        awayScorers: _l(j['buteurs_exterieur']).map(GamePlayerRef.fromJson).toList(),
        ranking: _l(j['classements']).map(MatchPlayerRank.fromJson).toList(),
        medias: _l(j['medias']).map(MediaItem.fromJson).toList(),
        homeSelection: _l(j['selection_domicile']).map(SelectedPlayer.fromJson).toList(),
        awaySelection: _l(j['selection_exterieur']).map(SelectedPlayer.fromJson).toList(),
      );
}
