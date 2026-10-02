import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/matches_repository.dart';
import '../data/models/match_game.dart';

final matchesListProvider = StreamProvider.autoDispose<List<MatchGame>>((ref) {
  return ref.watch(matchesRepositoryProvider).watchAll();
});

final matchDetailProvider = FutureProvider.autoDispose.family<MatchGame, int>((ref, id) {
  return ref.watch(matchesRepositoryProvider).fetchDetail(id);
});

final liveMatchesProvider = FutureProvider.autoDispose<List<MatchGame>>((ref) {
  return ref.watch(matchesRepositoryProvider).live();
});

/// Filters applied on the matches list screen. `categorie`/`genre` aren't
/// exposed as API query filters (`MatchController::index` only accepts
/// `status`/`competition_id`/`team_id`), so they're applied client-side over
/// the server-filtered results.
class MatchFilter {
  final int? statut;
  final int? competitionId;
  final String? categorie;
  final String? genre;

  const MatchFilter({this.statut, this.competitionId, this.categorie, this.genre});

  MatchFilter copyWith({
    int? statut,
    bool clearStatut = false,
    int? competitionId,
    bool clearCompetitionId = false,
    String? categorie,
    bool clearCategorie = false,
    String? genre,
    bool clearGenre = false,
  }) {
    return MatchFilter(
      statut: clearStatut ? null : (statut ?? this.statut),
      competitionId: clearCompetitionId ? null : (competitionId ?? this.competitionId),
      categorie: clearCategorie ? null : (categorie ?? this.categorie),
      genre: clearGenre ? null : (genre ?? this.genre),
    );
  }

  bool get isEmpty => statut == null && competitionId == null && categorie == null && genre == null;
}

final matchFilterProvider = StateProvider.autoDispose<MatchFilter>((ref) => const MatchFilter());

final filteredMatchesProvider = FutureProvider.autoDispose<List<MatchGame>>((ref) async {
  final filter = ref.watch(matchFilterProvider);
  final repo = ref.watch(matchesRepositoryProvider);
  final results = filter.statut == null && filter.competitionId == null
      ? await repo.all()
      : await repo.search(statut: filter.statut, competitionId: filter.competitionId);
  return results.where((m) {
    if (filter.categorie != null && m.categorie != filter.categorie) return false;
    if (filter.genre != null && m.genre != filter.genre) return false;
    return true;
  }).toList();
});
