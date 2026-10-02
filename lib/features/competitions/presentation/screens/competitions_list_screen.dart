import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../matches/presentation/screens/matches_list_screen.dart' show categoriesEquipe, genresEquipe;
import '../../../matches/presentation/widgets/match_widgets.dart';
import '../../data/competition_extras_repository.dart';
import '../../data/models/competition.dart';

class _CompQuery {
  final int? statut;
  final String? categorie;
  final String? genre;
  final String nom;
  final bool mine;
  const _CompQuery({this.statut, this.categorie, this.genre, this.nom = '', this.mine = false});

  @override
  bool operator ==(Object other) =>
      other is _CompQuery && other.statut == statut && other.categorie == categorie && other.genre == genre && other.nom == nom && other.mine == mine;

  @override
  int get hashCode => Object.hash(statut, categorie, genre, nom, mine);
}

final _competitionsQueryProvider = FutureProvider.autoDispose.family<List<Competition>, _CompQuery>((ref, q) {
  return ref.watch(competitionExtrasRepositoryProvider).list(
        statut: q.statut,
        categorie: q.categorie,
        genre: q.genre,
        nom: q.nom,
        mine: q.mine,
      );
});

Color competitionStatusColor(int statut) {
  switch (statut) {
    case CompetitionStatus.inProgress:
      return AppColors.matchLive;
    case CompetitionStatus.cancelled:
      return AppColors.textTertiary;
    case CompetitionStatus.finished:
      return AppColors.success;
    default:
      return AppColors.info;
  }
}

/// Liste des compétitions (compte/competitions.php + mes-competitions.php).
class CompetitionsListScreen extends ConsumerStatefulWidget {
  const CompetitionsListScreen({super.key});

  @override
  ConsumerState<CompetitionsListScreen> createState() => _CompetitionsListScreenState();
}

class _CompetitionsListScreenState extends ConsumerState<CompetitionsListScreen> {
  int? _statut;
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

  _CompQuery get _query => _CompQuery(statut: _statut, categorie: _categorie, genre: _genre, nom: _nom, mine: _mine);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final canCreate = user != null && (user.statut >= 3 || user.isAdmin);
    final list = ref.watch(_competitionsQueryProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: Text(_mine ? 'Mes compétitions' : 'Compétitions'),
        actions: [
          IconButton(tooltip: 'Classements', icon: const Icon(Icons.leaderboard_outlined), onPressed: () => context.push('/rankings')),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/competitions/create');
                ref.invalidate(_competitionsQueryProvider(_query));
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer une compétition'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_competitionsQueryProvider(_query)),
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
                        hintText: 'Rechercher ici',
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
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _Drop(
                          hint: 'Toutes les catégories',
                          value: _categorie,
                          items: categoriesEquipe,
                          onChanged: (v) => setState(() => _categorie = v),
                        ),
                        _Drop(hint: 'Tous les genres', value: _genre, items: genresEquipe, onChanged: (v) => setState(() => _genre = v)),
                        if (user != null)
                          FilterChip(
                            selected: _mine,
                            label: const Text('Mes compétitions'),
                            avatar: const Icon(Icons.person_outline, size: 16),
                            onSelected: (v) => setState(() => _mine = v),
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
                options: [
                  (value: null, label: 'Toutes'),
                  for (final s in CompetitionStatus.all) (value: s, label: CompetitionStatus.label(s)),
                ],
              ),
            ),
            list.when(
              loading: () => const SliverFillRemaining(hasScrollBody: false, child: SizedBox(height: 400, child: SkeletonList(count: 3, itemHeight: 250))),
              error: (e, _) => SliverFillRemaining(hasScrollBody: false, child: ErrorState(error: e, onRetry: () => ref.invalidate(_competitionsQueryProvider(_query)))),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'Aucune compétition',
                      message: 'Aucune compétition ne correspond à ces filtres.',
                      action: canCreate ? FilledButton(onPressed: () => context.push('/competitions/create'), child: const Text('Créer une compétition')) : null,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  sliver: SliverToBoxAdapter(
                    child: ResponsiveColumns(
                      children: [for (final c in items) CompetitionCard(competition: c, onTap: () => context.push('/competitions/${c.id}'))],
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

class _Drop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Drop({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(hint),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(hint)),
            for (final i in items) DropdownMenuItem<String?>(value: i, child: Text(i)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Carte compétition : couverture, statut, description, déroulement, progression.
class CompetitionCard extends StatelessWidget {
  final Competition competition;
  final VoidCallback? onTap;
  const CompetitionCard({super.key, required this.competition, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final text = Theme.of(context).textTheme;
    final progress = c.progress.clamp(0.0, 1.0);
    return SurfaceCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCover(
            imageUrl: c.photo,
            height: 150,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            overlay: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.nom, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleLarge?.copyWith(color: Colors.white)),
                      if (c.saison != null) Text('Saison ${c.saison}', style: text.bodySmall?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                StatusBadge(
                  label: CompetitionStatus.label(c.statut),
                  color: c.statut == CompetitionStatus.inProgress ? AppColors.matchLive : Colors.white,
                  solid: c.statut == CompetitionStatus.inProgress,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (c.categorie != null) StatusBadge(label: c.categorie!, color: AppColors.secondaryLight, icon: Icons.category_outlined),
                    if (c.genre != null) StatusBadge(label: c.genre!, color: AppColors.info, icon: Icons.wc),
                  ],
                ),
                if (c.description != null && c.description!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(c.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                ],
                const SizedBox(height: 12),
                _Meta(icon: Icons.calendar_today_outlined, label: 'Début : ${formatDateFr(c.dateDebut, withDay: false)}'),
                _Meta(icon: Icons.schedule, label: 'Heure : ${formatTimeFr(c.heureDebut).isEmpty ? '—' : formatTimeFr(c.heureDebut)}'),
                _Meta(icon: Icons.stadium_outlined, label: 'Lieu : ${c.lieu ?? '—'}'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Progression', style: text.labelMedium),
                    const Spacer(),
                    Text('${(progress * 100).round()}%', style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: AppColors.surfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (c.owner != null) ...[
                      AppAvatar(name: c.owner!.fullName, imageUrl: c.owner!.avatar, size: 24),
                      const SizedBox(width: 6),
                      Expanded(child: Text(c.owner!.fullName, style: text.bodySmall, overflow: TextOverflow.ellipsis)),
                    ] else
                      const Spacer(),
                    TextButton(onPressed: onTap, child: const Text('Voir les détails')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
