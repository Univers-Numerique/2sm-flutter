import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Generic local mirror of any server entity (team, competition, match, ...).
/// Rather than hand-rolling one Drift table per domain (dozens of them, each
/// mostly a JSON blob anyway), every cached record is stored as a row here,
/// keyed by (entityType, entityId), with the full server JSON payload kept
/// as-is. Feature repositories decode their own model from [data] and can
/// filter in Dart after loading — the app's data volume (a single club's
/// teams/matches/activities) never justifies a fully normalized schema.
/// If a specific feature later needs indexed/filtered queries the generic
/// table can't do efficiently, add dedicated columns then — not speculatively
/// now.
class CachedEntities extends Table {
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get data => text()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  BoolColumn get deletedLocally => boolean().withDefault(const Constant(false))();

  // (entityType, entityId) as the actual primary key (rather than a
  // separate autoincrement id + a uniqueKeys constraint) so that
  // insertOnConflictUpdate's generated ON CONFLICT clause targets the right
  // columns — with a separate autoincrement id, every upsert of a
  // previously-synced row hit the *other* unique constraint as a real
  // SqliteException instead of updating, breaking sync for every resource
  // after the very first pull.
  @override
  Set<Column> get primaryKey => {entityType, entityId};
}

/// Write-ahead outbox: every local mutation made while offline (or optimistically
/// even while online) is recorded here and drained by SyncService against the
/// real API as soon as connectivity allows.
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get operation => text()(); // create | update | delete
  TextColumn get method => text()(); // HTTP method to use
  TextColumn get endpoint => text()(); // API path (may reference a local temp id)
  TextColumn get payload => text().nullable()(); // JSON body, if any
  TextColumn get localEntityId => text().nullable()(); // entityId in CachedEntities this op targets
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

/// Bookkeeping for incremental pulls (last successful sync time per entity type).
class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [CachedEntities, PendingOperations, SyncMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Schema v1's CachedEntities had a broken key shape (see the
            // primaryKey doc comment above) — the table only ever held
            // disposable, re-fetchable server cache, so recreate it rather
            // than attempt a data-preserving migration.
            await m.deleteTable('cached_entities');
            await m.createTable(cachedEntities);
          }
        },
      );

  // ---- CachedEntities helpers ----

  Future<void> upsertEntity(String type, String id, String jsonData, DateTime updatedAt) {
    return into(cachedEntities).insertOnConflictUpdate(
      CachedEntitiesCompanion.insert(
        entityType: type,
        entityId: id,
        data: jsonData,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<List<CachedEntity>> allOfType(String type) {
    return (select(cachedEntities)
          ..where((t) => t.entityType.equals(type) & t.deletedLocally.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Stream<List<CachedEntity>> watchAllOfType(String type) {
    return (select(cachedEntities)
          ..where((t) => t.entityType.equals(type) & t.deletedLocally.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<CachedEntity?> findOne(String type, String id) {
    return (select(cachedEntities)..where((t) => t.entityType.equals(type) & t.entityId.equals(id)))
        .getSingleOrNull();
  }

  Future<void> markDeletedLocally(String type, String id) {
    return (update(cachedEntities)..where((t) => t.entityType.equals(type) & t.entityId.equals(id)))
        .write(const CachedEntitiesCompanion(deletedLocally: Value(true)));
  }

  // ---- PendingOperations (outbox) helpers ----

  Future<int> enqueueOperation({
    required String entityType,
    required String operation,
    required String method,
    required String endpoint,
    String? payload,
    String? localEntityId,
  }) {
    return into(pendingOperations).insert(
      PendingOperationsCompanion.insert(
        entityType: entityType,
        operation: operation,
        method: method,
        endpoint: endpoint,
        payload: Value(payload),
        localEntityId: Value(localEntityId),
      ),
    );
  }

  Future<List<PendingOperation>> pendingOps() {
    return (select(pendingOperations)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  Future<void> removeOperation(int id) {
    return (delete(pendingOperations)..where((t) => t.id.equals(id))).go();
  }

  Future<void> recordOperationFailure(int id, String error) {
    return (update(pendingOperations)..where((t) => t.id.equals(id))).write(
      PendingOperationsCompanion(
        lastError: Value(error),
      ),
    );
  }

  Stream<int> watchPendingCount() {
    final query = selectOnly(pendingOperations)..addColumns([pendingOperations.id.count()]);
    return query.map((row) => row.read(pendingOperations.id.count()) ?? 0).watchSingle();
  }

  // ---- SyncMeta helpers ----

  Future<DateTime?> lastSyncedAt(String entityType) async {
    final row = await (select(syncMeta)..where((t) => t.key.equals('last_sync_$entityType'))).getSingleOrNull();
    if (row == null) return null;
    return DateTime.tryParse(row.value);
  }

  Future<void> setLastSyncedAt(String entityType, DateTime time) {
    return into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(key: 'last_sync_$entityType', value: time.toIso8601String()),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, '2sm_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
