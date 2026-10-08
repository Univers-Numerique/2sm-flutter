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
  /// Types déjà entièrement rechargés depuis le lancement de l'application.
  final _fullySynced = <String>{};
  /// Garde-fou contre une pagination qui ne s'arrêterait pas.
  static const _maxPages = 50;
  final _statusController = StreamController<SyncStatus>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;
  bool _rerunRequested = false;

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
    // Les dépôts naissent quand leur écran s'ouvre, souvent après la
    // synchronisation du démarrage : synchroniser aussitôt la nouvelle ressource
    // plutôt que d'attendre un changement de connexion.
    scheduleMicrotask(syncNow);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
  }

  /// Drains the outbox first (so local edits reach the server before we pull
  /// a fresh snapshot back over them), then pulls every registered resource.
  Future<void> syncNow() async {
    if (_isSyncing) {
      // Demande arrivée pendant un passage (ex. ressource enregistrée trop tard
      // pour lui) : refaire un passage à la fin plutôt que de l'ignorer.
      _rerunRequested = true;
      return;
    }
    _isSyncing = true;
    _rerunRequested = false;
    _statusController.add(SyncStatus.syncing);
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        _statusController.add(SyncStatus.offline);
        return;
      }

      if (_api.authToken != null) await _drainOutbox(); // envois en attente : toujours ceux d'un compte
      // Parcours par index : un dépôt peut s'enregistrer pendant un `await`
      // (écran ouvert entre-temps) ; il est alors synchronisé dans ce passage
      // au lieu de faire échouer l'itération.
      for (var i = 0; i < _resources.length; i++) {
        final resource = _resources[i];
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
      if (_rerunRequested) scheduleMicrotask(syncNow);
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
    // Premier passage de la session : tout recharger. Le mode incrémental
    // (`updated_since`) ne rattrape ni un élément manqué auparavant, ni les
    // compteurs (vues, j'aime, commentaires) qui ne modifient pas `updated_at`.
    final full = !_fullySynced.contains(resource.entityType);
    final since = full ? null : await _db.lastSyncedAt(resource.entityType);
    final pulled = <Map<String, dynamic>>[];
    DateTime latest = since ?? DateTime.fromMillisecondsSinceEpoch(0);

    // L'API pagine (20 par page) : parcourir toutes les pages, pas seulement la première.
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _api.get<Map<String, dynamic>>(
        resource.endpoint,
        queryParameters: {
          if (since != null) 'updated_since': since.toIso8601String(),
          'page': page,
        },
      );
      final body = response.data;
      if (body == null) break;

      final items = resource.extractItems(body);
      for (final item in items) {
        final id = item[resource.idField].toString();
        final updatedAtRaw = item[resource.updatedAtField]?.toString();
        final updatedAt = updatedAtRaw != null ? (DateTime.tryParse(updatedAtRaw) ?? DateTime.now()) : DateTime.now();
        await _db.upsertEntity(resource.entityType, id, jsonEncode(item), updatedAt);
        if (updatedAt.isAfter(latest)) latest = updatedAt;
      }
      pulled.addAll(items);
      lastPage = (body['last_page'] as num?)?.toInt() ?? 1;
      page++;
    } while (page <= lastPage && page <= _maxPages);

    await _db.setLastSyncedAt(resource.entityType, latest);
    _fullySynced.add(resource.entityType);
    if (pulled.isNotEmpty) resource.onItemsPulled?.call(pulled);
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
