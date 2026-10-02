import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/player.dart';
import '../data/players_repository.dart';

final usersPageProvider = FutureProvider.autoDispose.family<UserPage, UserQuery>((ref, q) {
  return ref.watch(playersRepositoryProvider).users(q);
});

final userDetailProvider = FutureProvider.autoDispose.family<PlayerUser, int>((ref, id) {
  return ref.watch(playersRepositoryProvider).user(id);
});

final userPositionsProvider = FutureProvider.autoDispose.family<List<PlayerPosition>, int>((ref, id) {
  return ref.watch(playersRepositoryProvider).positions(id);
});

final userStatsProvider = FutureProvider.autoDispose.family<UserStats, int>((ref, id) {
  return ref.watch(playersRepositoryProvider).statistics(id);
});

final userPerformancesProvider = FutureProvider.autoDispose.family<List<Skill>, int>((ref, id) {
  return ref.watch(playersRepositoryProvider).performances(id);
});
