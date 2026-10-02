import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../../core/sync/sync_service.dart';
import 'models/activity.dart';
import 'models/activity_report.dart';
import 'models/activity_task.dart';

class ActivitiesRepository extends LocalFirstRepository<Activity> {
  final ApiClient _api;
  final AppDatabase _db;

  ActivitiesRepository(AppDatabase db, ApiClient api)
      : _api = api,
        _db = db,
        super(
          db: db,
          api: api,
          entityType: 'activity',
          fromJson: Activity.fromJson,
          toJson: (a) => a.toJson(),
          idOf: (a) => a.id.toString(),
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

  Future<Activity> fetchDetail(int id) => _guard(() => fetchAndCache(ApiConstants.activityById(id), id));

  Future<List<Activity>> myActivities() => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(ApiConstants.myActivities);
        final items = SyncableResource.laravelPage(response.data ?? const {});
        return items.map(Activity.fromJson).toList();
      });

  /// Browses activities straight from the API with server-side filters
  /// (bypassing the cached unfiltered list so filters/`past` combinations
  /// don't depend on what happens to already be cached) — each result is
  /// also mirrored into the local cache so offline detail views still work.
  Future<List<Activity>> search({int? teamId, int? statut, bool past = false}) => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(
          ApiConstants.activities,
          queryParameters: {
            if (teamId != null) 'equipe_id': teamId,
            if (statut != null) 'statut': statut,
            if (past) 'past': 1,
          },
        );
        final items = SyncableResource.laravelPage(response.data ?? const {});
        for (final item in items) {
          await _db.upsertEntity('activity', item['id'].toString(), jsonEncode(item), DateTime.now());
        }
        return items.map(Activity.fromJson).toList();
      });

  Future<Activity> create({
    required String titre,
    String? contenu,
    required String date,
    String? heure,
    String? lieu,
    String? categorie,
    String? genre,
    int? teamId,
  }) =>
      _guard(() async {
        final result = await mutate(
          operation: 'create',
          method: 'POST',
          endpoint: ApiConstants.activities,
          payload: {
            'titre': titre,
            if (contenu != null) 'contenu': contenu,
            'date': date,
            if (heure != null) 'heure': heure,
            if (lieu != null && lieu.isNotEmpty) 'lieu': lieu,
            if (categorie != null && categorie.isNotEmpty) 'categorie': categorie,
            if (genre != null && genre.isNotEmpty) 'genre': genre,
            if (teamId != null) 'id_equipe': teamId,
          },
          optimisticJson: () => {
            'id': -DateTime.now().millisecondsSinceEpoch,
            'id_utilisateur': 0,
            'id_equipe': teamId,
            'titre': titre,
            'contenu': contenu,
            'date': date,
            'heure': heure,
            'statut': 1,
          },
        );
        return result!;
      });

  Future<Activity> update(
    int id, {
    String? titre,
    String? contenu,
    String? date,
    String? heure,
    String? lieu,
    String? categorie,
    String? genre,
    int? statut,
  }) =>
      _guard(() async {
        final result = await mutate(
          operation: 'update',
          method: 'PUT',
          endpoint: ApiConstants.activityById(id),
          existingId: id.toString(),
          payload: {
            if (titre != null) 'titre': titre,
            if (contenu != null) 'contenu': contenu,
            if (date != null) 'date': date,
            if (heure != null) 'heure': heure,
            if (lieu != null) 'lieu': lieu,
            if (categorie != null) 'categorie': categorie,
            if (genre != null) 'genre': genre,
            if (statut != null) 'statut': statut,
          },
          optimisticJson: () => {
            'id': id,
            'titre': titre,
            'contenu': contenu,
            'date': date,
            'heure': heure,
            'statut': statut ?? 0,
          },
        );
        return result!;
      });

  Future<void> delete(int id) => _guard(() => mutate(
        operation: 'delete',
        method: 'DELETE',
        endpoint: ApiConstants.activityById(id),
        existingId: id.toString(),
        optimisticJson: () => {},
      ));

  /// Owner-only Commencer/Terminer/Annuler controls — a thin convenience
  /// over [update] which is also the endpoint that accepts `statut`.
  Future<Activity> setStatus(int id, int statut) => update(id, statut: statut);

  // ---- Participation / attendance — simple toggles, not routed through the
  // create/update/delete outbox since they aren't mutations of the activity
  // entity itself, and need to reflect the server's state immediately. ----

  Future<void> join(int activityId) => _guard(() => _api.post(ApiConstants.activityJoin(activityId)));

  Future<void> leave(int activityId) => _guard(() => _api.delete(ApiConstants.activityJoin(activityId)));

  /// Toggles the *current* user's own presence. Note: the real
  /// `PUT /activities/{id}/attendance` endpoint always targets `Auth::id()`
  /// server-side — there is no parameter to target another participant, so
  /// an owner cannot mark someone else present/absent through this call.
  Future<bool> setAttendance(int activityId, {required bool present, int? userId}) => _guard(() async {
        final response = await _api.put<Map<String, dynamic>>(
          ApiConstants.activityAttendance(activityId),
          data: {'present': present, if (userId != null) 'id_utilisateur': userId},
        );
        return (response.data?['present'] as bool?) ?? present;
      });

  Future<List<ActivityReport>> reports(int activityId) => _guard(() async {
        final response = await _api.get<List<dynamic>>('${ApiConstants.activityById(activityId)}/reports');
        return (response.data ?? const []).map((e) => ActivityReport.fromJson(e as Map<String, dynamic>)).toList();
      });

  // ---- Tasks ----

  Future<List<ActivityTask>> tasks(int activityId) => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(ApiConstants.activityTasks(activityId));
        final items = SyncableResource.laravelPage(response.data ?? const {});
        return items.map(ActivityTask.fromJson).toList();
      });

  Future<ActivityTask> createTask(
    int activityId, {
    required int assigneeId,
    required String tache,
    int? teamId,
  }) =>
      _guard(() async {
        final response = await _api.post<Map<String, dynamic>>(
          ApiConstants.activityTasks(activityId),
          data: {
            'id_utilisateur': assigneeId,
            'tache': tache,
            if (teamId != null) 'id_equipe': teamId,
          },
        );
        return ActivityTask.fromJson(response.data!);
      });

  Future<ActivityTask> updateTask(int taskId, {int? assigneeId, String? tache}) => _guard(() async {
        final response = await _api.put<Map<String, dynamic>>(
          ApiConstants.taskById(taskId),
          data: {
            if (assigneeId != null) 'id_utilisateur': assigneeId,
            if (tache != null) 'tache': tache,
          },
        );
        return ActivityTask.fromJson(response.data!);
      });

  Future<ActivityTask> setTaskStatus(int taskId, int statut) => _guard(() async {
        final response = await _api.put<Map<String, dynamic>>(
          ApiConstants.taskStatus(taskId),
          data: {'statut': statut},
        );
        return ActivityTask.fromJson(response.data!);
      });
}

final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  final repo = ActivitiesRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'activity',
        endpoint: ApiConstants.activities,
        extractItems: SyncableResource.laravelPage,
      ));
  return repo;
});
