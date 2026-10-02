import 'package:json_annotation/json_annotation.dart';

part 'competition_ranking.g.dart';

/// One row of `GET /competitions/{id}/rankings`, computed server-side from
/// `Score`. The endpoint is owner/admin-gated, so its exact field names
/// couldn't be verified against a live response while building this screen
/// (the test account isn't a competition owner) — parsing is deliberately
/// defensive: several plausible French key spellings are tried for the
/// team's nested identity and stats fall back to 0 rather than throwing.
@JsonSerializable()
class CompetitionRanking {
  @JsonKey(defaultValue: 0)
  final int rang;
  @JsonKey(name: 'id_equipe', readValue: _readTeamId)
  final int teamId;
  @JsonKey(name: 'nom_equipe', readValue: _readTeamNom, defaultValue: '')
  final String teamNom;
  @JsonKey(name: 'logo_equipe', readValue: _readTeamLogo)
  final String? teamLogo;
  @JsonKey(name: 'matchs_joues', readValue: _readMatchsJoues, defaultValue: 0)
  final int matchsJoues;
  @JsonKey(readValue: _readVictoires, defaultValue: 0)
  final int victoires;
  @JsonKey(readValue: _readNuls, defaultValue: 0)
  final int nuls;
  @JsonKey(readValue: _readDefaites, defaultValue: 0)
  final int defaites;
  @JsonKey(name: 'buts_pour', readValue: _readButsPour, defaultValue: 0)
  final int butsPour;
  @JsonKey(name: 'buts_contre', readValue: _readButsContre, defaultValue: 0)
  final int butsContre;
  @JsonKey(defaultValue: 0)
  final int points;

  const CompetitionRanking({
    this.rang = 0,
    required this.teamId,
    this.teamNom = '',
    this.teamLogo,
    this.matchsJoues = 0,
    this.victoires = 0,
    this.nuls = 0,
    this.defaites = 0,
    this.butsPour = 0,
    this.butsContre = 0,
    this.points = 0,
  });

  int get diffButs => butsPour - butsContre;

  static Map? _equipe(Map json) => json['equipe'] is Map ? json['equipe'] as Map : null;

  static Object? _readTeamId(Map json, String key) =>
      _equipe(json)?['id'] ?? json[key] ?? json['team_id'] ?? json['id_team'] ?? 0;

  static Object? _readTeamNom(Map json, String key) =>
      _equipe(json)?['nom'] ?? json[key] ?? json['equipe'] ?? json['team_nom'] ?? json['nom'] ?? '';

  static Object? _readTeamLogo(Map json, String key) => _equipe(json)?['logo'] ?? json[key] ?? json['team_logo'];

  static Object? _readMatchsJoues(Map json, String key) =>
      json[key] ?? json['matches_played'] ?? json['joues'] ?? json['j'];

  static Object? _readVictoires(Map json, String key) => json[key] ?? json['wins'] ?? json['v'];

  static Object? _readNuls(Map json, String key) => json[key] ?? json['draws'] ?? json['n'];

  static Object? _readDefaites(Map json, String key) => json[key] ?? json['defeats'] ?? json['losses'] ?? json['d'];

  static Object? _readButsPour(Map json, String key) => json[key] ?? json['goals_for'] ?? json['bp'];

  static Object? _readButsContre(Map json, String key) => json[key] ?? json['goals_against'] ?? json['bc'];

  factory CompetitionRanking.fromJson(Map<String, dynamic> json) => _$CompetitionRankingFromJson(json);
  Map<String, dynamic> toJson() => _$CompetitionRankingToJson(this);
}
