import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../activities/data/models/activity.dart';
import '../../admin/data/admin_endpoints.dart';
import '../../matches/data/models/match_game.dart';

/// Matches + activities returned by `GET /calendar` (the API counterpart of
/// the legacy `assets/php/get.php` `table=CALENDRIER` feed).
class CalendarData {
  final List<MatchGame> matches;
  final List<Activity> activities;
  const CalendarData({this.matches = const [], this.activities = const []});
}

class CalendarRepository {
  final ApiClient _api;
  CalendarRepository(this._api);

  static final _ymd = DateFormat('yyyy-MM-dd');

  Future<CalendarData> fetch({
    required DateTime from,
    required DateTime to,
    int? teamId,
    int? competitionId,
    String? search,
  }) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        AdminEndpoints.calendar,
        queryParameters: {
          'from': _ymd.format(from),
          'to': _ymd.format(to),
          'team_id': ?teamId,
          'competition_id': ?competitionId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final data = response.data ?? const {};
      final matches = (data['matches'] as List<dynamic>? ?? const [])
          .map((e) => MatchGame.fromJson(e as Map<String, dynamic>))
          .toList();
      final activities = (data['activities'] as List<dynamic>? ?? const [])
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList();
      return CalendarData(matches: matches, activities: activities);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(apiClientProvider));
});
