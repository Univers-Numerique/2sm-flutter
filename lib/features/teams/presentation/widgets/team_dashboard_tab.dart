import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../matches/presentation/screens/matches_list_screen.dart';
import '../../../players/data/football_constants.dart';
import '../../../players/presentation/widgets/people_widgets.dart';
import '../../application/teams_providers.dart';
import '../../data/models/team.dart';
import '../../data/models/team_dashboard.dart';
import 'team_charts.dart';

/// Team dashboard — port of `compte/tableau-de-bord.php` and
/// `manage/equipes/tableau-de-bord.php`, backed by `GET /teams/{id}/dashboard`
/// (with `GET /teams/{id}/statistics` as fallback for non-members).
class TeamDashboardTab extends ConsumerWidget {
  final Team team;
  const TeamDashboardTab({super.key, required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teamDashboardProvider(team.id));
    return PageBody(
      onRefresh: () async {
        ref.invalidate(teamDashboardProvider(team.id));
        ref.invalidate(teamDetailProvider(team.id));
      },
      children: [
        async.when(
          loading: () => Column(children: const [
            SkeletonBox(height: 100, radius: 20),
            SizedBox(height: 12),
            SkeletonBox(height: 260, radius: 20),
            SizedBox(height: 12),
            SkeletonBox(height: 200, radius: 20),
          ]),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(teamDashboardProvider(team.id))),
          data: (d) => _Body(team: team, d: d),
        ),
      ],
    );
  }
}

/// Nombre d'éléments affichés par bloc : le tableau de bord reste lisible,
/// « Voir tout » mène à la liste complète.
const _maxItems = 5;

/// Disposition du tableau de bord d'équipe du site (_tdb-*.blade.php) :
/// tuiles, puis (résultats | résumé), (statistiques | répartition),
/// (responsables | meilleurs performeurs), et les listes récentes.
class _Body extends StatelessWidget {
  final Team team;
  final TeamDashboard d;
  const _Body({required this.team, required this.d});

  @override
  Widget build(BuildContext context) {
    final s = d.stats;
    final tiles = <Widget>[
      StatTile(label: 'Victoires', value: '${s.wins}', icon: Icons.emoji_events_outlined, color: AppColors.success),
      StatTile(label: 'Défaites', value: '${s.defeats}', icon: Icons.trending_down, color: AppColors.error),
      StatTile(label: 'Buts marqués', value: '${s.goalsScored}', icon: Icons.sports_soccer, color: AppColors.primary),
      StatTile(label: 'Matchs joués', value: '${s.matchesPlayed}', icon: Icons.stadium_outlined, color: AppColors.info),
      StatTile(label: 'Tirs cadrés', value: '${s.shotsOnTarget}', icon: Icons.gps_fixed, color: AppColors.warning),
      StatTile(label: 'Moy. buts / match', value: s.averageGoals.toStringAsFixed(s.averageGoals % 1 == 0 ? 0 : 2), icon: Icons.show_chart, color: AppColors.secondaryLight),
    ];

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final cols = c.maxWidth >= 900 ? 6 : (c.maxWidth >= 560 ? 3 : 2);
      final tileW = (c.maxWidth - (cols - 1) * 10) / cols;

      final resultsCard = _Card(
        title: 'Résultat des matchs passés',
        subtitle: 'Statistiques des victoires et des défaites',
        child: ResultsBarChart(months: d.months),
      );
      final summaryCard = _SummaryCard(stats: s);
      final matchesCard = _Card(
        title: 'Statistiques des matchs',
        subtitle: 'Buts marqués par mois (12 derniers mois)',
        child: GoalsLineChart(months: d.months),
      );
      final donutCard = _Card(
        title: 'Répartition des résultats',
        child: ResultsDonut(wins: s.wins, draws: s.draws, defeats: s.defeats),
      );
      final respCard = _ResponsablesCard(team: team);
      final bestCard = _BestPerformersCard(list: d.topPerformers);
      final eventsCard = _EventsCard(matches: d.recentMatches);
      final activitiesCard = _ActivitiesCard(d: d);
      final tasksCard = _TasksCard(tasks: d.tasks);
      final categoriesCard = _CategoriesCard(matrix: d.categoryMatrix);

      Widget pair(Widget left, Widget right) => wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 16), right]);

      Widget trio(List<Widget> l) => wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < l.length; i++) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: l[i])],
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < l.length; i++) ...[if (i > 0) const SizedBox(height: 16), l[i]],
            ]);

      const gap = SizedBox(height: 16);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 10, runSpacing: 10, children: [for (final t in tiles) SizedBox(width: tileW, height: 118, child: t)]),
          gap,
          pair(resultsCard, summaryCard),
          gap,
          pair(matchesCard, donutCard),
          gap,
          pair(respCard, bestCard),
          gap,
          trio([eventsCard, activitiesCard, tasksCard]),
          gap,
          categoriesCard,
        ],
      );
    });
  }
}

/// « Résumé de l'état » : carte verte du site, matchs joués en grand.
class _SummaryCard extends StatelessWidget {
  final DashboardStats stats;
  const _SummaryCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget mini(String label, int v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$v', style: AppTextStyles.stat.copyWith(fontSize: 22, color: Colors.white)),
          Text(label, style: t.bodySmall?.copyWith(color: Colors.white70)),
        ]);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primaryDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha(70), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Résumé de l'état", style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Text('Matchs joués', style: t.bodyMedium?.copyWith(color: Colors.white70)),
        Text('${stats.matchesPlayed}', style: AppTextStyles.score.copyWith(fontSize: 56, color: Colors.white)),
        const SizedBox(height: 16),
        Wrap(spacing: 22, runSpacing: 12, children: [
          mini('Points', stats.points),
          mini('Buts encaissés', stats.goalsConceded),
          mini('Corners', stats.corners),
          mini('Cartons jaunes', stats.yellowCards),
        ]),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleMedium),
                if (subtitle != null) Text(subtitle!, style: t.bodySmall),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  final Map<String, Map<String, int>> matrix;
  const _CategoriesCard({required this.matrix});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (matrix.isEmpty) {
      return _Card(title: 'Statistiques des catégories', child: Text("Aucun membre dans l'équipe.", style: t.bodyMedium));
    }
    final cats = [...kCategories, if (matrix.values.any((r) => r.containsKey('Non renseigné'))) 'Non renseigné'];
    int rowTotal(String g) => matrix[g]!.values.fold(0, (a, b) => a + b);
    int colTotal(String c) => matrix.values.fold(0, (a, r) => a + (r[c] ?? 0));
    final head = t.labelMedium?.copyWith(fontWeight: FontWeight.w800);
    return _Card(
      title: 'Statistiques des catégories et genres',
      subtitle: 'Répartition des membres',
      child: Column(children: [
        CategoryGenderChart(matrix: matrix, categories: cats),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            columnSpacing: 18,
            columns: [
              DataColumn(label: Text('Genre', style: head)),
              for (final c in cats) DataColumn(label: Text(c, style: head), numeric: true),
              DataColumn(label: Text('Total genre', style: head), numeric: true),
            ],
            rows: [
              for (final g in matrix.keys)
                DataRow(cells: [
                  DataCell(Text(g, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                  for (final c in cats) DataCell(Text('${matrix[g]![c] ?? 0}')),
                  DataCell(Text('${rowTotal(g)}', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
                ]),
              DataRow(cells: [
                DataCell(Text('Total catégorie', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
                for (final c in cats) DataCell(Text('${colTotal(c)}', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
                DataCell(Text('${matrix.keys.fold(0, (a, g) => a + rowTotal(g))}', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

/// « Liste des responsables » du site : uniquement les postes honorifiques et le
/// personnel administratif actifs (TeamDashboardService::responsables), 5 au plus.
class _ResponsablesCard extends StatelessWidget {
  final Team team;
  const _ResponsablesCard({required this.team});

  static const _staffTypes = {'Postes Honorifiques', 'Personnel Administratif'};

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final staff = team.members.where((m) => _staffTypes.contains(m.type) && m.statut == 1).toList();
    final shown = staff.take(_maxItems).toList();
    return _Card(
      title: 'Liste des responsables',
      subtitle: staff.isEmpty ? null : '${staff.length} responsable${staff.length > 1 ? 's' : ''}',
      child: staff.isEmpty
          ? Text('Aucun responsable.', style: t.bodyMedium)
          : Column(children: [
              for (final m in shown)
                InkWell(
                  onTap: () => context.push('/users/${m.userId}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border.withAlpha(m == shown.last ? 0 : 255), width: 0.8))),
                    child: Row(children: [
                      AppAvatar(name: m.fullName, imageUrl: m.avatar, size: 40, rounded: true),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.fullName, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(m.poste ?? '—', style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 560) ...[
                        Expanded(
                          flex: 2,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.genre ?? '—', style: t.labelLarge),
                            if (m.user.dateDeNaissance != null) Text(formatDateFr(m.user.dateDeNaissance), style: t.bodySmall),
                          ]),
                        ),
                        if ((m.user.telephone ?? '').isNotEmpty)
                          Expanded(flex: 2, child: Text(m.user.telephone!, style: t.bodyMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))),
                      ],
                      if (timeAgo(m.position?.createdAt).isNotEmpty) StatusBadge(label: timeAgo(m.position?.createdAt), color: AppColors.success),
                    ]),
                  ),
                ),
              if (staff.length > _maxItems)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('+ ${staff.length - _maxItems} autre${staff.length - _maxItems > 1 ? 's' : ''} dans « Gestion des membres »', style: t.bodySmall),
                ),
            ]),
    );
  }
}

class _EventsCard extends StatelessWidget {
  final List<RecentMatch> matches;
  const _EventsCard({required this.matches});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Card(
      title: 'Événements récents',
      child: Column(children: [
        if (matches.isEmpty) Align(alignment: Alignment.centerLeft, child: Text('Aucun match.', style: t.bodyMedium)),
        for (final m in matches.take(_maxItems))
          InkWell(
            onTap: () => context.push('/matches/${m.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(m.home?.nom ?? '—', style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      m.homeGoals != null || m.awayGoals != null ? '${m.homeGoals ?? 0} - ${m.awayGoals ?? 0}' : 'VS',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Text(m.away?.nom ?? '—', textAlign: TextAlign.end, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text('${formatDateFr(m.date)}${m.heure != null ? ' à ${m.heure!.substring(0, 5)}' : ''}', style: t.bodySmall),
                ]),
                const Divider(height: 16),
              ]),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MatchesListScreen())), icon: const Icon(Icons.arrow_forward, size: 16), label: const Text('Voir tout')),
        ),
      ]),
    );
  }
}

class _ActivitiesCard extends StatelessWidget {
  final TeamDashboard d;
  const _ActivitiesCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Card(
      title: 'Activités',
      subtitle: '${d.activitiesFinished} terminée${d.activitiesFinished > 1 ? 's' : ''}, ${d.activitiesOngoing} en cours',
      child: Column(children: [
        if (d.activities.isEmpty) Align(alignment: Alignment.centerLeft, child: Text('Aucune activité.', style: t.bodyMedium)),
        for (final a in d.activities.take(_maxItems))
          InkWell(
            onTap: () => context.push('/activities/${a.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Container(width: 4, height: 44, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.titre, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (a.lieu != null) Text('Lieu : ${a.lieu}', style: t.bodySmall?.copyWith(color: AppColors.success)),
                    Text('Le ${formatDateFr(a.date)}${a.heure != null && a.heure!.length >= 5 ? ' à ${a.heure!.substring(0, 5)}' : ''}', style: t.bodySmall),
                  ]),
                ),
              ]),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: () => context.push('/activities'), icon: const Icon(Icons.arrow_forward, size: 16), label: const Text('Afficher tout')),
        ),
      ]),
    );
  }
}

class _TasksCard extends StatelessWidget {
  final List<DashboardTask> tasks;
  const _TasksCard({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Card(
      title: 'Liste des tâches',
      child: tasks.isEmpty
          ? Text('Aucune tâche.', style: t.bodyMedium)
          : Column(children: [
              for (final k in tasks.take(_maxItems))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(k.statut == 2 ? Icons.check_circle : Icons.radio_button_unchecked, color: k.statut == 2 ? AppColors.success : AppColors.textTertiary),
                  title: Text(k.tache, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text([timeAgo(k.createdAt), if (k.author != null && k.author!.isNotEmpty) 'par ${k.author}'].where((e) => e.isNotEmpty).join(' · ')),
                ),
            ]),
    );
  }
}

class _BestPerformersCard extends StatelessWidget {
  final List<TopPerformer> list;
  const _BestPerformersCard({required this.list});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return _Card(
      title: 'Meilleurs performeurs',
      subtitle: 'Moyenne des compétences évaluées',
      child: list.isEmpty
          ? Text('Aucune évaluation.', style: t.bodyMedium)
          : Column(children: [
              for (final p in list.take(_maxItems))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => context.push('/users/${p.id}'),
                  leading: AppAvatar(name: p.fullName, imageUrl: p.avatar, size: 44),
                  title: Text(p.fullName, style: t.titleSmall),
                  subtitle: Text(p.age == null ? '' : '${p.age} ans'),
                  trailing: Text('${p.average.round()}/100', style: t.titleSmall?.copyWith(color: AppColors.primary)),
                ),
            ]),
    );
  }
}
