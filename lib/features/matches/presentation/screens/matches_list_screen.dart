import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../competitions/application/competitions_providers.dart';
import '../../../teams/application/teams_providers.dart';
import '../../data/match_extras_repository.dart';
import '../../data/models/match_game.dart';
import '../widgets/match_widgets.dart';

const categoriesEquipe = ['Sous minimes', 'Minime', 'Cadet', 'Junior', 'Senior', 'Élite', 'Major'];
const genresEquipe = ['Masculin', 'Féminin'];

class _MatchQuery {
  final int? statut;
  final int? competitionId;
  final String? categorie;
  final String? genre;
  final String nom;
  final bool mine;

  const _MatchQuery({this.statut, this.competitionId, this.categorie, this.genre, this.nom = '', this.mine = false});

  @override
  bool operator ==(Object other) =>
      other is _MatchQuery &&
      other.statut == statut &&
      other.competitionId == competitionId &&
      other.categorie == categorie &&
      other.genre == genre &&
      other.nom == nom &&
      other.mine == mine;

  @override
  int get hashCode => Object.hash(statut, competitionId, categorie, genre, nom, mine);
}

final _matchesQueryProvider = FutureProvider.autoDispose.family<List<MatchGame>, _MatchQuery>((ref, q) {
  return ref.watch(matchExtrasRepositoryProvider).list(
        statut: q.statut,
        competitionId: q.competitionId,
        categorie: q.categorie,
        genre: q.genre,
        nom: q.nom,
        mine: q.mine,
      );
});

/// Liste des matchs (compte/matchs.php + mes-matchs.php) : filtres par
/// statut, compétition, catégorie, genre, recherche par équipe, bascule
/// "Mes matchs", accès aux propositions et au match amical.
class MatchesListScreen extends ConsumerStatefulWidget {
  const MatchesListScreen({super.key});

  @override
  ConsumerState<MatchesListScreen> createState() => _MatchesListScreenState();
}

class _MatchesListScreenState extends ConsumerState<MatchesListScreen> {
  int? _statut;
  int? _competitionId;
  String? _categorie;
  String? _genre;
  bool _mine = false;
  String _nom = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  _MatchQuery get _query =>
      _MatchQuery(statut: _statut, competitionId: _competitionId, categorie: _categorie, genre: _genre, nom: _nom, mine: _mine);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final matches = ref.watch(_matchesQueryProvider(_query));
    final competitions = ref.watch(competitionsListProvider).valueOrNull ?? const [];
    final myTeams = user == null
        ? const []
        : (ref.watch(teamsListProvider).valueOrNull ?? const []).where((t) => t.isManagedBy(user.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchs'),
        actions: [
          IconButton(
            tooltip: 'Classements',
            icon: const Icon(Icons.leaderboard_outlined),
            onPressed: () => context.push('/rankings'),
          ),
          IconButton(
            tooltip: 'Propositions de matchs',
            icon: const Icon(Icons.mark_email_unread_outlined),
            onPressed: () => context.push('/propositions'),
          ),
        ],
      ),
      floatingActionButton: user == null || (user.statut < 3 && !user.isAdmin && myTeams.isEmpty)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/matches/create'),
              icon: const Icon(Icons.add),
              label: const Text('Programmer'),
            ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_matchesQueryProvider(_query)),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) => setState(() => _nom = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une équipe',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _nom.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _nom = '');
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _Dropdown<int>(
                          hint: 'Toutes les compétitions',
                          value: _competitionId,
                          items: {for (final c in competitions) c.id: c.nom},
                          onChanged: (v) => setState(() => _competitionId = v),
                        ),
                        _Dropdown<String>(
                          hint: 'Toutes les catégories',
                          value: _categorie,
                          items: {for (final c in categoriesEquipe) c: c},
                          onChanged: (v) => setState(() => _categorie = v),
                        ),
                        _Dropdown<String>(
                          hint: 'Tous les genres',
                          value: _genre,
                          items: {for (final g in genresEquipe) g: g},
                          onChanged: (v) => setState(() => _genre = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FilterChips<int>(
                selected: _statut,
                onChanged: (v) => setState(() => _statut = v),
                options: const [
                  (value: null, label: 'Tous'),
                  (value: MatchStatus.inProgress, label: 'En cours'),
                  (value: MatchStatus.scheduled, label: 'Futurs'),
                  (value: MatchStatus.finished, label: 'Terminés'),
                  (value: 2, label: 'Annulés'),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    if (user != null)
                      FilterChip(
                        selected: _mine,
                        label: const Text('Mes matchs'),
                        avatar: const Icon(Icons.person_outline, size: 16),
                        onSelected: (v) => setState(() => _mine = v),
                      ),
                    const Spacer(),
                    if (myTeams.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => context.push('/matches/friendly'),
                        icon: const Icon(Icons.handshake_outlined),
                        label: const Text('Proposer un match amical'),
                      ),
                  ],
                ),
              ),
            ),
            matches.when(
              loading: () => const SliverFillRemaining(hasScrollBody: false, child: SizedBox(height: 400, child: SkeletonList(count: 4, itemHeight: 170))),
              error: (e, _) => SliverFillRemaining(hasScrollBody: false, child: ErrorState(error: e, onRetry: () => ref.invalidate(_matchesQueryProvider(_query)))),
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.sports_soccer,
                      title: 'Aucun match',
                      message: 'Aucun match ne correspond à ces filtres.',
                    ),
                  );
                }
                final sorted = [...list]..sort((a, b) {
                    int rank(MatchGame m) => m.isInProgress ? 0 : (m.isScheduled ? 1 : 2);
                    final r = rank(a).compareTo(rank(b));
                    if (r != 0) return r;
                    return (b.dateDebut ?? '').compareTo(a.dateDebut ?? '');
                  });
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  sliver: SliverToBoxAdapter(
                    child: ResponsiveColumns(
                      children: [
                        for (final m in sorted) MatchScoreboardCard(match: m, onTap: () => context.push('/matches/${m.id}')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: items.containsKey(value) ? value : null,
          isExpanded: true,
          hint: Text(hint, style: Theme.of(context).textTheme.bodyMedium),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(hint)),
            for (final e in items.entries) DropdownMenuItem<T?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
