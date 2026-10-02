import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_config.dart';
import '../data/admin_repository.dart';
import '../data/models/admin_models.dart';
import '../data/models/global_stats.dart';
import '../data/models/plan.dart';
import '../data/plans_repository.dart';

final globalStatsProvider = FutureProvider.autoDispose<GlobalStats>((ref) {
  return ref.watch(adminRepositoryProvider).fetchStats();
});

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboard>((ref) {
  return ref.watch(adminRepositoryProvider).fetchDashboard();
});

// --- Users (legacy admin/utilisateurs.php) --------------------------------

/// Filters of the admin users screen: poste (grouped by category), catégorie,
/// genre, nom, plus column sort and page.
class AdminUsersFilter {
  final String? search;
  final String? genre;
  final String? poste;
  final String? categorie;
  final String sort;
  final bool ascending;
  final int page;

  const AdminUsersFilter({
    this.search,
    this.genre,
    this.poste,
    this.categorie,
    this.sort = 'nom',
    this.ascending = true,
    this.page = 1,
  });

  bool get hasFilters =>
      (search?.isNotEmpty ?? false) || genre != null || poste != null || categorie != null;

  AdminUsersFilter copyWith({
    String? search,
    bool clearSearch = false,
    String? genre,
    bool clearGenre = false,
    String? poste,
    bool clearPoste = false,
    String? categorie,
    bool clearCategorie = false,
    String? sort,
    bool? ascending,
    int? page,
  }) {
    return AdminUsersFilter(
      search: clearSearch ? null : (search ?? this.search),
      genre: clearGenre ? null : (genre ?? this.genre),
      poste: clearPoste ? null : (poste ?? this.poste),
      categorie: clearCategorie ? null : (categorie ?? this.categorie),
      sort: sort ?? this.sort,
      ascending: ascending ?? this.ascending,
      // Any filter/sort change goes back to page 1 unless a page is given.
      page: page ?? 1,
    );
  }
}

final adminUsersFilterProvider = StateProvider.autoDispose<AdminUsersFilter>((ref) => const AdminUsersFilter());

final adminUsersProvider = FutureProvider.autoDispose<PagedResult<AdminUserRow>>((ref) {
  final f = ref.watch(adminUsersFilterProvider);
  return ref.watch(adminRepositoryProvider).fetchUsers(
        search: f.search,
        genre: f.genre,
        poste: f.poste,
        categorie: f.categorie,
        sort: f.sort,
        order: f.ascending ? 'asc' : 'desc',
        page: f.page,
      );
});

// --- Teams / fields: search + order + page ----------------------------------

class AdminListFilter {
  final String search;
  final bool ascending;
  final int page;
  const AdminListFilter({this.search = '', this.ascending = true, this.page = 1});

  AdminListFilter copyWith({String? search, bool? ascending, int? page}) => AdminListFilter(
        search: search ?? this.search,
        ascending: ascending ?? this.ascending,
        page: page ?? 1,
      );
}

final adminTeamsFilterProvider = StateProvider.autoDispose<AdminListFilter>((ref) => const AdminListFilter());

final adminTeamsProvider = FutureProvider.autoDispose<PagedResult<AdminTeamRow>>((ref) {
  final f = ref.watch(adminTeamsFilterProvider);
  return ref.watch(adminRepositoryProvider).fetchTeams(
        search: f.search,
        order: f.ascending ? 'asc' : 'desc',
        page: f.page,
      );
});

final adminFieldsFilterProvider = StateProvider.autoDispose<AdminListFilter>((ref) => const AdminListFilter());

final adminFieldsProvider = FutureProvider.autoDispose<PagedResult<AdminFieldRow>>((ref) {
  final f = ref.watch(adminFieldsFilterProvider);
  return ref.watch(adminRepositoryProvider).fetchFields(
        search: f.search,
        order: f.ascending ? 'asc' : 'desc',
        page: f.page,
      );
});

// --- Competitions (legacy admin/competitions.php) ---------------------------

class AdminCompetitionsFilter {
  final String search;
  final int? statut;
  final String? categorie;
  final String? genre;
  final int page;

  const AdminCompetitionsFilter({this.search = '', this.statut, this.categorie, this.genre, this.page = 1});

  bool get hasFilters => search.isNotEmpty || statut != null || categorie != null || genre != null;

  AdminCompetitionsFilter copyWith({
    String? search,
    int? statut,
    bool clearStatut = false,
    String? categorie,
    bool clearCategorie = false,
    String? genre,
    bool clearGenre = false,
    int? page,
  }) {
    return AdminCompetitionsFilter(
      search: search ?? this.search,
      statut: clearStatut ? null : (statut ?? this.statut),
      categorie: clearCategorie ? null : (categorie ?? this.categorie),
      genre: clearGenre ? null : (genre ?? this.genre),
      page: page ?? 1,
    );
  }
}

final adminCompetitionsFilterProvider =
    StateProvider.autoDispose<AdminCompetitionsFilter>((ref) => const AdminCompetitionsFilter());

final adminCompetitionsProvider = FutureProvider.autoDispose<PagedResult<AdminCompetitionRow>>((ref) {
  final f = ref.watch(adminCompetitionsFilterProvider);
  return ref.watch(adminRepositoryProvider).fetchCompetitions(
        search: f.search,
        statut: f.statut,
        categorie: f.categorie,
        genre: f.genre,
        page: f.page,
      );
});

// --- Generic "Gérer" editor ---------------------------------------------------

final adminTargetProvider =
    FutureProvider.autoDispose.family<AdminManageTarget, ({AdminEntity entity, int id})>((ref, args) {
  return ref.watch(adminRepositoryProvider).fetchTarget(args.entity, args.id);
});

// --- Plans --------------------------------------------------------------------

final plansListProvider = FutureProvider.autoDispose<List<Plan>>((ref) {
  return ref.watch(plansRepositoryProvider).fetchAll();
});
