import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activities_repository.dart';
import '../data/models/activity.dart';
import '../data/models/activity_report.dart';
import '../data/models/activity_task.dart';

final activitiesListProvider = StreamProvider.autoDispose<List<Activity>>((ref) {
  return ref.watch(activitiesRepositoryProvider).watchAll();
});

final activityDetailProvider = FutureProvider.autoDispose.family<Activity, int>((ref, id) {
  return ref.watch(activitiesRepositoryProvider).fetchDetail(id);
});

final activityTasksProvider = FutureProvider.autoDispose.family<List<ActivityTask>, int>((ref, activityId) {
  return ref.watch(activitiesRepositoryProvider).tasks(activityId);
});

final activityReportsProvider = FutureProvider.autoDispose.family<List<ActivityReport>, int>((ref, activityId) {
  return ref.watch(activitiesRepositoryProvider).reports(activityId);
});

final myActivitiesProvider = FutureProvider.autoDispose<List<Activity>>((ref) {
  return ref.watch(activitiesRepositoryProvider).myActivities();
});

class ActivityFilter {
  final int? teamId;
  final int? statut;

  const ActivityFilter({this.teamId, this.statut});

  ActivityFilter copyWith({int? teamId, bool clearTeamId = false, int? statut, bool clearStatut = false}) {
    return ActivityFilter(
      teamId: clearTeamId ? null : (teamId ?? this.teamId),
      statut: clearStatut ? null : (statut ?? this.statut),
    );
  }

  bool get isEmpty => teamId == null && statut == null;
}

final activityFilterProvider = StateProvider.autoDispose<ActivityFilter>((ref) => const ActivityFilter());

/// Browses activities from the API with `past=1` always set (the endpoint
/// excludes past activities by default) so this list screen shows the full
/// history, not just what's upcoming.
final filteredActivitiesProvider = FutureProvider.autoDispose<List<Activity>>((ref) {
  final filter = ref.watch(activityFilterProvider);
  final repo = ref.watch(activitiesRepositoryProvider);
  return repo.search(teamId: filter.teamId, statut: filter.statut, past: true);
});
