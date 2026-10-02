import 'dart:convert';

import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/failure.dart';
import 'app_database.dart';

/// Base for every feature repository that follows the app's local-first
/// rule: the UI only ever reads [watchAll]/[watchOne] (backed by
/// [AppDatabase]'s [CachedEntities] table), and every mutation goes through
/// [mutate], which applies immediately over the network when possible and
/// falls back to the outbox ([PendingOperations]) when offline — the caller
/// never needs to branch on connectivity itself.
///
/// [T] is the feature's own model (e.g. `Team`), decoded from/to the raw
/// JSON stored in the cache row.
abstract class LocalFirstRepository<T> {
  final AppDatabase db;
  final ApiClient api;
  final String entityType;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;
  final String Function(T value) idOf;

  LocalFirstRepository({
    required this.db,
    required this.api,
    required this.entityType,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  });

  Stream<List<T>> watchAll() {
    return db.watchAllOfType(entityType).map(
          (rows) => rows.map((r) => fromJson(jsonDecode(r.data) as Map<String, dynamic>)).toList(),
        );
  }

  Future<List<T>> all() async {
    final rows = await db.allOfType(entityType);
    return rows.map((r) => fromJson(jsonDecode(r.data) as Map<String, dynamic>)).toList();
  }

  Future<T?> findById(Object id) async {
    final row = await db.findOne(entityType, id.toString());
    if (row == null) return null;
    return fromJson(jsonDecode(row.data) as Map<String, dynamic>);
  }

  /// Fetches a single record straight from the API (bypassing the cache) and
  /// stores the fresh copy — used for detail screens where the list's cached
  /// summary isn't rich enough (e.g. a team's full roster/statistics).
  Future<T> fetchAndCache(String endpoint, Object id) async {
    final response = await api.get<Map<String, dynamic>>(endpoint);
    final json = _unwrap(response.data!);
    final item = fromJson(json);
    await db.upsertEntity(entityType, idOf(item), jsonEncode(json), DateTime.now());
    return item;
  }

  /// Applies a create/update/delete. If the network call succeeds, the local
  /// cache is updated from the real response immediately. If it fails purely
  /// because we're offline, the same call is queued in the outbox and the
  /// cache is updated optimistically from [optimisticJson] so the UI
  /// reflects the change right away.
  Future<T?> mutate({
    required String operation, // create | update | delete
    required String method,
    required String endpoint,
    Map<String, dynamic>? payload,
    required Map<String, dynamic> Function() optimisticJson,
    String? existingId,
  }) async {
    try {
      final response = await api.dio.request<dynamic>(
        endpoint,
        data: payload,
        options: Options(method: method),
      );
      if (operation == 'delete') {
        if (existingId != null) await db.markDeletedLocally(entityType, existingId);
        return null;
      }
      final json = _unwrap(response.data as Map<String, dynamic>);
      final item = fromJson(json);
      await db.upsertEntity(entityType, idOf(item), jsonEncode(json), DateTime.now());
      return item;
    } on DioException catch (e) {
      final failure = Failure.fromDioException(e);
      if (!failure.isOffline) rethrow; // a real 4xx/5xx, not just "no network"

      final localId = existingId ?? 'local_${DateTime.now().microsecondsSinceEpoch}';
      await db.enqueueOperation(
        entityType: entityType,
        operation: operation,
        method: method,
        endpoint: endpoint,
        payload: payload != null ? jsonEncode(payload) : null,
        localEntityId: localId,
      );
      if (operation == 'delete') {
        await db.markDeletedLocally(entityType, localId);
        return null;
      }
      final optimistic = optimisticJson();
      final item = fromJson(optimistic);
      await db.upsertEntity(entityType, localId, jsonEncode(optimistic), DateTime.now());
      return item;
    }
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> body) {
    // Some endpoints wrap the record ({'user': {...}}), most return it directly.
    if (body.length == 1 && body.values.first is Map) {
      return Map<String, dynamic>.from(body.values.first as Map);
    }
    return body;
  }
}
