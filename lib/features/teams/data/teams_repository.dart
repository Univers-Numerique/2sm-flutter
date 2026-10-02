import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../../core/sync/sync_service.dart';
import 'models/team.dart';
import 'models/team_dashboard.dart';
import 'models/team_member.dart';

class TeamsRepository extends LocalFirstRepository<Team> {
  final ApiClient _api;

  TeamsRepository(AppDatabase db, ApiClient api)
      : _api = api,
        super(
          db: db,
          api: api,
          entityType: 'team',
          fromJson: Team.fromJson,
          toJson: (t) => t.toJson(),
          idOf: (t) => t.id.toString(),
        );

  Future<Team> fetchDetail(int id) => fetchAndCache(ApiConstants.teamById(id), id);

  Future<Team> create({required String nom, String? lieu, String? logo}) async {
    final result = await mutate(
      operation: 'create',
      method: 'POST',
      endpoint: ApiConstants.teams,
      payload: {'nom': nom, 'lieu': ?lieu, 'logo': ?logo},
      optimisticJson: () => {
        'id': -DateTime.now().millisecondsSinceEpoch,
        'nom': nom,
        'lieu': lieu,
        'logo': logo,
        'statut': 1,
      },
    );
    return result!;
  }

  Future<Team> update(int id, {String? nom, String? lieu, String? logo}) async {
    final result = await mutate(
      operation: 'update',
      method: 'PUT',
      endpoint: ApiConstants.teamById(id),
      existingId: id.toString(),
      payload: {'nom': ?nom, 'lieu': ?lieu, 'logo': ?logo},
      optimisticJson: () => {'id': id, 'nom': nom, 'lieu': lieu, 'logo': logo, 'statut': 1},
    );
    return result!;
  }

  /// `GET /teams/{id}/members` — users with their position on this team.
  Future<List<TeamMember>> members(int teamId) async {
    try {
      final response = await _api.get<List<dynamic>>(ApiConstants.teamMembers(teamId));
      return (response.data ?? [])
          .map((e) => TeamMember.fromJson(Map<String, dynamic>.from(e as Map), teamId: teamId))
          .toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// `POST /teams/{id}/members` — adds a user or updates their position
  /// (poste, type, catégorie, pied fort, maillot, taille, poids, nationalité).
  Future<void> addMember(
    int teamId,
    int userId, {
    String poste = 'Joueur',
    String? categorie,
    String? type,
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      await _api.post(ApiConstants.teamMembers(teamId), data: {
        'id_utilisateur': userId,
        'poste': poste,
        'categorie': ?categorie,
        'type': ?type,
        ...extra,
      });
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> removeMember(int teamId, int userId) async {
    try {
      await _api.delete(ApiConstants.teamMembers(teamId), data: {'id_utilisateur': userId});
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// `GET /teams/{id}/statistics` (members only).
  Future<TeamStatistics> statistics(int teamId) async {
    try {
      final r = await _api.get<Map<String, dynamic>>(ApiConstants.teamStatistics(teamId));
      return TeamStatistics.fromJson(r.data ?? const {});
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// `GET /teams/{id}/dashboard`
  Future<TeamDashboard> dashboard(int teamId) async {
    try {
      final r = await _api.get<Map<String, dynamic>>('/teams/$teamId/dashboard');
      return TeamDashboard.fromJson(r.data ?? const {});
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// `GET /teams/{id}/member-stats`
  Future<MemberStatsBundle> memberStats(int teamId) async {
    try {
      final r = await _api.get<Map<String, dynamic>>('/teams/$teamId/member-stats');
      return MemberStatsBundle.fromJson(r.data ?? const {});
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// "Créer un membre" (legacy `inscrireMembre()`): registers a new account
  /// with a generated temporary password, then attaches it to the team.
  /// Returns the temporary password so the manager can hand it over.
  Future<String> createMember(
    int teamId, {
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    String poste = 'Joueur',
    String? categorie,
  }) async {
    final rnd = Random.secure();
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final password = List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
    try {
      final r = await _api.post<Map<String, dynamic>>(ApiConstants.register, data: {
        'nom': nom,
        'prenoms': prenoms,
        'email': email,
        'telephone': telephone,
        'pass': password,
      });
      final userId = (r.data?['user'] as Map?)?['id'] as int?;
      if (userId == null) throw const Failure("Le compte a été créé mais son identifiant est introuvable.");
      await addMember(teamId, userId, poste: poste, categorie: categorie);
      return password;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// Uploads a new team logo (owner-only on the API side), mirroring
  /// ProfileRepository.uploadAvatar's multipart pattern.
  Future<Team> uploadLogo(int teamId, File file) async {
    try {
      final formData = FormData.fromMap({'logo': await MultipartFile.fromFile(file.path)});
      final response = await _api.uploadFile<Map<String, dynamic>>(ApiConstants.teamLogo(teamId), formData: formData);
      final team = Team.fromJson(response.data!);
      await db.upsertEntity(entityType, idOf(team), jsonEncode(response.data!), DateTime.now());
      return team;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  final repo = TeamsRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'team',
        endpoint: ApiConstants.teams,
        extractItems: SyncableResource.laravelPage,
      ));
  return repo;
});
