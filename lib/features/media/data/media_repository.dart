import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'models/media_item.dart';

/// `GET /media`, `POST /media` (multipart), `POST /media/{id}/like`.
class MediaRepository {
  final ApiClient _api;
  MediaRepository(this._api);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// Médias rattachés à une entité (ex. `tables: 'matchs', entityId: 12`).
  Future<List<MediaItem>> list({String? tables, int? entityId, int? userId}) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>('/media', queryParameters: {
          if (tables != null) 'tables': tables,
          if (entityId != null) 'id_entre': entityId,
          if (userId != null) 'id_utilisateur': userId,
          'per_page': 100,
        });
        final data = r.data?['data'];
        return (data is List ? data : const [])
            .whereType<Map>()
            .map((e) => MediaItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });

  Future<MediaItem> upload({
    required File file,
    String? tables,
    int? entityId,
    int? eventId,
    String? commentaire,
  }) =>
      _guard(() async {
        final form = FormData.fromMap({
          'fichier': await MultipartFile.fromFile(file.path),
          'type': 'photo',
          if (tables != null) 'tables': tables,
          if (entityId != null) 'id_entre': entityId,
          if (eventId != null) 'id_evenement': eventId,
          if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
        });
        final r = await _api.uploadFile<Map<String, dynamic>>('/media', formData: form);
        return MediaItem.fromJson(r.data ?? const {});
      });

  /// Bascule le like ; renvoie (liked, likesCount).
  Future<({bool liked, int count})> toggleLike(int id) => _guard(() async {
        final r = await _api.post<Map<String, dynamic>>('/media/$id/like');
        return (liked: r.data?['liked'] == true, count: (r.data?['likes_count'] as num?)?.toInt() ?? 0);
      });
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) => MediaRepository(ref.watch(apiClientProvider)));
