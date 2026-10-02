import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar_repository.dart';

/// Which events the calendar shows — the three legacy variants:
/// `compte/calendrier.php` (global), `manage/equipes/calendrier.php` (team)
/// and `manage/competitions/calendrier.php` (competition).
enum CalendarScope { global, team, competition }

class CalendarFilter {
  final CalendarScope scope;
  final int? teamId;
  final int? competitionId;
  final String search;
  final DateTime month;

  const CalendarFilter({
    this.scope = CalendarScope.global,
    this.teamId,
    this.competitionId,
    this.search = '',
    required this.month,
  });

  CalendarFilter copyWith({
    CalendarScope? scope,
    int? teamId,
    bool clearTeam = false,
    int? competitionId,
    bool clearCompetition = false,
    String? search,
    DateTime? month,
  }) {
    return CalendarFilter(
      scope: scope ?? this.scope,
      teamId: clearTeam ? null : (teamId ?? this.teamId),
      competitionId: clearCompetition ? null : (competitionId ?? this.competitionId),
      search: search ?? this.search,
      month: month ?? this.month,
    );
  }
}

final calendarFilterProvider = StateProvider.autoDispose<CalendarFilter>((ref) {
  final now = DateTime.now();
  return CalendarFilter(month: DateTime(now.year, now.month));
});

/// Events of the visible month (grid padded to full weeks) for the current
/// filter. The month is part of the request so navigation stays cheap.
final calendarDataProvider = FutureProvider.autoDispose<CalendarData>((ref) {
  final f = ref.watch(calendarFilterProvider);
  final first = DateTime(f.month.year, f.month.month, 1);
  final from = first.subtract(Duration(days: first.weekday - 1));
  final last = DateTime(f.month.year, f.month.month + 1, 0);
  final to = last.add(Duration(days: 7 - last.weekday));
  return ref.watch(calendarRepositoryProvider).fetch(
        from: from,
        to: to,
        teamId: f.scope == CalendarScope.team ? f.teamId : null,
        competitionId: f.scope == CalendarScope.competition ? f.competitionId : null,
        search: f.search,
      );
});
