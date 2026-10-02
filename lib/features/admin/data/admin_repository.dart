import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'admin_config.dart';
import 'admin_endpoints.dart';
import 'models/admin_models.dart';
import 'models/global_stats.dart';

/// What the generic "Gérer" editor needs to display an entity.
class AdminManageTarget {
  final AdminEntity entity;
  final int id;
  final String name;
  final String? subtitle;
  final String? image;
  final int statut;
  final bool isBlocked;
  final bool isAdmin;

  const AdminManageTarget({
    required this.entity,
    required this.id,
    required this.name,
    this.subtitle,
    this.image,
    required this.statut,
    this.isBlocked = false,
    this.isAdmin = false,
  });

  AdminManageTarget copyWith({int? statut, bool? isBlocked, bool? isAdmin}) => AdminManageTarget(
        entity: entity,
        id: id,
        name: name,
        subtitle: subtitle,
        image: image,
        statut: statut ?? this.statut,
        isBlocked: isBlocked ?? this.isBlocked,
        isAdmin: isAdmin ?? this.isAdmin,
      );
}

/// Admin back-office endpoints. Deliberately not local-first: moderation
/// views must show fresh server data.
class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<GlobalStats> fetchStats() => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(ApiConstants.adminStats);
        return GlobalStats.fromJson(response.data!);
      });

  Future<AdminDashboard> fetchDashboard() => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(AdminEndpoints.dashboard);
        return AdminDashboard.fromJson(response.data!);
      });

  Map<String, dynamic> _clean(Map<String, dynamic> q) {
    q.removeWhere((_, v) => v == null || (v is String && v.isEmpty));
    return q;
  }

  Future<PagedResult<AdminUserRow>> fetchUsers({
    String? search,
    String? genre,
    String? poste,
    String? categorie,
    int? statut,
    String sort = 'nom',
    String order = 'asc',
    int page = 1,
    int perPage = 15,
  }) =>
      _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(
          ApiConstants.adminUsers,
          queryParameters: _clean({
            'search': search,
            'genre': genre,
            'poste': poste,
            'categorie': categorie,
            'statut': statut,
            'sort': sort,
            'order': order,
            'page': page,
            'per_page': perPage,
          }),
        );
        return PagedResult.fromJson(response.data!, AdminUserRow.fromJson);
      });

  Future<PagedResult<AdminTeamRow>> fetchTeams({String? search, String order = 'asc', int page = 1, int perPage = 15}) =>
      _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(
          AdminEndpoints.teams,
          queryParameters: _clean({'search': search, 'order': order, 'page': page, 'per_page': perPage}),
        );
        return PagedResult.fromJson(response.data!, AdminTeamRow.fromJson);
      });

  Future<PagedResult<AdminCompetitionRow>> fetchCompetitions({
    String? search,
    int? statut,
    String? categorie,
    String? genre,
    String order = 'asc',
    int page = 1,
    int perPage = 6,
  }) =>
      _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(
          AdminEndpoints.competitions,
          queryParameters: _clean({
            'search': search,
            'statut': statut,
            'categorie': categorie,
            'genre': genre,
            'order': order,
            'page': page,
            'per_page': perPage,
          }),
        );
        return PagedResult.fromJson(response.data!, AdminCompetitionRow.fromJson);
      });

  Future<PagedResult<AdminFieldRow>> fetchFields({String? search, String order = 'asc', int page = 1, int perPage = 12}) =>
      _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(
          AdminEndpoints.fields,
          queryParameters: _clean({'search': search, 'order': order, 'page': page, 'per_page': perPage}),
        );
        return PagedResult.fromJson(response.data!, AdminFieldRow.fromJson);
      });

  /// Loads a single entity for the "Gérer" screen from the public detail
  /// endpoints (`/users/{id}`, `/teams/{id}`, ...).
  Future<AdminManageTarget> fetchTarget(AdminEntity entity, int id) => _guard(() async {
        switch (entity) {
          case AdminEntity.utilisateurs:
            final r = await _api.get<Map<String, dynamic>>(ApiConstants.userById(id));
            final u = _unwrap(r.data!);
            var isAdmin = u['is_admin'] == true;
            final email = u['email'] as String?;
            if (email != null && !u.containsKey('is_admin')) {
              final page = await fetchUsers(search: email, perPage: 5);
              for (final row in page.data) {
                if (row.id == id) isAdmin = row.isAdmin;
              }
            }
            return AdminManageTarget(
              entity: entity,
              id: id,
              name: [u['nom'], u['prenoms']].where((s) => s != null && '$s'.isNotEmpty).join(' '),
              subtitle: email,
              image: u['avatar'] as String?,
              statut: (u['statut'] as num?)?.toInt() ?? 1,
              isBlocked: u['is_blocked'] == true || u['is_blocked'] == 1,
              isAdmin: isAdmin,
            );
          case AdminEntity.equipes:
            final r = await _api.get<Map<String, dynamic>>(ApiConstants.teamById(id));
            final t = _unwrap(r.data!);
            return AdminManageTarget(
              entity: entity,
              id: id,
              name: '${t['nom'] ?? ''}',
              subtitle: t['lieu'] as String?,
              image: t['logo'] as String?,
              statut: (t['statut'] as num?)?.toInt() ?? 1,
            );
          case AdminEntity.competitions:
            final r = await _api.get<Map<String, dynamic>>(ApiConstants.competitionById(id));
            final c = _unwrap(r.data!);
            return AdminManageTarget(
              entity: entity,
              id: id,
              name: '${c['nom'] ?? ''}',
              subtitle: [c['categorie'], c['genre']].where((s) => s != null && '$s'.isNotEmpty).join(' · '),
              image: c['photo'] as String?,
              statut: (c['statut'] as num?)?.toInt() ?? 0,
            );
          case AdminEntity.terrains:
            final r = await _api.get<Map<String, dynamic>>(ApiConstants.fieldById(id));
            final f = _unwrap(r.data!);
            return AdminManageTarget(
              entity: entity,
              id: id,
              name: '${f['nom_terrain'] ?? ''}',
              subtitle: f['lieu'] as String?,
              image: f['photo'] as String?,
              statut: (f['statut'] as num?)?.toInt() ?? 1,
            );
        }
      });

  Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final inner = json['data'];
    return inner is Map<String, dynamic> ? inner : json;
  }

  /// Legacy "Mettre à jour" of `admin/gerer.php`: writes the new statut on
  /// the right admin endpoint for the entity.
  Future<void> updateStatus(AdminEntity entity, int id, int statut) => _guard(() async {
        switch (entity) {
          case AdminEntity.utilisateurs:
            await _api.put(ApiConstants.adminUserStatus(id), data: {'statut': statut});
          case AdminEntity.equipes:
            await _api.put(ApiConstants.adminTeamStatus(id), data: {'statut': statut});
          case AdminEntity.competitions:
            await _api.put(ApiConstants.adminCompetitionStatus(id), data: {'statut': statut});
          case AdminEntity.terrains:
            await _api.put(ApiConstants.adminFieldStatus(id), data: {'statut': statut});
        }
      });

  Future<void> setUserBlocked(int userId, bool blocked) => _guard(() async {
        await _api.put(ApiConstants.adminUserStatus(userId), data: {'is_blocked': blocked});
      });

  Future<void> grantAdmin(int userId, {String? role}) => _guard(() async {
        await _api.post(ApiConstants.adminAdmins, data: {'id_utilisateur': userId, 'role': ?role});
      });

  Future<void> revokeAdmin(int userId) => _guard(() async {
        await _api.delete('${ApiConstants.adminAdmins}/$userId');
      });
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});
