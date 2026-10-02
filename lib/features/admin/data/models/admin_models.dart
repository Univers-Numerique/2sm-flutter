import 'package:json_annotation/json_annotation.dart';

part 'admin_models.g.dart';

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? double.tryParse('$v')?.toInt() ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse('$v');
}

/// One page of a Laravel `paginate()` response, whatever the row type.
class PagedResult<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  const PagedResult({
    required this.data,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 20,
  });

  factory PagedResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    final list = (json['data'] as List<dynamic>? ?? const []).map((e) => parse(e as Map<String, dynamic>)).toList();
    return PagedResult(
      data: list,
      currentPage: _toInt(json['current_page'] ?? 1),
      lastPage: _toInt(json['last_page'] ?? 1),
      total: json['total'] == null ? list.length : _toInt(json['total']),
      perPage: json['per_page'] == null ? list.length : _toInt(json['per_page']),
    );
  }
}

@JsonSerializable()
class AdminOwnerRef {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;

  const AdminOwnerRef({required this.id, this.nom, this.prenoms, this.avatar});

  String get fullName => [nom, prenoms].where((s) => s != null && s.isNotEmpty).join(' ');

  factory AdminOwnerRef.fromJson(Map<String, dynamic> json) => _$AdminOwnerRefFromJson(json);
  Map<String, dynamic> toJson() => _$AdminOwnerRefToJson(this);
}

/// A row of `GET /admin/users` (legacy `admin/utilisateurs.php`): the user
/// plus the active position (poste, catégorie, équipe) and computed age.
@JsonSerializable()
class AdminUserRow {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? email;
  final String? telephone;
  final String? avatar;
  final String? genre;
  @JsonKey(defaultValue: 1)
  final int statut;
  @JsonKey(name: 'is_blocked', defaultValue: false)
  final bool isBlocked;
  @JsonKey(name: 'is_admin', defaultValue: false)
  final bool isAdmin;
  final String? poste;
  final String? categorie;
  final String? equipe;
  @JsonKey(name: 'id_equipe')
  final int? teamId;
  final int? age;
  @JsonKey(name: 'date_inscription')
  final String? dateInscription;

  const AdminUserRow({
    required this.id,
    this.nom,
    this.prenoms,
    this.email,
    this.telephone,
    this.avatar,
    this.genre,
    this.statut = 1,
    this.isBlocked = false,
    this.isAdmin = false,
    this.poste,
    this.categorie,
    this.equipe,
    this.teamId,
    this.age,
    this.dateInscription,
  });

  String get fullName => [nom, prenoms].where((s) => s != null && s.isNotEmpty).join(' ');

  factory AdminUserRow.fromJson(Map<String, dynamic> json) => _$AdminUserRowFromJson(json);
  Map<String, dynamic> toJson() => _$AdminUserRowToJson(this);
}

/// A row of `GET /admin/teams` (legacy `admin/equipes.php`).
@JsonSerializable(explicitToJson: true)
class AdminTeamRow {
  final int id;
  final String nom;
  final String? lieu;
  final String? logo;
  @JsonKey(defaultValue: 1)
  final int statut;
  @JsonKey(name: 'members_count', defaultValue: 0)
  final int membersCount;
  final AdminOwnerRef? owner;

  const AdminTeamRow({
    required this.id,
    required this.nom,
    this.lieu,
    this.logo,
    this.statut = 1,
    this.membersCount = 0,
    this.owner,
  });

  factory AdminTeamRow.fromJson(Map<String, dynamic> json) => _$AdminTeamRowFromJson(json);
  Map<String, dynamic> toJson() => _$AdminTeamRowToJson(this);
}

/// A row of `GET /admin/competitions` (legacy `admin/competitions.php`).
@JsonSerializable(explicitToJson: true)
class AdminCompetitionRow {
  final int id;
  final String nom;
  final String? description;
  final String? categorie;
  final String? genre;
  final String? saison;
  @JsonKey(name: 'date_debut')
  final String? dateDebut;
  @JsonKey(name: 'heure_debut')
  final String? heureDebut;
  @JsonKey(defaultValue: 0)
  final int statut;
  final String? photo;
  @JsonKey(fromJson: _toDouble)
  final double progression;
  @JsonKey(name: 'nom_terrain')
  final String? nomTerrain;
  @JsonKey(name: 'matches_count', defaultValue: 0)
  final int matchesCount;
  @JsonKey(name: 'matches_finished_count', defaultValue: 0)
  final int matchesFinishedCount;
  final AdminOwnerRef? owner;

  const AdminCompetitionRow({
    required this.id,
    required this.nom,
    this.description,
    this.categorie,
    this.genre,
    this.saison,
    this.dateDebut,
    this.heureDebut,
    this.statut = 0,
    this.photo,
    this.progression = 0,
    this.nomTerrain,
    this.matchesCount = 0,
    this.matchesFinishedCount = 0,
    this.owner,
  });

  factory AdminCompetitionRow.fromJson(Map<String, dynamic> json) => _$AdminCompetitionRowFromJson(json);
  Map<String, dynamic> toJson() => _$AdminCompetitionRowToJson(this);
}

/// A row of `GET /admin/fields` (legacy `admin/terrains.php`).
@JsonSerializable(explicitToJson: true)
class AdminFieldRow {
  final int id;
  @JsonKey(name: 'nom_terrain')
  final String nomTerrain;
  final String? lieu;
  @JsonKey(fromJson: _toDoubleOrNull)
  final double? latitude;
  @JsonKey(fromJson: _toDoubleOrNull)
  final double? longitude;
  final String? photo;
  @JsonKey(defaultValue: 1)
  final int statut;
  final AdminOwnerRef? owner;

  const AdminFieldRow({
    required this.id,
    required this.nomTerrain,
    this.lieu,
    this.latitude,
    this.longitude,
    this.photo,
    this.statut = 1,
    this.owner,
  });

  /// Same target as the legacy "Localiser le terrain" button.
  String get mapsUrl {
    if (latitude != null && longitude != null) return 'https://www.google.com/maps?q=$latitude,$longitude';
    final q = Uri.encodeComponent(lieu?.isNotEmpty == true ? lieu! : nomTerrain);
    return 'https://www.google.com/maps?q=$q';
  }

  factory AdminFieldRow.fromJson(Map<String, dynamic> json) => _$AdminFieldRowFromJson(json);
  Map<String, dynamic> toJson() => _$AdminFieldRowToJson(this);
}

// ---------------------------------------------------------------------------
// Dashboard (`GET /admin/dashboard`)
// ---------------------------------------------------------------------------

@JsonSerializable()
class DashboardCounts {
  @JsonKey(fromJson: _toInt)
  final int users;
  @JsonKey(fromJson: _toInt)
  final int teams;
  @JsonKey(fromJson: _toInt)
  final int fields;
  @JsonKey(fromJson: _toInt)
  final int competitions;
  @JsonKey(fromJson: _toInt)
  final int matches;
  @JsonKey(name: 'matches_played', fromJson: _toInt)
  final int matchesPlayed;
  @JsonKey(fromJson: _toInt)
  final int activities;
  @JsonKey(fromJson: _toInt)
  final int goals;
  @JsonKey(name: 'matches_today', fromJson: _toInt)
  final int matchesToday;
  @JsonKey(name: 'new_users_this_month', fromJson: _toInt)
  final int newUsersThisMonth;

  const DashboardCounts({
    this.users = 0,
    this.teams = 0,
    this.fields = 0,
    this.competitions = 0,
    this.matches = 0,
    this.matchesPlayed = 0,
    this.activities = 0,
    this.goals = 0,
    this.matchesToday = 0,
    this.newUsersThisMonth = 0,
  });

  factory DashboardCounts.fromJson(Map<String, dynamic> json) => _$DashboardCountsFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardCountsToJson(this);
}

@JsonSerializable()
class MonthlyResult {
  final String month;
  @JsonKey(name: 'home_wins', fromJson: _toInt)
  final int homeWins;
  @JsonKey(fromJson: _toInt)
  final int draws;
  @JsonKey(name: 'away_wins', fromJson: _toInt)
  final int awayWins;
  @JsonKey(fromJson: _toInt)
  final int goals;
  @JsonKey(fromJson: _toInt)
  final int matches;

  const MonthlyResult({
    required this.month,
    this.homeWins = 0,
    this.draws = 0,
    this.awayWins = 0,
    this.goals = 0,
    this.matches = 0,
  });

  factory MonthlyResult.fromJson(Map<String, dynamic> json) => _$MonthlyResultFromJson(json);
  Map<String, dynamic> toJson() => _$MonthlyResultToJson(this);
}

@JsonSerializable()
class WeekCount {
  @JsonKey(fromJson: _toInt)
  final int week;
  @JsonKey(fromJson: _toInt)
  final int matches;

  const WeekCount({this.week = 0, this.matches = 0});

  factory WeekCount.fromJson(Map<String, dynamic> json) => _$WeekCountFromJson(json);
  Map<String, dynamic> toJson() => _$WeekCountToJson(this);
}

@JsonSerializable()
class DashboardManager {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;
  final String? genre;
  @JsonKey(name: 'date_de_naissance')
  final String? dateDeNaissance;
  final String? telephone;
  final String? poste;
  final String? equipe;
  final String? depuis;

  const DashboardManager({
    required this.id,
    this.nom,
    this.prenoms,
    this.avatar,
    this.genre,
    this.dateDeNaissance,
    this.telephone,
    this.poste,
    this.equipe,
    this.depuis,
  });

  String get fullName => [nom, prenoms].where((s) => s != null && s.isNotEmpty).join(' ');

  factory DashboardManager.fromJson(Map<String, dynamic> json) => _$DashboardManagerFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardManagerToJson(this);
}

@JsonSerializable()
class DashboardEvent {
  final int id;
  final String? home;
  final String? away;
  final String? date;
  final String? heure;
  @JsonKey(defaultValue: 0)
  final int statut;

  const DashboardEvent({required this.id, this.home, this.away, this.date, this.heure, this.statut = 0});

  factory DashboardEvent.fromJson(Map<String, dynamic> json) => _$DashboardEventFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardEventToJson(this);
}

@JsonSerializable()
class DashboardActivity {
  final int id;
  final String titre;
  final String? lieu;
  final String? date;
  final String? heure;
  @JsonKey(defaultValue: 0)
  final int statut;
  final String? equipe;

  const DashboardActivity({
    required this.id,
    required this.titre,
    this.lieu,
    this.date,
    this.heure,
    this.statut = 0,
    this.equipe,
  });

  factory DashboardActivity.fromJson(Map<String, dynamic> json) => _$DashboardActivityFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardActivityToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DashboardActivities {
  final List<DashboardActivity> items;
  @JsonKey(fromJson: _toInt)
  final int finished;
  @JsonKey(name: 'in_progress', fromJson: _toInt)
  final int inProgress;

  const DashboardActivities({this.items = const [], this.finished = 0, this.inProgress = 0});

  factory DashboardActivities.fromJson(Map<String, dynamic> json) => _$DashboardActivitiesFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardActivitiesToJson(this);
}

@JsonSerializable()
class DashboardTask {
  final int id;
  final String tache;
  @JsonKey(defaultValue: 0)
  final int statut;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'nom_dest')
  final String? nomDest;
  @JsonKey(name: 'prenoms_dest')
  final String? prenomsDest;

  const DashboardTask({required this.id, required this.tache, this.statut = 0, this.createdAt, this.nomDest, this.prenomsDest});

  String get recipient => [nomDest, prenomsDest].where((s) => s != null && s.isNotEmpty).join(' ');

  factory DashboardTask.fromJson(Map<String, dynamic> json) => _$DashboardTaskFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardTaskToJson(this);
}

@JsonSerializable()
class PlanStat {
  final int id;
  final String nom;
  @JsonKey(fromJson: _toDouble)
  final double prix;
  @JsonKey(fromJson: _toInt)
  final int count;
  @JsonKey(fromJson: _toDouble)
  final double montant;

  const PlanStat({required this.id, required this.nom, this.prix = 0, this.count = 0, this.montant = 0});

  factory PlanStat.fromJson(Map<String, dynamic> json) => _$PlanStatFromJson(json);
  Map<String, dynamic> toJson() => _$PlanStatToJson(this);
}

@JsonSerializable()
class PerfMonth {
  final String month;
  @JsonKey(fromJson: _toDouble)
  final double avg;

  const PerfMonth({required this.month, this.avg = 0});

  factory PerfMonth.fromJson(Map<String, dynamic> json) => _$PerfMonthFromJson(json);
  Map<String, dynamic> toJson() => _$PerfMonthToJson(this);
}

@JsonSerializable()
class TopPerformer {
  final int id;
  final String? nom;
  final String? prenoms;
  final String? avatar;
  @JsonKey(fromJson: _toDouble)
  final double moyenne;
  final int? age;

  const TopPerformer({required this.id, this.nom, this.prenoms, this.avatar, this.moyenne = 0, this.age});

  String get fullName => [nom, prenoms].where((s) => s != null && s.isNotEmpty).join(' ');

  factory TopPerformer.fromJson(Map<String, dynamic> json) => _$TopPerformerFromJson(json);
  Map<String, dynamic> toJson() => _$TopPerformerToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AdminDashboard {
  final DashboardCounts counts;
  @JsonKey(name: 'results_by_month', defaultValue: <MonthlyResult>[])
  final List<MonthlyResult> resultsByMonth;
  @JsonKey(name: 'matches_by_week', defaultValue: <WeekCount>[])
  final List<WeekCount> matchesByWeek;
  @JsonKey(name: 'matches_played_this_month', fromJson: _toInt)
  final int matchesPlayedThisMonth;
  @JsonKey(defaultValue: <DashboardManager>[])
  final List<DashboardManager> managers;
  @JsonKey(name: 'recent_events', defaultValue: <DashboardEvent>[])
  final List<DashboardEvent> recentEvents;
  final DashboardActivities activities;
  @JsonKey(defaultValue: <DashboardTask>[])
  final List<DashboardTask> tasks;
  @JsonKey(name: 'subscriptions_by_plan', defaultValue: <PlanStat>[])
  final List<PlanStat> subscriptionsByPlan;
  @JsonKey(name: 'performance_by_month', defaultValue: <PerfMonth>[])
  final List<PerfMonth> performanceByMonth;
  @JsonKey(name: 'top_performers', defaultValue: <TopPerformer>[])
  final List<TopPerformer> topPerformers;

  const AdminDashboard({
    required this.counts,
    this.resultsByMonth = const [],
    this.matchesByWeek = const [],
    this.matchesPlayedThisMonth = 0,
    this.managers = const [],
    this.recentEvents = const [],
    this.activities = const DashboardActivities(),
    this.tasks = const [],
    this.subscriptionsByPlan = const [],
    this.performanceByMonth = const [],
    this.topPerformers = const [],
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => _$AdminDashboardFromJson(json);
  Map<String, dynamic> toJson() => _$AdminDashboardToJson(this);
}
