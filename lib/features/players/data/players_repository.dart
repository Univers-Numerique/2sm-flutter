import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'models/player.dart';

class UserQuery {
  final String search;
  final String? genre;
  final String? poste;
  final String? categorie;
  final int page;
  const UserQuery({this.search = '', this.genre, this.poste, this.categorie, this.page = 1});

  @override
  bool operator ==(Object other) =>
      other is UserQuery &&
      other.search == search &&
      other.genre == genre &&
      other.poste == poste &&
      other.categorie == categorie &&
      other.page == page;

  @override
  int get hashCode => Object.hash(search, genre, poste, categorie, page);
}

/// Users, positions, performances and statistics endpoints (transient data,
/// so plain Dio wrappers rather than a local-first repository).
class PlayersRepository {
  final ApiClient _api;
  PlayersRepository(this._api);

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// `GET /users` (search / genre / statut, paginated by 20).
  Future<UserPage> users(UserQuery q) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>(ApiConstants.users, queryParameters: {
          if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
          if (q.genre != null && q.genre!.isNotEmpty) 'genre': q.genre,
          if (q.poste != null && q.poste!.isNotEmpty) 'poste': q.poste,
          if (q.categorie != null && q.categorie!.isNotEmpty) 'categorie': q.categorie,
          'page': q.page,
        });
        return UserPage.fromJson(r.data!);
      });

  /// `GET /users/{id}` (with positions + teams).
  Future<PlayerUser> user(int id) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>(ApiConstants.userById(id));
        return PlayerUser.fromJson(r.data!);
      });

  /// `GET /users/{id}/positions`
  Future<List<PlayerPosition>> positions(int id) => _guard(() async {
        final r = await _api.get<List<dynamic>>(ApiConstants.userPositions(id));
        return (r.data ?? []).map((e) => PlayerPosition.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      });

  /// `GET /users/{id}/performances` (history, newest first).
  Future<List<Skill>> performances(int id, {int page = 1}) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>(ApiConstants.userPerformances(id), queryParameters: {'page': page});
        return ((r.data?['data'] as List?) ?? const [])
            .map((e) => Skill.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  /// `GET /users/{id}/statistics`
  Future<UserStats> statistics(int id) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>(ApiConstants.userStatistics(id));
        return UserStats.fromJson(r.data!);
      });

  /// `POST /users/{id}/performances` — set a skill value (0-100).
  Future<void> addPerformance(
    int userId, {
    int? activityId,
    int? teamId,
    required String performance,
    required num valeur,
    String? categorie,
    String? type,
  }) =>
      _guard(() async {
        await _api.post(ApiConstants.userPerformances(userId), data: {
          'id_activite': ?activityId,
          'id_equipe': ?teamId,
          'performance': performance,
          'valeur': valeur,
          'categorie': ?categorie,
          'type': ?type,
        });
      });
}

final playersRepositoryProvider = Provider<PlayersRepository>((ref) => PlayersRepository(ref.watch(apiClientProvider)));
