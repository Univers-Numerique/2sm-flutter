import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/competitions_repository.dart';
import '../data/models/competition.dart';
import '../data/models/competition_ranking.dart';

final competitionsListProvider = StreamProvider.autoDispose<List<Competition>>((ref) {
  return ref.watch(competitionsRepositoryProvider).watchAll();
});

final competitionDetailProvider = FutureProvider.autoDispose.family<Competition, int>((ref, id) {
  return ref.watch(competitionsRepositoryProvider).fetchDetail(id);
});

final competitionRankingsProvider = FutureProvider.autoDispose.family<List<CompetitionRanking>, int>((ref, id) {
  return ref.watch(competitionsRepositoryProvider).rankings(id);
});

/// Keyed by (competitionId, teamId) — the current squad selection (a list of
/// `id_utilisateur`) for that team in that competition.
final competitionSelectionProvider =
    FutureProvider.autoDispose.family<List<int>, ({int competitionId, int teamId})>((ref, args) {
  return ref.watch(competitionsRepositoryProvider).selection(args.competitionId, args.teamId);
});
