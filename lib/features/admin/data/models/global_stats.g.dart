// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlobalStats _$GlobalStatsFromJson(Map<String, dynamic> json) => GlobalStats(
  usersCount: (json['users_count'] as num?)?.toInt() ?? 0,
  teamsCount: (json['teams_count'] as num?)?.toInt() ?? 0,
  competitionsCount: (json['competitions_count'] as num?)?.toInt() ?? 0,
  matchesCount: (json['matches_count'] as num?)?.toInt() ?? 0,
  fieldsCount: (json['fields_count'] as num?)?.toInt() ?? 0,
  matchesToday: (json['matches_today'] as num?)?.toInt() ?? 0,
  newUsersThisMonth: (json['new_users_this_month'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$GlobalStatsToJson(GlobalStats instance) =>
    <String, dynamic>{
      'users_count': instance.usersCount,
      'teams_count': instance.teamsCount,
      'competitions_count': instance.competitionsCount,
      'matches_count': instance.matchesCount,
      'fields_count': instance.fieldsCount,
      'matches_today': instance.matchesToday,
      'new_users_this_month': instance.newUsersThisMonth,
    };
