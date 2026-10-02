import 'package:json_annotation/json_annotation.dart';

part 'global_stats.g.dart';

/// Mirrors `AdminController::globalStats` — `GET /stats`.
@JsonSerializable()
class GlobalStats {
  @JsonKey(name: 'users_count', defaultValue: 0)
  final int usersCount;
  @JsonKey(name: 'teams_count', defaultValue: 0)
  final int teamsCount;
  @JsonKey(name: 'competitions_count', defaultValue: 0)
  final int competitionsCount;
  @JsonKey(name: 'matches_count', defaultValue: 0)
  final int matchesCount;
  @JsonKey(name: 'fields_count', defaultValue: 0)
  final int fieldsCount;
  @JsonKey(name: 'matches_today', defaultValue: 0)
  final int matchesToday;
  @JsonKey(name: 'new_users_this_month', defaultValue: 0)
  final int newUsersThisMonth;

  const GlobalStats({
    this.usersCount = 0,
    this.teamsCount = 0,
    this.competitionsCount = 0,
    this.matchesCount = 0,
    this.fieldsCount = 0,
    this.matchesToday = 0,
    this.newUsersThisMonth = 0,
  });

  factory GlobalStats.fromJson(Map<String, dynamic> json) => _$GlobalStatsFromJson(json);
  Map<String, dynamic> toJson() => _$GlobalStatsToJson(this);
}
