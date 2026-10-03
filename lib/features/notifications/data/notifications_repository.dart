import 'package:dio/dio.dart';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/sync/sync_service.dart';
import 'models/app_notification.dart';

class NotificationsRepository extends LocalFirstRepository<AppNotification> {
  final ApiClient _api;

  NotificationsRepository(AppDatabase db, ApiClient api)
      : _api = api,
        super(
          db: db,
          api: api,
          entityType: 'notification',
          fromJson: AppNotification.fromJson,
          toJson: (n) => n.toJson(),
          idOf: (n) => n.id.toString(),
        );

  /// Marks one notification read on the server, then patches the cached
  /// copy's `_read_local` flag so the UI updates immediately — see the doc
  /// comment on [AppNotification] for why the server's own list response
  /// can't tell us this directly.
  Future<void> markRead(int id) async {
    await _api.put(ApiConstants.notificationRead(id));
    final cached = await findById(id);
    if (cached != null) {
      final json = cached.toJson();
      json['_read_local'] = true;
      await db.upsertEntity(entityType, id.toString(), jsonEncode(json), DateTime.now());
    }
  }

  Future<void> markAllRead() async {
    await _api.put(ApiConstants.notificationsReadAll);
    final all = await this.all();
    for (final n in all) {
      final json = n.toJson();
      json['_read_local'] = true;
      await db.upsertEntity(entityType, n.id.toString(), jsonEncode(json), DateTime.now());
    }
  }

  /// `GET /notifications/{id}` - fresh copy with the embedded proposition.
  Future<AppNotification> fetchDetail(int id) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(ApiConstants.notificationById(id));
      return AppNotification.fromJson(response.data!);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<int> unreadCount() async {
    final response = await _api.get<Map<String, dynamic>>(ApiConstants.notificationsUnreadCount);
    return (response.data?['count'] as num?)?.toInt() ?? 0;
  }

  /// Accepts (statut=1) or refuses (statut=2) a friendly-match proposition,
  /// per PropositionController::update — confirmed against
  /// app/Http/Controllers/Api/PropositionController.php. Only reachable
  /// from a notification whose `id_proposition` is set, which in practice
  /// doesn't currently happen (see [AppNotification.idProposition]).
  Future<void> respondToProposition(int propositionId, {required bool accept}) {
    return _api.put(ApiConstants.propositionById(propositionId), data: {'statut': accept ? 1 : 2});
  }

  static const _lastNotifiedIdKey = 'notifications_last_notified_id';

  /// Called by [SyncService] (via the `onItemsPulled` hook registered below)
  /// with the raw JSON of every notification just created or updated since
  /// the last sync. Fires one local notification per genuinely new, unread
  /// item — "new" meaning an id past the highest one this device has already
  /// surfaced, tracked as a watermark in [SharedPreferences] rather than by
  /// diffing against the cache (the pulled items have already been upserted
  /// into it by the time this runs, so the old copies are gone).
  ///
  /// On the very first sync ever (no watermark stored yet), the watermark is
  /// just initialized to the current max id without notifying — otherwise a
  /// fresh install would immediately fire a notification for the user's
  /// entire notification history.
  Future<void> _notifyNewItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final lastNotifiedId = prefs.getInt(_lastNotifiedIdKey);

    final sorted = List<Map<String, dynamic>>.from(items)
      ..sort((a, b) => ((a['id'] as num?) ?? 0).compareTo((b['id'] as num?) ?? 0));
    final maxId = ((sorted.last['id'] as num?) ?? 0).toInt();

    if (lastNotifiedId == null) {
      // First run: don't spam the user with pre-existing history.
      await prefs.setInt(_lastNotifiedIdKey, maxId);
      return;
    }

    for (final item in sorted) {
      final id = ((item['id'] as num?) ?? 0).toInt();
      if (id <= lastNotifiedId) continue;
      final statutLecture = item['statut_lecture']?.toString() ?? 'non lu';
      if (statutLecture == 'lu') continue;

      final title = item['titre']?.toString() ?? 'Nouvelle notification';
      final contenu = item['contenu']?.toString() ?? item['contenu_publication']?.toString() ?? '';
      await LocalNotificationsService.instance.show(id: id, title: title, body: _truncate(contenu, 140));
    }

    await prefs.setInt(_lastNotifiedIdKey, maxId);
  }

  static String _truncate(String text, int maxLength) {
    return text.length <= maxLength ? text : '${text.substring(0, maxLength)}…';
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final repo = NotificationsRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'notification',
        endpoint: ApiConstants.notifications,
        extractItems: SyncableResource.laravelPage,
        onItemsPulled: repo._notifyNewItems,
        personal: true,
      ));
  return repo;
});
