import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_service.dart';
import 'package:dio/dio.dart';

import '../../../core/network/failure.dart';
import 'models/conversation.dart';

/// Group conversations behave like Teams: a plain cached list, synced
/// through [LocalFirstRepository]. What happens *inside* an open
/// conversation is a different story — see the note on [ChatScreen] and in
/// the final report: the API currently has no endpoint to send or list
/// messages within a conversation, so this repository only covers the
/// container (create / list / add member), not a message thread.
class ConversationsRepository extends LocalFirstRepository<Conversation> {
  final ApiClient _api;

  ConversationsRepository(AppDatabase db, ApiClient api)
      : _api = api,
        super(
          db: db,
          api: api,
          entityType: 'conversation',
          fromJson: Conversation.fromJson,
          toJson: (c) => c.toJson(),
          idOf: (c) => c.id.toString(),
        );

  /// There is genuinely no `GET /conversations/{id}` route in the Laravel
  /// API (checked against routes/api.php — only index/store and the
  /// add-user endpoint exist), so a conversation's detail can only come
  /// from whatever the cached list already pulled in, not a fresh
  /// single-record fetch. Nor is there any endpoint to list a
  /// conversation's actual members (`POST .../users` only adds one), so a
  /// member roster can't be shown at all with the current backend.
  Future<Conversation?> cachedById(int id) => findById(id);

  Future<Conversation> create({
    required String sujet,
    String? description,
    required String type,
  }) async {
    final result = await mutate(
      operation: 'create',
      method: 'POST',
      endpoint: ApiConstants.conversations,
      payload: {
        'sujet': sujet,
        if (description != null && description.isNotEmpty) 'description': description,
        'type': type,
      },
      optimisticJson: () => {
        'id': -DateTime.now().millisecondsSinceEpoch,
        'id_utilisateur': 0,
        'sujet': sujet,
        'description': description,
        'type': type,
        'statut': '1',
      },
    );
    return result!;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> addUser(int conversationId, int userId) => _guard(
      () => _api.post(ApiConstants.conversationUsers(conversationId), data: {'id_utilisateur': userId}));

  /// Fresh group detail with members (`GET /conversations/{id}`).
  Future<Conversation> fetchDetail(int id) => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(ApiConstants.conversationById(id));
        return Conversation.fromJson(response.data!);
      });

  /// My groups with unread counters and last message (`GET /conversations`).
  Future<List<Conversation>> mine() => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(ApiConstants.conversations);
        final data = response.data?['data'] as List<dynamic>? ?? const [];
        return data.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
      });

  /// Directory of groups (`GET /conversations/discover`) - search + order.
  Future<List<Conversation>> discover({String search = '', bool descending = false}) => _guard(() async {
        final response = await _api.get<Map<String, dynamic>>(
          '${ApiConstants.conversations}/discover',
          queryParameters: {if (search.isNotEmpty) 'search': search, 'order': descending ? 'desc' : 'asc'},
        );
        final data = response.data?['data'] as List<dynamic>? ?? const [];
        return data.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<void> updateGroup(int id, {required String sujet, String? description, required String type}) =>
      _guard(() => _api.put(
            ApiConstants.conversationById(id),
            data: {'sujet': sujet, 'description': description ?? '', 'type': type},
          ));

  Future<void> join(int id) => _guard(() => _api.post('${ApiConstants.conversationById(id)}/join'));

  Future<void> leave(int id) => _guard(() => _api.post('${ApiConstants.conversationById(id)}/leave'));

  /// 0 = retirer, 1 = membre, 2 = nommer administrateur.
  Future<void> setMemberStatus(int id, int userId, int statut) =>
      _guard(() => _api.put('${ApiConstants.conversationById(id)}/users/$userId', data: {'statut': statut}));
}

final conversationsRepositoryProvider = Provider<ConversationsRepository>((ref) {
  final repo = ConversationsRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'conversation',
        endpoint: ApiConstants.conversations,
        extractItems: SyncableResource.laravelPage,
        personal: true,
      ));
  return repo;
});
