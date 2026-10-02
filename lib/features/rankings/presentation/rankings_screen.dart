import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../competitions/data/competition_extras_repository.dart';
import '../../matches/presentation/widgets/match_widgets.dart';

/// Classements de toutes les compétitions (compte/classements.php) : un
/// tableau par compétition — rang, équipe, J/V/N/D, buts, points, progression.
class RankingsScreen extends ConsumerWidget {
  const RankingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(globalStandingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classements'),
        actions: [
          IconButton(onPressed: () => ref.invalidate(globalStandingsProvider), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: standings.when(
        loading: () => const SkeletonList(count: 3, itemHeight: 220),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(globalStandingsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'Aucun classement',
              message: "Les classements apparaissent dès que des équipes sont inscrites à une compétition.",
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(globalStandingsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                for (final c in list) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
                    child: InkWell(
                      onTap: () => context.push('/competitions/${c.competitionId}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          AppAvatar(name: c.nom, imageUrl: c.photo, size: 44, rounded: true),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.nom, style: Theme.of(context).textTheme.titleLarge),
                                if (c.saison != null) Text('Saison ${c.saison}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ),
                  StandingsTable(rows: c.rows, onTeamTap: (r) => context.push('/competitions/${c.competitionId}/teams/${r.teamId}/selection')),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
