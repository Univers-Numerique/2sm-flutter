/// Helpers for lenient JSON parsing (Laravel returns decimals as strings or
/// numbers depending on the cast).
int? asInt(dynamic v) => v == null ? null : (v is int ? v : (v is num ? v.toInt() : int.tryParse('$v')));
double? asDouble(dynamic v) => v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
String? asStr(dynamic v) {
  if (v == null) return null;
  final s = '$v';
  return s.isEmpty ? null : s;
}

/// A row of `postes` (a user's role within a team) with the team summary
/// the API embeds under `team`.
class PlayerPosition {
  final int id;
  final int userId;
  final int? teamId;
  final String? poste;
  final String? categorie;
  final String? type;
  final String? piedFort;
  final String? numeroDeMaillot;
  final double? taille;
  final double? poids;
  final String? nationalite;
  final int statut;
  final String? teamName;
  final String? teamLogo;
  final String? createdAt;

  const PlayerPosition({
    required this.id,
    required this.userId,
    this.teamId,
    this.poste,
    this.categorie,
    this.type,
    this.piedFort,
    this.numeroDeMaillot,
    this.taille,
    this.poids,
    this.nationalite,
    this.statut = 1,
    this.teamName,
    this.teamLogo,
    this.createdAt,
  });

  factory PlayerPosition.fromJson(Map<String, dynamic> j) {
    final team = j['team'] is Map ? Map<String, dynamic>.from(j['team'] as Map) : null;
    return PlayerPosition(
      id: asInt(j['id']) ?? 0,
      userId: asInt(j['id_utilisateur']) ?? 0,
      teamId: asInt(j['id_equipe']),
      poste: asStr(j['poste']),
      categorie: asStr(j['categorie']),
      type: asStr(j['type']),
      piedFort: asStr(j['pied_fort']),
      numeroDeMaillot: asStr(j['numero_de_maillot']),
      taille: asDouble(j['taille']),
      poids: asDouble(j['poids']),
      nationalite: asStr(j['nationalite']),
      statut: asInt(j['statut']) ?? 1,
      teamName: asStr(team?['nom']),
      teamLogo: asStr(team?['logo']),
      createdAt: asStr(j['created_at']),
    );
  }
}

/// Full user record as returned by `GET /users`, `GET /users/{id}` and the
/// `users` embedded in `GET /teams/{id}/members`.
class PlayerUser {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? email;
  final String? telephone;
  final String? avatar;
  final String? dateDeNaissance;
  final String? genre;
  final String? profession;
  final String? adresse;
  final String? biographie;
  final String? citation;
  final String? pays;
  final String? ville;
  final int statut;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  final String? dateInscription;
  final List<PlayerPosition> positions;

  const PlayerUser({
    required this.id,
    this.nom,
    this.prenoms,
    this.email,
    this.telephone,
    this.avatar,
    this.dateDeNaissance,
    this.genre,
    this.profession,
    this.adresse,
    this.biographie,
    this.citation,
    this.pays,
    this.ville,
    this.statut = 1,
    this.facebook,
    this.instagram,
    this.twitter,
    this.linkedin,
    this.dateInscription,
    this.positions = const [],
  });

  String get fullName {
    final n = [nom, prenoms].where((s) => s != null && s.isNotEmpty).join(' ');
    return n.isEmpty ? (email ?? 'Utilisateur') : n;
  }

  int? get age => _age(dateDeNaissance);

  /// Main position (first active one) — used by directory rows.
  PlayerPosition? get mainPosition {
    for (final p in positions) {
      if (p.statut == 1) return p;
    }
    return positions.isEmpty ? null : positions.first;
  }

  bool get hasSocials => [facebook, instagram, twitter, linkedin].any((s) => s != null && s.isNotEmpty);

  factory PlayerUser.fromJson(Map<String, dynamic> j) {
    final rawPositions = j['positions'];
    return PlayerUser(
      id: asInt(j['id']) ?? 0,
      nom: asStr(j['nom']),
      prenoms: asStr(j['prenoms']),
      email: asStr(j['email']),
      telephone: asStr(j['telephone']),
      avatar: asStr(j['avatar']),
      dateDeNaissance: asStr(j['date_de_naissance']),
      genre: asStr(j['genre']),
      profession: asStr(j['profession']),
      adresse: asStr(j['adresse']),
      biographie: asStr(j['biographie']),
      citation: asStr(j['citation']),
      pays: asStr(j['pays']),
      ville: asStr(j['ville']),
      statut: asInt(j['statut']) ?? 1,
      facebook: asStr(j['facebook']),
      instagram: asStr(j['instagram']),
      twitter: asStr(j['twitter']),
      linkedin: asStr(j['linkedin']),
      dateInscription: asStr(j['date_inscription']) ?? asStr(j['created_at']),
      positions: rawPositions is List
          ? rawPositions.map((e) => PlayerPosition.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : const [],
    );
  }
}

int? _age(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;
  final now = DateTime.now();
  var age = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
  return age < 0 ? null : age;
}

/// One page of `GET /users`.
class UserPage {
  final List<PlayerUser> users;
  final int currentPage;
  final int lastPage;
  final int total;
  const UserPage({required this.users, required this.currentPage, required this.lastPage, required this.total});

  factory UserPage.fromJson(Map<String, dynamic> j) => UserPage(
        users: ((j['data'] as List?) ?? const [])
            .map((e) => PlayerUser.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        currentPage: asInt(j['current_page']) ?? 1,
        lastPage: asInt(j['last_page']) ?? 1,
        total: asInt(j['total']) ?? 0,
      );
}

/// Latest value (0-100) of a skill (`performences` row).
class Skill {
  final int id;
  final int? userId;
  final int? teamId;
  final int? activityId;
  final String performance;
  final double valeur;
  final String? categorie;
  final String? type;
  final String? createdAt;

  const Skill({
    required this.id,
    this.userId,
    this.teamId,
    this.activityId,
    required this.performance,
    required this.valeur,
    this.categorie,
    this.type,
    this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
        id: asInt(j['id']) ?? 0,
        userId: asInt(j['id_utilisateur']),
        teamId: asInt(j['id_equipe']),
        activityId: asInt(j['id_activite']),
        performance: asStr(j['performance']) ?? '',
        valeur: asDouble(j['valeur']) ?? 0,
        categorie: asStr(j['categorie']),
        type: asStr(j['type']),
        createdAt: asStr(j['created_at']),
      );
}

class GameEventItem {
  final int id;
  final int? matchId;
  final String jeu;
  final String? temps;
  final int statut;
  final String? teamName;
  final String? teamLogo;
  final String? createdAt;

  const GameEventItem({
    required this.id,
    this.matchId,
    required this.jeu,
    this.temps,
    this.statut = 1,
    this.teamName,
    this.teamLogo,
    this.createdAt,
  });

  factory GameEventItem.fromJson(Map<String, dynamic> j) {
    final team = j['team'] is Map ? Map<String, dynamic>.from(j['team'] as Map) : null;
    return GameEventItem(
      id: asInt(j['id']) ?? 0,
      matchId: asInt(j['id_match']),
      jeu: asStr(j['jeu']) ?? '',
      temps: asStr(j['temps']),
      statut: asInt(j['statut']) ?? 1,
      teamName: asStr(team?['nom']),
      teamLogo: asStr(team?['logo']),
      createdAt: asStr(j['created_at']),
    );
  }
}

/// `GET /users/{id}/statistics`
class UserStats {
  final int totalGoals;
  final int totalMatches;
  final int teamsCount;
  final Map<String, int> eventsByType;
  final List<GameEventItem> recentEvents;
  final List<Skill> skills;

  const UserStats({
    this.totalGoals = 0,
    this.totalMatches = 0,
    this.teamsCount = 0,
    this.eventsByType = const {},
    this.recentEvents = const [],
    this.skills = const [],
  });

  List<Skill> skillsOfType(String type) => skills.where((s) => s.type == type).toList();

  factory UserStats.fromJson(Map<String, dynamic> j) {
    final byType = j['events_by_type'];
    return UserStats(
      totalGoals: asInt(j['total_goals']) ?? 0,
      totalMatches: asInt(j['total_matches']) ?? 0,
      teamsCount: asInt(j['teams_count']) ?? 0,
      eventsByType: byType is Map ? byType.map((k, v) => MapEntry('$k', asInt(v) ?? 0)) : const {},
      recentEvents: ((j['recent_events'] as List?) ?? const [])
          .map((e) => GameEventItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      skills: ((j['skills'] as List?) ?? const [])
          .map((e) => Skill.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
