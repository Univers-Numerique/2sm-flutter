import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';

/// Entities that can be followed (values of `etre_notifie.tables`).
class FollowTable {
  static const String team = 'equipes';
  static const String competition = 'competitions';
  static const String user = 'utilisateurs';
  static const String match = 'matchs';
}

class FollowStatus {
  final bool following;
  final int followersCount;
  const FollowStatus({required this.following, required this.followersCount});
}

class FollowKey {
  final String table;
  final int id;
  const FollowKey(this.table, this.id);

  @override
  bool operator ==(Object other) => other is FollowKey && other.table == table && other.id == id;

  @override
  int get hashCode => Object.hash(table, id);
}

/// Wraps `POST|DELETE /follow` and `GET /follow/status`.
class FollowRepository {
  final ApiClient _api;
  FollowRepository(this._api);

  Future<FollowStatus> status(FollowKey key) async {
    try {
      final r = await _api.get<Map<String, dynamic>>('/follow/status',
          queryParameters: {'tables': key.table, 'id_entre': key.id});
      final data = r.data ?? const {};
      return FollowStatus(
        following: data['following'] == true,
        followersCount: (data['followers_count'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> follow(FollowKey key) async {
    try {
      await _api.post('/follow', data: {'tables': key.table, 'id_entre': key.id});
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> unfollow(FollowKey key) async {
    try {
      await _api.delete('/follow', data: {'tables': key.table, 'id_entre': key.id});
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final followRepositoryProvider = Provider<FollowRepository>((ref) => FollowRepository(ref.watch(apiClientProvider)));

final followStatusProvider = FutureProvider.autoDispose.family<FollowStatus, FollowKey>((ref, key) {
  return ref.watch(followRepositoryProvider).status(key);
});
