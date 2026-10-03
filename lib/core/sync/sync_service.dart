import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';

/// Describes how one entity type is pulled from the API into the local cache.
class SyncableResource {
  final String entityType;
  final String endpoint;
  final String idField;
  final String updatedAtField;

  /// Given a page of the API's paginated `index` response, return the list
  /// of raw entity JSON objects (Laravel's `paginate()` wraps them in `data`).
  final List<Map<String, dynamic>> Function(Map<String, dynamic> responseBody) extractItems;

  /// Optional hook fired with the raw JSON of every item just pulled and
  /// cached for this resource (created or updated since the last sync).
  /// [SyncService] itself has no opinion on what a feature does with these —
  /// it's the mechanism [NotificationsRepository] uses to detect and surface
  /// newly-arrived notifications as local notifications without the generic
  /// sync layer knowing anything about that UI concern.
  final void Function(List<Map<String, dynamic>> items)? onItemsPulled;

  /// Données propres au compte connecté (messagerie, notifications) : jamais
  /// demandées pour un visiteur, qui consulte l'application sans compte.
  final bool personal;

  const SyncableResource({
    required this.entityType,
    required this.endpoint,
    this.idField = 'id',
    this.updatedAtField = 'updated_at',
    required this.extractItems,
    this.onItemsPulled,
    this.personal = false,
  });

  static List<Map<String, dynamic>> laravelPage(Map<String, dynamic> body) {
    final data = body['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }
}

enum SyncStatus { idle, syncing, offline, error }

/// Drains the local outbox to the API and pulls fresh data whenever
/// connectivity allows — the only place in the app that talks to both the
/// local database and the network for existing cached data. Feature
/// repositories register their resource with [registerResource] once, then
/// only ever read/write [AppDatabase] directly; this service keeps it honest.
class SyncService {
  final AppDatabase _db;
  final ApiClient _api;
  final _resources = <SyncableResource>[];
  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  SyncService(this._db, this._api) {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncNow();
      } else {
        _statusController.add(SyncStatus.offline);
      }
    });
  }

  Stream<SyncStatus> get statusStream => _statusController.stream;

  void registerResource(SyncableResource resource) {
    _resources.add(resource);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }

  /// Drains the outbox first (so local edits reach the server before we pull
  /// a fresh snapshot back over them), then pulls every registered resource.
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        _statusController.add(SyncStatus.offline);
        return;
      }

      if (_api.authToken != null) await _drainOutbox(); // envois en attente : toujours ceux d'un compte
      for (final resource in _resources) {
        if (resource.personal && _api.authToken == null) continue;
        try {
          await _pull(resource);
        } on DioException catch (e) {
          // Données personnelles refusées (session expirée) : la déconnexion
          // est gérée par l'intercepteur, ce n'est pas une panne de synchro.
          if (resource.personal && e.response?.statusCode == 401) continue;
          rethrow;
        }
      }
      _statusController.add(SyncStatus.idle);
    } catch (e, stackTrace) {
      // A silent catch here previously made every sync failure
      // undiagnosable — always surface at least this much.
      debugPrint('SyncService.syncNow failed: $e\n$stackTrace');
      _statusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _drainOutbox() async {
    final ops = await _db.pendingOps();
    for (final op in ops) {
      try {
        await _api.dio.request(
          op.endpoint,
          data: op.payload != null ? jsonDecode(op.payload!) : null,
          options: Options(method: op.method),
        );
        await _db.removeOperation(op.id);
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status != null && status >= 400 && status < 500) {
          // Business-rule rejection (validation, ownership, 404...) — this
          // operation will never succeed as-is, drop it rather than retry
          // forever, but keep the error visible for the user to inspect.
          await _db.recordOperationFailure(op.id, e.message ?? 'Erreur $status');
          await _db.removeOperation(op.id);
        } else {
          // Network/server error: stop draining, we'll retry the whole
          // queue on the next connectivity event rather than skip ahead.
          await _db.recordOperationFailure(op.id, e.message ?? 'Erreur réseau');
          rethrow;
        }
      }
    }
  }

  Future<void> _pull(SyncableResource resource) async {
    final since = await _db.lastSyncedAt(resource.entityType);
    final response = await _api.get<Map<String, dynamic>>(
      resource.endpoint,
      queryParameters: since != null ? {'updated_since': since.toIso8601String()} : null,
    );
    final body = response.data;
    if (body == null) return;

    final items = resource.extractItems(body);
    DateTime latest = since ?? DateTime.fromMillisecondsSinceEpoch(0);
    for (final item in items) {
      final id = item[resource.idField].toString();
      final updatedAtRaw = item[resource.updatedAtField]?.toString();
      final updatedAt = updatedAtRaw != null ? (DateTime.tryParse(updatedAtRaw) ?? DateTime.now()) : DateTime.now();
      await _db.upsertEntity(resource.entityType, id, jsonEncode(item), updatedAt);
      if (updatedAt.isAfter(latest)) latest = updatedAt;
    }
    await _db.setLastSyncedAt(resource.entityType, latest);
    if (items.isNotEmpty) resource.onItemsPulled?.call(items);
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final api = ref.watch(apiClientProvider);
  final service = SyncService(db, api);
  ref.onDispose(service.dispose);
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncServiceProvider).statusStream;
});
