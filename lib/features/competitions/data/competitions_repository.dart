import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../../core/sync/sync_service.dart';
import 'models/competition.dart';
import 'models/competition_ranking.dart';

class CompetitionsRepository extends LocalFirstRepository<Competition> {
  CompetitionsRepository(AppDatabase db, ApiClient api)
      : super(
          db: db,
          api: api,
          entityType: 'competition',
          fromJson: Competition.fromJson,
          toJson: (c) => c.toJson(),
          idOf: (c) => c.id.toString(),
        );

  Future<Competition> fetchDetail(int id) => fetchAndCache(ApiConstants.competitionById(id), id);

  Future<Competition> create({
    required String nom,
    String? description,
    String? categorie,
    String? genre,
    String? dateDebut,
    String? heureDebut,
    String? saison,
    String? photo,
  }) async {
    final result = await mutate(
      operation: 'create',
      method: 'POST',
      endpoint: ApiConstants.competitions,
      payload: {
        'nom': nom,
        // ignore: use_null_aware_elements
        if (description != null) 'description': description,
        // ignore: use_null_aware_elements
        if (categorie != null) 'categorie': categorie,
        // ignore: use_null_aware_elements
        if (genre != null) 'genre': genre,
        // ignore: use_null_aware_elements
        if (dateDebut != null) 'date_debut': dateDebut,
        // ignore: use_null_aware_elements
        if (heureDebut != null) 'heure_debut': heureDebut,
        // ignore: use_null_aware_elements
        if (saison != null) 'saison': saison,
        // ignore: use_null_aware_elements
        if (photo != null) 'photo': photo,
      },
      optimisticJson: () => {
        'id': -DateTime.now().millisecondsSinceEpoch,
        'id_utilisateur': 0,
        'nom': nom,
        'description': description,
        'categorie': categorie,
        'genre': genre,
        'date_debut': dateDebut,
        'heure_debut': heureDebut,
        'statut': 0,
        'saison': saison,
        'photo': photo,
      },
    );
    return result!;
  }

  Future<Competition> update(
    int id, {
    String? nom,
    String? description,
    String? categorie,
    String? genre,
    String? dateDebut,
    String? heureDebut,
    String? saison,
    String? photo,
  }) async {
    final result = await mutate(
      operation: 'update',
      method: 'PUT',
      endpoint: ApiConstants.competitionById(id),
      existingId: id.toString(),
      payload: {
        // ignore: use_null_aware_elements
        if (nom != null) 'nom': nom,
        // ignore: use_null_aware_elements
        if (description != null) 'description': description,
        // ignore: use_null_aware_elements
        if (categorie != null) 'categorie': categorie,
        // ignore: use_null_aware_elements
        if (genre != null) 'genre': genre,
        // ignore: use_null_aware_elements
        if (dateDebut != null) 'date_debut': dateDebut,
        // ignore: use_null_aware_elements
        if (heureDebut != null) 'heure_debut': heureDebut,
        // ignore: use_null_aware_elements
        if (saison != null) 'saison': saison,
        // ignore: use_null_aware_elements
        if (photo != null) 'photo': photo,
      },
      optimisticJson: () => {
        'id': id,
        'id_utilisateur': 0,
        'nom': nom,
        'description': description,
        'categorie': categorie,
        'genre': genre,
        'date_debut': dateDebut,
        'heure_debut': heureDebut,
        'statut': 0,
        'saison': saison,
        'photo': photo,
      },
    );
    return result!;
  }

  Future<void> delete(int id) async {
    await mutate(
      operation: 'delete',
      method: 'DELETE',
      endpoint: ApiConstants.competitionById(id),
      existingId: id.toString(),
      optimisticJson: () => {},
    );
  }

  /// `GET /competitions/{id}/rankings` — admin/owner-gated on the API; the
  /// UI calls it for anyone and surfaces a 403 as a normal [Failure].
  Future<List<CompetitionRanking>> rankings(int id) async {
    final response = await api.get<dynamic>(ApiConstants.competitionRankings(id));
    final body = response.data;
    final list = body is Map && body['data'] is List
        ? body['data'] as List
        : (body is List ? body : const <dynamic>[]);
    return list.map((e) => CompetitionRanking.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// A team registers itself into the competition.
  Future<void> register(int competitionId, int teamId) {
    return api.post(ApiConstants.competitionRegister(competitionId), data: {'id_equipe': teamId});
  }

  /// Owner-only: auto-generates a round-robin schedule for the linked teams.
  Future<void> generateFixtures(int id) {
    return api.post(ApiConstants.competitionGenerateFixtures(id), data: {});
  }

  /// Owner-only: wipes all generated matches.
  Future<void> clearMatches(int id) {
    return api.delete(ApiConstants.competitionClearMatches(id));
  }

  /// A team's current squad selection for this competition, as a list of
  /// `id_utilisateur`. The response shape isn't documented beyond "add/remove
  /// a player by id_utilisateur", so this parses defensively: a bare list of
  /// ids, a list of `{id_utilisateur}` objects, or `{data: [...]}`.
  Future<List<int>> selection(int competitionId, int teamId) async {
    final response = await api.get<dynamic>(ApiConstants.competitionTeamSelection(competitionId, teamId));
    final body = response.data;
    final list = body is Map && body['data'] is List
        ? body['data'] as List
        : (body is List ? body : const <dynamic>[]);
    return list.map((e) {
      if (e is Map) return (e['id_utilisateur'] ?? e['id']) as int;
      return e as int;
    }).toList();
  }

  Future<void> addToSelection(int competitionId, int teamId, int userId) {
    return api.post(
      ApiConstants.competitionTeamSelection(competitionId, teamId),
      data: {'id_utilisateur': userId},
    );
  }

  Future<void> removeFromSelection(int competitionId, int teamId, int userId) {
    return api.delete('${ApiConstants.competitionTeamSelection(competitionId, teamId)}/$userId');
  }

  /// Uploads a new competition photo (owner-only on the API side), mirroring
  /// ProfileRepository.uploadAvatar's multipart pattern.
  Future<Competition> uploadPhoto(int competitionId, File file) async {
    try {
      final formData = FormData.fromMap({'photo': await MultipartFile.fromFile(file.path)});
      final response = await api.uploadFile<Map<String, dynamic>>(ApiConstants.competitionPhoto(competitionId), formData: formData);
      final competition = Competition.fromJson(response.data!);
      await db.upsertEntity(entityType, idOf(competition), jsonEncode(response.data!), DateTime.now());
      return competition;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final competitionsRepositoryProvider = Provider<CompetitionsRepository>((ref) {
  final repo = CompetitionsRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'competition',
        endpoint: ApiConstants.competitions,
        extractItems: SyncableResource.laravelPage,
      ));
  return repo;
});
