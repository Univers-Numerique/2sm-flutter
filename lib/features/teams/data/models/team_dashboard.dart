import '../../../players/data/models/player.dart';

/// Payload of `GET /teams/{id}/dashboard` (Laravel addition mirroring the
/// legacy `tableauDeBord()` helper: stats, results per month, recent
/// matches, activities, tasks, category matrix, best performers).
class DashboardStats {
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int defeats;
  final int goalsScored;
  final int goalsConceded;
  final int shotsOnTarget;
  final int yellowCards;
  final int redCards;
  final int corners;
  final double averageGoals;
  final int points;

  const DashboardStats({
    this.matchesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.defeats = 0,
    this.goalsScored = 0,
    this.goalsConceded = 0,
    this.shotsOnTarget = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.corners = 0,
    this.averageGoals = 0,
    this.points = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
        matchesPlayed: asInt(j['matches_played']) ?? 0,
        wins: asInt(j['wins']) ?? 0,
        draws: asInt(j['draws']) ?? 0,
        defeats: asInt(j['defeats']) ?? 0,
        goalsScored: asInt(j['goals_scored']) ?? 0,
        goalsConceded: asInt(j['goals_conceded']) ?? 0,
        shotsOnTarget: asInt(j['shots_on_target']) ?? 0,
        yellowCards: asInt(j['yellow_cards']) ?? 0,
        redCards: asInt(j['red_cards']) ?? 0,
        corners: asInt(j['corners']) ?? 0,
        averageGoals: asDouble(j['average_goals']) ?? 0,
        points: asInt(j['points']) ?? 0,
      );
}

class MonthResult {
  final String month; // yyyy-MM
  final int wins;
  final int draws;
  final int defeats;
  final int matches;
  final int goals;
  const MonthResult({required this.month, this.wins = 0, this.draws = 0, this.defeats = 0, this.matches = 0, this.goals = 0});

  /// "sept.", "oct." ...
  String get shortLabel {
    const names = ['janv', 'févr', 'mars', 'avr', 'mai', 'juin', 'juil', 'août', 'sept', 'oct', 'nov', 'déc'];
    final m = int.tryParse(month.length >= 7 ? month.substring(5, 7) : '') ?? 1;
    return names[(m - 1).clamp(0, 11)];
  }

  factory MonthResult.fromJson(Map<String, dynamic> j) => MonthResult(
        month: asStr(j['month']) ?? '',
        wins: asInt(j['wins']) ?? 0,
        draws: asInt(j['draws']) ?? 0,
        defeats: asInt(j['defeats']) ?? 0,
        matches: asInt(j['matches']) ?? 0,
        goals: asInt(j['goals']) ?? 0,
      );
}

class MiniTeam {
  final int id;
  final String nom;
  final String? logo;
  const MiniTeam({required this.id, required this.nom, this.logo});

  factory MiniTeam.fromJson(Map<String, dynamic> j) =>
      MiniTeam(id: asInt(j['id']) ?? 0, nom: asStr(j['nom']) ?? '—', logo: asStr(j['logo']));
}

class RecentMatch {
  final int id;
  final int statut;
  final String? date;
  final String? heure;
  final MiniTeam? home;
  final MiniTeam? away;
  final int? homeGoals;
  final int? awayGoals;
  const RecentMatch({required this.id, this.statut = 0, this.date, this.heure, this.home, this.away, this.homeGoals, this.awayGoals});

  factory RecentMatch.fromJson(Map<String, dynamic> j) => RecentMatch(
        id: asInt(j['id']) ?? 0,
        statut: asInt(j['statut']) ?? 0,
        date: asStr(j['date_debut']),
        heure: asStr(j['heure_debut']),
        home: j['home'] is Map ? MiniTeam.fromJson(Map<String, dynamic>.from(j['home'] as Map)) : null,
        away: j['away'] is Map ? MiniTeam.fromJson(Map<String, dynamic>.from(j['away'] as Map)) : null,
        homeGoals: asInt(j['home_goals']),
        awayGoals: asInt(j['away_goals']),
      );
}

class DashboardActivity {
  final int id;
  final String titre;
  final String? lieu;
  final String? date;
  final String? heure;
  final int statut;
  const DashboardActivity({required this.id, required this.titre, this.lieu, this.date, this.heure, this.statut = 0});

  factory DashboardActivity.fromJson(Map<String, dynamic> j) => DashboardActivity(
        id: asInt(j['id']) ?? 0,
        titre: asStr(j['titre']) ?? '',
        lieu: asStr(j['lieu']),
        date: asStr(j['date']),
        heure: asStr(j['heure']),
        statut: asInt(j['statut']) ?? 0,
      );
}

class DashboardTask {
  final int id;
  final String tache;
  final int statut;
  final String? author;
  final String? createdAt;
  const DashboardTask({required this.id, required this.tache, this.statut = 0, this.author, this.createdAt});

  factory DashboardTask.fromJson(Map<String, dynamic> j) {
    final o = j['owner'] is Map ? Map<String, dynamic>.from(j['owner'] as Map) : null;
    final author = o == null ? null : [o['prenoms'], o['nom']].where((e) => e != null && '$e'.isNotEmpty).join(' ');
    return DashboardTask(
      id: asInt(j['id']) ?? 0,
      tache: asStr(j['tache']) ?? '',
      statut: asInt(j['statut']) ?? 0,
      author: author,
      createdAt: asStr(j['created_at']),
    );
  }
}

class TopPerformer {
  final int id;
  final String fullName;
  final String? avatar;
  final int? age;
  final double average;
  const TopPerformer({required this.id, required this.fullName, this.avatar, this.age, required this.average});

  factory TopPerformer.fromJson(Map<String, dynamic> j) {
    final name = [j['prenoms'], j['nom']].where((e) => e != null && '$e'.isNotEmpty).join(' ');
    final dob = asStr(j['date_de_naissance']);
    int? age;
    if (dob != null) {
      final d = DateTime.tryParse(dob);
      if (d != null) {
        final n = DateTime.now();
        age = n.year - d.year - ((n.month < d.month || (n.month == d.month && n.day < d.day)) ? 1 : 0);
      }
    }
    return TopPerformer(id: asInt(j['id']) ?? 0, fullName: name, avatar: asStr(j['avatar']), age: age, average: asDouble(j['moyenne']) ?? 0);
  }
}

class TeamDashboard {
  final DashboardStats stats;
  final List<MonthResult> months;
  final List<RecentMatch> recentMatches;
  final int activitiesFinished;
  final int activitiesOngoing;
  final List<DashboardActivity> activities;
  final List<DashboardTask> tasks;
  final Map<String, Map<String, int>> categoryMatrix; // genre -> catégorie -> n
  final List<TopPerformer> topPerformers;

  const TeamDashboard({
    required this.stats,
    this.months = const [],
    this.recentMatches = const [],
    this.activitiesFinished = 0,
    this.activitiesOngoing = 0,
    this.activities = const [],
    this.tasks = const [],
    this.categoryMatrix = const {},
    this.topPerformers = const [],
  });

  factory TeamDashboard.fromJson(Map<String, dynamic> j) {
    final act = j['activities'] is Map ? Map<String, dynamic>.from(j['activities'] as Map) : <String, dynamic>{};
    final matrix = <String, Map<String, int>>{};
    final rawMatrix = j['category_matrix'];
    if (rawMatrix is Map) {
      rawMatrix.forEach((genre, cats) {
        if (cats is Map) matrix['$genre'] = cats.map((k, v) => MapEntry('$k', asInt(v) ?? 0));
      });
    }
    List<T> list<T>(dynamic raw, T Function(Map<String, dynamic>) f) =>
        raw is List ? raw.map((e) => f(Map<String, dynamic>.from(e as Map))).toList() : <T>[];
    return TeamDashboard(
      stats: DashboardStats.fromJson(Map<String, dynamic>.from((j['statistics'] as Map?) ?? const {})),
      months: list(j['results_by_month'], MonthResult.fromJson),
      recentMatches: list(j['recent_matches'], RecentMatch.fromJson),
      activitiesFinished: asInt(act['finished']) ?? 0,
      activitiesOngoing: asInt(act['ongoing']) ?? 0,
      activities: list(act['items'], DashboardActivity.fromJson),
      tasks: list(j['tasks'], DashboardTask.fromJson),
      categoryMatrix: matrix,
      topPerformers: list(j['top_performers'], TopPerformer.fromJson),
    );
  }
}
