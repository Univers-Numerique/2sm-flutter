import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_service.dart';
import 'models/news.dart';
import 'models/news_comment.dart';

class NewsRepository extends LocalFirstRepository<News> {
  final ApiClient _api;

  NewsRepository(AppDatabase db, ApiClient api)
      : _api = api,
        super(
          db: db,
          api: api,
          entityType: 'news',
          fromJson: News.fromJson,
          toJson: (n) => n.toJson(),
          idOf: (n) => n.id.toString(),
        );

  /// Full detail (with comments) — the list endpoint doesn't embed comments.
  Future<News> fetchDetail(int id) => fetchAndCache(ApiConstants.newsById(id), id);

  Future<News> create(String contenu) async {
    final result = await mutate(
      operation: 'create',
      method: 'POST',
      endpoint: ApiConstants.news,
      payload: {'contenu': contenu},
      optimisticJson: () => {
        'id': -DateTime.now().millisecondsSinceEpoch,
        'id_utilisateur': 0,
        'contenu': contenu,
        'statut': 1,
        'comments_count': 0,
        'likes_count': 0,
      },
    );
    return result!;
  }

  Future<News> update(int id, String contenu) async {
    final result = await mutate(
      operation: 'update',
      method: 'PUT',
      endpoint: ApiConstants.newsById(id),
      existingId: id.toString(),
      payload: {'contenu': contenu},
      optimisticJson: () => {
        'id': id,
        'id_utilisateur': 0,
        'contenu': contenu,
        'statut': 1,
      },
    );
    return result!;
  }

  Future<void> delete(int id) => mutate(
        operation: 'delete',
        method: 'DELETE',
        endpoint: ApiConstants.newsById(id),
        existingId: id.toString(),
        optimisticJson: () => {},
      );

  /// Toggles the current user's like. The API only returns `{liked: bool}`
  /// (no full record, no per-user flag on later GETs), so the cached row's
  /// `likes_count` and the client-only `_liked_local` flag are patched by
  /// hand right after a successful call.
  Future<bool> toggleLike(int newsId) async {
    final response = await _api.post<Map<String, dynamic>>(ApiConstants.newsLike(newsId));
    final liked = (response.data?['liked'] as bool?) ?? false;

    final cached = await findById(newsId);
    if (cached != null) {
      final delta = liked ? 1 : -1;
      final json = cached.toJson();
      json['likes_count'] = (cached.likesCount + delta).clamp(0, 1 << 30);
      json['_liked_local'] = liked;
      json['liked'] = liked;
      await db.upsertEntity(entityType, newsId.toString(), jsonEncode(json), DateTime.now());
    }
    return liked;
  }

  Future<NewsComment> addComment(int newsId, String contenu) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.newsComments(newsId),
      data: {'contenu': contenu},
    );
    final comment = NewsComment.fromJson(response.data!);

    final cached = await findById(newsId);
    if (cached != null) {
      final json = cached.toJson();
      json['comments_count'] = cached.commentsCount + 1;
      await db.upsertEntity(entityType, newsId.toString(), jsonEncode(json), DateTime.now());
    }
    return comment;
  }
}

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  final repo = NewsRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'news',
        endpoint: ApiConstants.news,
        extractItems: SyncableResource.laravelPage,
      ));
  return repo;
});
