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
      final summaryCard = _Card(
        title: "Résumé de l'état",
        subtitle: 'Répartition des résultats',
        child: Column(children: [
          ResultsDonut(wins: s.wins, draws: s.draws, defeats: s.defeats),
          const Divider(height: 28),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Mini(label: 'Points', value: '${s.points}'),
            _Mini(label: 'Buts encaissés', value: '${s.goalsConceded}'),
            _Mini(label: 'Corners', value: '${s.corners}'),
            _Mini(label: 'Cartons J.', value: '${s.yellowCards}'),
          ]),
        ]),
      );
      final matchesCard = _Card(
        title: 'Statistiques des matchs',
        subtitle: 'Buts marqués par mois (12 derniers mois)',
        child: GoalsLineChart(months: d.months),
      );
      final categoriesCard = _CategoriesCard(matrix: d.categoryMatrix);
      final respCard = _ResponsablesCard(team: team);
      final eventsCard = _EventsCard(matches: d.recentMatches);
      final activitiesCard = _ActivitiesCard(d: d);
      final tasksCard = _TasksCard(tasks: d.tasks);
      final perfCard = _Card(
        title: 'Performance',
        subtitle: 'Par mois',
        child: GoalsLineChart(months: d.months, color: AppColors.info),
      );
      final bestCard = _BestPerformersCard(list: d.topPerformers);

      Widget stack(List<Widget> l) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final w in l) Padding(padding: const EdgeInsets.only(bottom: 16), child: w)],
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(spacing: 10, runSpacing: 10, children: [for (final t in tiles) SizedBox(width: tileW, height: 132, child: t)]),
          const SizedBox(height: 16),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: stack([resultsCard, matchesCard, categoriesCard, respCard, Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: eventsCard), const SizedBox(width: 16), Expanded(child: activitiesCard)])])),
              const SizedBox(width: 16),
              Expanded(child: stack([summaryCard, tasksCard, perfCard, bestCard])),
            ])
          else
            stack([resultsCard, summaryCard, matchesCard, categoriesCard, respCard, eventsCard, activitiesCard, tasksCard, perfCard, bestCard]),
        ],
      );
    });
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

class _Mini extends StatelessWidget {
  final String label;
  final String value;
  const _Mini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(children: [
      Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      Text(label, style: t.bodySmall, textAlign: TextAlign.center),
    ]);
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

/// "Liste des responsables": legacy table (Utilisateur / Genre / Contacts /
/// Depuis) — here the team members from the detail payload.
class _ResponsablesCard extends StatelessWidget {
  final Team team;
  const _ResponsablesCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final members = team.members;
    return _Card(
      title: 'Liste des responsables',
      subtitle: "Membres de l'équipe",
      child: members.isEmpty
          ? Text('Aucun membre.', style: t.bodyMedium)
          : Column(children: [
              for (final m in members)
                InkWell(
                  onTap: () => context.push('/users/${m.userId}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      AppAvatar(name: m.fullName, imageUrl: m.avatar, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.fullName, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(m.poste ?? '—', style: t.bodySmall),
                        ]),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.genre ?? '—', style: t.labelLarge),
                          Text(m.user.dateDeNaissance == null ? '' : formatDateFr(m.user.dateDeNaissance), style: t.bodySmall),
                        ]),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 560)
                        Expanded(flex: 3, child: Text(m.user.telephone ?? '', style: t.bodyMedium?.copyWith(color: AppColors.success, fontWeight: FontWeight.w600))),
                      StatusBadge(label: timeAgo(m.position?.createdAt).isEmpty ? '—' : timeAgo(m.position?.createdAt)),
                    ]),
                  ),
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
        for (final m in matches)
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
        for (final a in d.activities)
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
              for (final k in tasks)
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
              for (final p in list)
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
