import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../../core/sync/sync_service.dart';
import 'models/match_game.dart';

class MatchesRepository extends LocalFirstRepository<MatchGame> {
  final ApiClient _api;
  final AppDatabase _db;

  MatchesRepository(AppDatabase db, ApiClient api)
      : _api = api,
        _db = db,
        super(
          db: db,
          api: api,
          entityType: 'match',
          fromJson: MatchGame.fromJson,
          toJson: (m) => m.toJson(),
          idOf: (m) => m.id.toString(),
        );

  /// Converts a raw [DioException] into the app's uniform [Failure] so every
  /// screen can rely on `on Failure catch (e) => e.message` regardless of
  /// which repository method threw.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<MatchGame> fetchDetail(int id) => _guard(() => fetchAndCache(ApiConstants.matchById(id), id));

  /// Browses matches straight from the API with server-side filters
  /// (bypassing the cached unfiltered list) — results are also mirrored into
  /// the local cache so offline detail views still work.
  Future<List<MatchGame>> search({int? statut, int? competitionId, int? teamId}) => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(
          ApiConstants.matches,
          queryParameters: {
            if (statut != null) 'status': statut,
            if (competitionId != null) 'competition_id': competitionId,
            if (teamId != null) 'team_id': teamId,
          },
        );
        final items = SyncableResource.laravelPage(response.data ?? const {});
        for (final item in items) {
          await _db.upsertEntity('match', item['id'].toString(), jsonEncode(item), DateTime.now());
        }
        return items.map(MatchGame.fromJson).toList();
      });

  Future<List<MatchGame>> live() => _guard(() async {
        final response = await _api.get<List<dynamic>>(ApiConstants.liveMatches);
        final items = (response.data ?? const []).cast<Map<String, dynamic>>();
        for (final item in items) {
          await _db.upsertEntity('match', item['id'].toString(), jsonEncode(item), DateTime.now());
        }
        return items.map(MatchGame.fromJson).toList();
      });

  Future<MatchGame> create({
    required int homeTeamId,
    required int awayTeamId,
    required String dateDebut,
    required String heureDebut,
    int? competitionId,
    String? genre,
    String? categorie,
    int? lieu,
  }) =>
      _guard(() async {
        final result = await mutate(
          operation: 'create',
          method: 'POST',
          endpoint: ApiConstants.matches,
          payload: {
            'id_equipe_domicile': homeTeamId,
            'id_equipe_exterieur': awayTeamId,
            'date_debut': dateDebut,
            'heure_debut': heureDebut,
            if (competitionId != null) 'id_competition': competitionId,
            if (genre != null) 'genre': genre,
            if (categorie != null) 'categorie': categorie,
            if (lieu != null) 'lieu': lieu,
          },
          optimisticJson: () => {
            'id': -DateTime.now().millisecondsSinceEpoch,
            'id_utilisateur': 0,
            'id_equipe_domicile': homeTeamId,
            'id_equipe_exterieur': awayTeamId,
            'date_debut': dateDebut,
            'heure_debut': heureDebut,
            'id_competition': competitionId,
            'genre': genre,
            'categorie': categorie,
            'lieu': lieu,
            'statut': 0,
          },
        );
        return result!;
      });

  Future<MatchGame> update(
    int id, {
    int? homeTeamId,
    int? awayTeamId,
    String? dateDebut,
    String? heureDebut,
    int? competitionId,
    String? genre,
    String? categorie,
    int? lieu,
  }) =>
      _guard(() async {
        final result = await mutate(
          operation: 'update',
          method: 'PUT',
          endpoint: ApiConstants.matchById(id),
          existingId: id.toString(),
          payload: {
            if (homeTeamId != null) 'id_equipe_domicile': homeTeamId,
            if (awayTeamId != null) 'id_equipe_exterieur': awayTeamId,
            if (dateDebut != null) 'date_debut': dateDebut,
            if (heureDebut != null) 'heure_debut': heureDebut,
            if (competitionId != null) 'id_competition': competitionId,
            if (genre != null) 'genre': genre,
            if (categorie != null) 'categorie': categorie,
            if (lieu != null) 'lieu': lieu,
          },
          optimisticJson: () => {
            'id': id,
            'id_equipe_domicile': homeTeamId,
            'id_equipe_exterieur': awayTeamId,
            'date_debut': dateDebut,
            'heure_debut': heureDebut,
            'id_competition': competitionId,
            'genre': genre,
            'categorie': categorie,
            'lieu': lieu,
            'statut': 0,
          },
        );
        return result!;
      });

  Future<MatchGame> start(int id) => _guard(() async {
        final response = await _api.post<Map<String, dynamic>>(ApiConstants.matchStart(id));
        final json = response.data!;
        await _db.upsertEntity('match', id.toString(), jsonEncode(json), DateTime.now());
        return MatchGame.fromJson(json);
      });

  Future<MatchGame> end(int id) => _guard(() async {
        final response = await _api.post<Map<String, dynamic>>(ApiConstants.matchEnd(id));
        final json = response.data!;
        await _db.upsertEntity('match', id.toString(), jsonEncode(json), DateTime.now());
        return MatchGame.fromJson(json);
      });

  /// Logs a live game event directly against the API — deliberately NOT
  /// routed through the offline outbox (`mutate`): the operator console
  /// needs the server-recalculated score back immediately, and there's no
  /// sane optimistic score to fake locally while offline. Throws [Failure]
  /// (including when offline) so the console can just show the error.
  ///
  /// `POST /matches/{id}/events` (`MatchController::addGameEvent`) only
  /// returns the created event, not the match/scores, so the match detail
  /// is re-fetched afterwards to pick up the recalculated score.
  Future<MatchGame> logEvent(
    int matchId, {
    required String jeu,
    required int teamId,
    required int playerId,
    required String temps,
  }) =>
      _guard(() async {
        await _api.post<Map<String, dynamic>>(
          ApiConstants.matchEvents(matchId),
          data: {
            'id_utilisateur': playerId,
            'id_equipe': teamId,
            'jeu': jeu,
            'temps': temps,
          },
        );
        return fetchAndCache(ApiConstants.matchById(matchId), matchId);
      });

  /// Validates/voids a logged event (`statut` 1/0) — owner or the match's
  /// announcer only (`MatchGame.canModerateEvents`). Also bypasses the
  /// outbox for the same immediate-feedback reason as [logEvent].
  Future<MatchGame> setEventStatus(int matchId, int eventId, {required bool valid}) => _guard(() async {
        await _api.put<Map<String, dynamic>>(
          ApiConstants.matchEventById(matchId, eventId),
          data: {'statut': valid ? 1 : 0},
        );
        return fetchAndCache(ApiConstants.matchById(matchId), matchId);
      });
}

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  final repo = MatchesRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'match',
        endpoint: ApiConstants.matches,
        extractItems: SyncableResource.laravelPage,
      ));
  return repo;
});
