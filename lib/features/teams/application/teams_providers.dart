import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/team.dart';
import '../data/models/team_dashboard.dart';
import '../data/models/team_member.dart';
import '../data/teams_repository.dart';

final teamsListProvider = StreamProvider.autoDispose<List<Team>>((ref) {
  return ref.watch(teamsRepositoryProvider).watchAll();
});

final teamDetailProvider = FutureProvider.autoDispose.family<Team, int>((ref, id) {
  return ref.watch(teamsRepositoryProvider).fetchDetail(id);
});

final teamMembersProvider = FutureProvider.autoDispose.family<List<TeamMember>, int>((ref, teamId) {
  return ref.watch(teamsRepositoryProvider).members(teamId);
});

final teamDashboardProvider = FutureProvider.autoDispose.family<TeamDashboard, int>((ref, teamId) async {
  final repo = ref.watch(teamsRepositoryProvider);
  try {
    return await repo.dashboard(teamId);
  } catch (_) {
    // Non-members can't read the dashboard: degrade to whatever
    // `GET /teams/{id}/statistics` allows, then to the public detail block.
    TeamStatistics stats;
    try {
      stats = await repo.statistics(teamId);
    } catch (_) {
      stats = (await ref.watch(teamDetailProvider(teamId).future)).statistics ?? const TeamStatistics();
    }
    return TeamDashboard(
      stats: DashboardStats(
        matchesPlayed: stats.totalMatches,
        wins: stats.wins,
        draws: stats.draws,
        defeats: stats.defeats,
        goalsScored: stats.goalsFor,
        goalsConceded: stats.goalsAgainst,
        points: stats.points,
      ),
    );
  }
});

final teamMemberStatsProvider = FutureProvider.autoDispose.family<MemberStatsBundle, int>((ref, teamId) {
  return ref.watch(teamsRepositoryProvider).memberStats(teamId);
});
