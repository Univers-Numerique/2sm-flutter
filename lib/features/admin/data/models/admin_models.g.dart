// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminOwnerRef _$AdminOwnerRefFromJson(Map<String, dynamic> json) =>
    AdminOwnerRef(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$AdminOwnerRefToJson(AdminOwnerRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
    };

AdminUserRow _$AdminUserRowFromJson(Map<String, dynamic> json) => AdminUserRow(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  prenoms: json['prenoms'] as String?,
  email: json['email'] as String?,
  telephone: json['telephone'] as String?,
  avatar: json['avatar'] as String?,
  genre: json['genre'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  isBlocked: json['is_blocked'] as bool? ?? false,
  isAdmin: json['is_admin'] as bool? ?? false,
  poste: json['poste'] as String?,
  categorie: json['categorie'] as String?,
  equipe: json['equipe'] as String?,
  teamId: (json['id_equipe'] as num?)?.toInt(),
  age: (json['age'] as num?)?.toInt(),
  dateInscription: json['date_inscription'] as String?,
);

Map<String, dynamic> _$AdminUserRowToJson(AdminUserRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'email': instance.email,
      'telephone': instance.telephone,
      'avatar': instance.avatar,
      'genre': instance.genre,
      'statut': instance.statut,
      'is_blocked': instance.isBlocked,
      'is_admin': instance.isAdmin,
      'poste': instance.poste,
      'categorie': instance.categorie,
      'equipe': instance.equipe,
      'id_equipe': instance.teamId,
      'age': instance.age,
      'date_inscription': instance.dateInscription,
    };

AdminTeamRow _$AdminTeamRowFromJson(Map<String, dynamic> json) => AdminTeamRow(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String,
  lieu: json['lieu'] as String?,
  logo: json['logo'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 1,
  membersCount: (json['members_count'] as num?)?.toInt() ?? 0,
  owner: json['owner'] == null
      ? null
      : AdminOwnerRef.fromJson(json['owner'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdminTeamRowToJson(AdminTeamRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'lieu': instance.lieu,
      'logo': instance.logo,
      'statut': instance.statut,
      'members_count': instance.membersCount,
      'owner': instance.owner?.toJson(),
    };

AdminCompetitionRow _$AdminCompetitionRowFromJson(
  Map<String, dynamic> json,
) => AdminCompetitionRow(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String,
  description: json['description'] as String?,
  categorie: json['categorie'] as String?,
  genre: json['genre'] as String?,
  saison: json['saison'] as String?,
  dateDebut: json['date_debut'] as String?,
  heureDebut: json['heure_debut'] as String?,
  statut: (json['statut'] as num?)?.toInt() ?? 0,
  photo: json['photo'] as String?,
  progression: json['progression'] == null ? 0 : _toDouble(json['progression']),
  nomTerrain: json['nom_terrain'] as String?,
  matchesCount: (json['matches_count'] as num?)?.toInt() ?? 0,
  matchesFinishedCount: (json['matches_finished_count'] as num?)?.toInt() ?? 0,
  owner: json['owner'] == null
      ? null
      : AdminOwnerRef.fromJson(json['owner'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AdminCompetitionRowToJson(
  AdminCompetitionRow instance,
) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'description': instance.description,
  'categorie': instance.categorie,
  'genre': instance.genre,
  'saison': instance.saison,
  'date_debut': instance.dateDebut,
  'heure_debut': instance.heureDebut,
  'statut': instance.statut,
  'photo': instance.photo,
  'progression': instance.progression,
  'nom_terrain': instance.nomTerrain,
  'matches_count': instance.matchesCount,
  'matches_finished_count': instance.matchesFinishedCount,
  'owner': instance.owner?.toJson(),
};

AdminFieldRow _$AdminFieldRowFromJson(Map<String, dynamic> json) =>
    AdminFieldRow(
      id: (json['id'] as num).toInt(),
      nomTerrain: json['nom_terrain'] as String,
      lieu: json['lieu'] as String?,
      latitude: _toDoubleOrNull(json['latitude']),
      longitude: _toDoubleOrNull(json['longitude']),
      photo: json['photo'] as String?,
      statut: (json['statut'] as num?)?.toInt() ?? 1,
      owner: json['owner'] == null
          ? null
          : AdminOwnerRef.fromJson(json['owner'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AdminFieldRowToJson(AdminFieldRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom_terrain': instance.nomTerrain,
      'lieu': instance.lieu,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'photo': instance.photo,
      'statut': instance.statut,
      'owner': instance.owner?.toJson(),
    };

DashboardCounts _$DashboardCountsFromJson(Map<String, dynamic> json) =>
    DashboardCounts(
      users: json['users'] == null ? 0 : _toInt(json['users']),
      teams: json['teams'] == null ? 0 : _toInt(json['teams']),
      fields: json['fields'] == null ? 0 : _toInt(json['fields']),
      competitions: json['competitions'] == null
          ? 0
          : _toInt(json['competitions']),
      matches: json['matches'] == null ? 0 : _toInt(json['matches']),
      matchesPlayed: json['matches_played'] == null
          ? 0
          : _toInt(json['matches_played']),
      activities: json['activities'] == null ? 0 : _toInt(json['activities']),
      goals: json['goals'] == null ? 0 : _toInt(json['goals']),
      matchesToday: json['matches_today'] == null
          ? 0
          : _toInt(json['matches_today']),
      newUsersThisMonth: json['new_users_this_month'] == null
          ? 0
          : _toInt(json['new_users_this_month']),
    );

Map<String, dynamic> _$DashboardCountsToJson(DashboardCounts instance) =>
    <String, dynamic>{
      'users': instance.users,
      'teams': instance.teams,
      'fields': instance.fields,
      'competitions': instance.competitions,
      'matches': instance.matches,
      'matches_played': instance.matchesPlayed,
      'activities': instance.activities,
      'goals': instance.goals,
      'matches_today': instance.matchesToday,
      'new_users_this_month': instance.newUsersThisMonth,
    };

MonthlyResult _$MonthlyResultFromJson(Map<String, dynamic> json) =>
    MonthlyResult(
      month: json['month'] as String,
      homeWins: json['home_wins'] == null ? 0 : _toInt(json['home_wins']),
      draws: json['draws'] == null ? 0 : _toInt(json['draws']),
      awayWins: json['away_wins'] == null ? 0 : _toInt(json['away_wins']),
      goals: json['goals'] == null ? 0 : _toInt(json['goals']),
      matches: json['matches'] == null ? 0 : _toInt(json['matches']),
    );

Map<String, dynamic> _$MonthlyResultToJson(MonthlyResult instance) =>
    <String, dynamic>{
      'month': instance.month,
      'home_wins': instance.homeWins,
      'draws': instance.draws,
      'away_wins': instance.awayWins,
      'goals': instance.goals,
      'matches': instance.matches,
    };

WeekCount _$WeekCountFromJson(Map<String, dynamic> json) => WeekCount(
  week: json['week'] == null ? 0 : _toInt(json['week']),
  matches: json['matches'] == null ? 0 : _toInt(json['matches']),
);

Map<String, dynamic> _$WeekCountToJson(WeekCount instance) => <String, dynamic>{
  'week': instance.week,
  'matches': instance.matches,
};

DashboardManager _$DashboardManagerFromJson(Map<String, dynamic> json) =>
    DashboardManager(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String?,
      prenoms: json['prenoms'] as String?,
      avatar: json['avatar'] as String?,
      genre: json['genre'] as String?,
      dateDeNaissance: json['date_de_naissance'] as String?,
      telephone: json['telephone'] as String?,
      poste: json['poste'] as String?,
      equipe: json['equipe'] as String?,
      depuis: json['depuis'] as String?,
    );

Map<String, dynamic> _$DashboardManagerToJson(DashboardManager instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
      'genre': instance.genre,
      'date_de_naissance': instance.dateDeNaissance,
      'telephone': instance.telephone,
      'poste': instance.poste,
      'equipe': instance.equipe,
      'depuis': instance.depuis,
    };

DashboardEvent _$DashboardEventFromJson(Map<String, dynamic> json) =>
    DashboardEvent(
      id: (json['id'] as num).toInt(),
      home: json['home'] as String?,
      away: json['away'] as String?,
      date: json['date'] as String?,
      heure: json['heure'] as String?,
      statut: (json['statut'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$DashboardEventToJson(DashboardEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'home': instance.home,
      'away': instance.away,
      'date': instance.date,
      'heure': instance.heure,
      'statut': instance.statut,
    };

DashboardActivity _$DashboardActivityFromJson(Map<String, dynamic> json) =>
    DashboardActivity(
      id: (json['id'] as num).toInt(),
      titre: json['titre'] as String,
      lieu: json['lieu'] as String?,
      date: json['date'] as String?,
      heure: json['heure'] as String?,
      statut: (json['statut'] as num?)?.toInt() ?? 0,
      equipe: json['equipe'] as String?,
    );

Map<String, dynamic> _$DashboardActivityToJson(DashboardActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titre': instance.titre,
      'lieu': instance.lieu,
      'date': instance.date,
      'heure': instance.heure,
      'statut': instance.statut,
      'equipe': instance.equipe,
    };

DashboardActivities _$DashboardActivitiesFromJson(Map<String, dynamic> json) =>
    DashboardActivities(
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => DashboardActivity.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      finished: json['finished'] == null ? 0 : _toInt(json['finished']),
      inProgress: json['in_progress'] == null ? 0 : _toInt(json['in_progress']),
    );

Map<String, dynamic> _$DashboardActivitiesToJson(
  DashboardActivities instance,
) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
  'finished': instance.finished,
  'in_progress': instance.inProgress,
};

DashboardTask _$DashboardTaskFromJson(Map<String, dynamic> json) =>
    DashboardTask(
      id: (json['id'] as num).toInt(),
      tache: json['tache'] as String,
      statut: (json['statut'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String?,
      nomDest: json['nom_dest'] as String?,
      prenomsDest: json['prenoms_dest'] as String?,
    );

Map<String, dynamic> _$DashboardTaskToJson(DashboardTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tache': instance.tache,
      'statut': instance.statut,
      'created_at': instance.createdAt,
      'nom_dest': instance.nomDest,
      'prenoms_dest': instance.prenomsDest,
    };

PlanStat _$PlanStatFromJson(Map<String, dynamic> json) => PlanStat(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String,
  prix: json['prix'] == null ? 0 : _toDouble(json['prix']),
  count: json['count'] == null ? 0 : _toInt(json['count']),
  montant: json['montant'] == null ? 0 : _toDouble(json['montant']),
);

Map<String, dynamic> _$PlanStatToJson(PlanStat instance) => <String, dynamic>{
  'id': instance.id,
  'nom': instance.nom,
  'prix': instance.prix,
  'count': instance.count,
  'montant': instance.montant,
};

PerfMonth _$PerfMonthFromJson(Map<String, dynamic> json) => PerfMonth(
  month: json['month'] as String,
  avg: json['avg'] == null ? 0 : _toDouble(json['avg']),
);

Map<String, dynamic> _$PerfMonthToJson(PerfMonth instance) => <String, dynamic>{
  'month': instance.month,
  'avg': instance.avg,
};

TopPerformer _$TopPerformerFromJson(Map<String, dynamic> json) => TopPerformer(
  id: (json['id'] as num).toInt(),
  nom: json['nom'] as String?,
  prenoms: json['prenoms'] as String?,
  avatar: json['avatar'] as String?,
  moyenne: json['moyenne'] == null ? 0 : _toDouble(json['moyenne']),
  age: (json['age'] as num?)?.toInt(),
);

Map<String, dynamic> _$TopPerformerToJson(TopPerformer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nom': instance.nom,
      'prenoms': instance.prenoms,
      'avatar': instance.avatar,
      'moyenne': instance.moyenne,
      'age': instance.age,
    };

AdminDashboard _$AdminDashboardFromJson(Map<String, dynamic> json) =>
    AdminDashboard(
      counts: DashboardCounts.fromJson(json['counts'] as Map<String, dynamic>),
      resultsByMonth:
          (json['results_by_month'] as List<dynamic>?)
              ?.map((e) => MonthlyResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      matchesByWeek:
          (json['matches_by_week'] as List<dynamic>?)
              ?.map((e) => WeekCount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      matchesPlayedThisMonth: json['matches_played_this_month'] == null
          ? 0
          : _toInt(json['matches_played_this_month']),
      managers:
          (json['managers'] as List<dynamic>?)
              ?.map((e) => DashboardManager.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentEvents:
          (json['recent_events'] as List<dynamic>?)
              ?.map((e) => DashboardEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activities: json['activities'] == null
          ? const DashboardActivities()
          : DashboardActivities.fromJson(
              json['activities'] as Map<String, dynamic>,
            ),
      tasks:
          (json['tasks'] as List<dynamic>?)
              ?.map((e) => DashboardTask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      subscriptionsByPlan:
          (json['subscriptions_by_plan'] as List<dynamic>?)
              ?.map((e) => PlanStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      performanceByMonth:
          (json['performance_by_month'] as List<dynamic>?)
              ?.map((e) => PerfMonth.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topPerformers:
          (json['top_performers'] as List<dynamic>?)
              ?.map((e) => TopPerformer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$AdminDashboardToJson(
  AdminDashboard instance,
) => <String, dynamic>{
  'counts': instance.counts.toJson(),
  'results_by_month': instance.resultsByMonth.map((e) => e.toJson()).toList(),
  'matches_by_week': instance.matchesByWeek.map((e) => e.toJson()).toList(),
  'matches_played_this_month': instance.matchesPlayedThisMonth,
  'managers': instance.managers.map((e) => e.toJson()).toList(),
  'recent_events': instance.recentEvents.map((e) => e.toJson()).toList(),
  'activities': instance.activities.toJson(),
  'tasks': instance.tasks.map((e) => e.toJson()).toList(),
  'subscriptions_by_plan': instance.subscriptionsByPlan
      .map((e) => e.toJson())
      .toList(),
  'performance_by_month': instance.performanceByMonth
      .map((e) => e.toJson())
      .toList(),
  'top_performers': instance.topPerformers.map((e) => e.toJson()).toList(),
};
