import '../../../players/data/models/player.dart';
import 'team_member.dart';

/// `statistics` block of `GET /teams/{id}`.
class TeamStatistics {
  final int totalMatches;
  final int wins;
  final int draws;
  final int defeats;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final int membersCount;

  const TeamStatistics({
    this.totalMatches = 0,
    this.wins = 0,
    this.draws = 0,
    this.defeats = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
    this.membersCount = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  factory TeamStatistics.fromJson(Map<String, dynamic> j) => TeamStatistics(
        totalMatches: asInt(j['total_matches']) ?? 0,
        wins: asInt(j['wins']) ?? 0,
        draws: asInt(j['draws']) ?? 0,
        defeats: asInt(j['defeats']) ?? 0,
        goalsFor: asInt(j['goals_scored'] ?? j['goals_for']) ?? 0,
        goalsAgainst: asInt(j['goals_conceded'] ?? j['goals_against']) ?? 0,
        points: asInt(j['points']) ?? 0,
        membersCount: asInt(j['members_count']) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'total_matches': totalMatches,
        'wins': wins,
        'draws': draws,
        'defeats': defeats,
        'goals_scored': goalsFor,
        'goals_conceded': goalsAgainst,
        'points': points,
        'members_count': membersCount,
      };
}

class TeamOwner {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;
  final String? email;
  const TeamOwner({required this.id, this.nom, this.prenoms, this.avatar, this.email});

  String get fullName => [nom, prenoms].where((s) => s != null && s.isNotEmpty).join(' ');

  factory TeamOwner.fromJson(Map<String, dynamic> j) => TeamOwner(
        id: asInt(j['id']) ?? 0,
        nom: asStr(j['nom']),
        prenoms: asStr(j['prenoms']),
        avatar: asStr(j['avatar']),
        email: asStr(j['email']),
      );

  Map<String, dynamic> toJson() => {'id': id, 'nom': nom, 'prenoms': prenoms, 'avatar': avatar, 'email': email};
}

class TeamCompetition {
  final int id;
  final String nom;
  final String? photo;
  final String? saison;
  final String? categorie;
  final int statut;
  const TeamCompetition({required this.id, required this.nom, this.photo, this.saison, this.categorie, this.statut = 1});

  factory TeamCompetition.fromJson(Map<String, dynamic> j) => TeamCompetition(
        id: asInt(j['id']) ?? 0,
        nom: asStr(j['nom']) ?? '',
        photo: asStr(j['photo']),
        saison: asStr(j['saison']),
        categorie: asStr(j['categorie']),
        statut: asInt(j['statut']) ?? 1,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'nom': nom, 'photo': photo, 'saison': saison, 'categorie': categorie, 'statut': statut};
}

class Team {
  final int id;
  final int ownerId;
  final String nom;
  final String? lieu;
  final String? logo;
  final int statut;
  final int? membersCount;
  final TeamStatistics? statistics;
  final TeamOwner? owner;
  final List<TeamMember> members;
  final List<TeamCompetition> competitions;
  final String? createdAt;
  final String? updatedAt;

  const Team({
    required this.id,
    required this.ownerId,
    required this.nom,
    this.lieu,
    this.logo,
    this.statut = 1,
    this.membersCount,
    this.statistics,
    this.owner,
    this.members = const [],
    this.competitions = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// True when [userId] is this team's manager and may see/perform the
  /// management actions that PHP split across a separate `manage/equipes/*`
  /// console — here they're just conditionally shown on the same screen.
  bool isManagedBy(int userId) => ownerId == userId;

  bool hasMember(int userId) => members.any((m) => m.userId == userId);

  factory Team.fromJson(Map<String, dynamic> json) {
    final id = asInt(json['id']) ?? 0;
    return Team(
      id: id,
      ownerId: asInt(json['id_utilisateur']) ?? 0,
      nom: asStr(json['nom']) ?? '',
      lieu: asStr(json['lieu']),
      logo: asStr(json['logo']),
      statut: asInt(json['statut']) ?? 1,
      membersCount: asInt(json['members_count']),
      statistics: json['statistics'] is Map ? TeamStatistics.fromJson(Map<String, dynamic>.from(json['statistics'] as Map)) : null,
      owner: json['owner'] is Map ? TeamOwner.fromJson(Map<String, dynamic>.from(json['owner'] as Map)) : null,
      members: json['members'] is List
          ? (json['members'] as List).map((e) => TeamMember.fromJson(Map<String, dynamic>.from(e as Map), teamId: id)).toList()
          : const [],
      competitions: json['competitions'] is List
          ? (json['competitions'] as List).map((e) => TeamCompetition.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : const [],
      createdAt: asStr(json['created_at']),
      updatedAt: asStr(json['updated_at']),
    );
  }

  /// Light serialization used for the local cache (the members list is not
  /// persisted — it is always re-fetched with the detail).
  Map<String, dynamic> toJson() => {
        'id': id,
        'id_utilisateur': ownerId,
        'nom': nom,
        'lieu': lieu,
        'logo': logo,
        'statut': statut,
        'members_count': membersCount,
        'statistics': statistics?.toJson(),
        'owner': owner?.toJson(),
        'competitions': competitions.map((c) => c.toJson()).toList(),
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
