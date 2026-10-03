import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/constants/brand_tokens.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../application/admin_providers.dart';
import '../../data/models/admin_models.dart';
import '../widgets/admin_widgets.dart';

/// Legacy `admin/tableau-de-bord.php`: KPI strip, results chart, status
/// summary, match statistics, "Liste des responsables", recent events,
/// activities, task list, subscriptions doughnut, performance and top
/// performers. The legacy KPI labels were mixed up (competitions showed the
/// victory count, etc.) — here every tile shows what its label says.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminDashboardProvider);

    return AdminScaffold(
      title: 'Administration',
      section: AdminSection.dashboard,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminDashboardProvider.future),
        child: async.when(
          loading: () => const _DashboardSkeleton(),
          error: (e, _) => ListView(
            children: [SizedBox(height: 380, child: ErrorState(error: e, onRetry: () => ref.invalidate(adminDashboardProvider)))],
          ),
          data: (d) => _DashboardBody(data: d),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonBox(height: 40, width: 260),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (var i = 0; i < 6; i++) const SkeletonBox(width: 160, height: 130, radius: 20)],
        ),
        const SizedBox(height: 16),
        const SkeletonBox(height: 300, radius: 24),
        const SizedBox(height: 16),
        const SkeletonBox(height: 260, radius: 24),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final AdminDashboard data;
  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final wide = isAdminWide(context);
    final pad = wide ? 24.0 : 16.0;
    final text = Theme.of(context).textTheme;

    final main = <Widget>[
      _ResultsCard(months: data.resultsByMonth),
      _GoalsCard(months: data.resultsByMonth),
      _ManagersCard(managers: data.managers, wide: wide),
      wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _EventsCard(events: data.recentEvents)),
                const SizedBox(width: 16),
                Expanded(child: _ActivitiesCard(activities: data.activities)),
              ],
            )
          : Column(children: [
              _EventsCard(events: data.recentEvents),
              const SizedBox(height: 16),
              _ActivitiesCard(activities: data.activities),
            ]),
    ];

    final side = <Widget>[
      _SummaryCard(data: data),
      _TasksCard(tasks: data.tasks),
      _PlansCard(stats: data.subscriptionsByPlan),
      _PerformanceCard(months: data.performanceByMonth),
      _TopPerformersCard(items: data.topPerformers),
    ];

    Widget stack(List<Widget> children) => Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              children[i],
            ],
          ],
        );

    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
      children: [
        Text('Tableau de bord', style: text.headlineSmall),
        Text("Vue d'ensemble de la plateforme.", style: text.bodyMedium),
        const SizedBox(height: 16),
        _KpiStrip(counts: data.counts, wide: wide),
        const SizedBox(height: 16),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: stack(main)),
              const SizedBox(width: 16),
              Expanded(child: stack(side)),
            ],
          )
        else
          stack([...side.take(1), ...main, ...side.skip(1)]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// KPI strip
// ---------------------------------------------------------------------------

class _KpiStrip extends StatelessWidget {
  final DashboardCounts counts;
  final bool wide;
  const _KpiStrip({required this.counts, required this.wide});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _tap(context, '/admin/competitions',
          StatTile(label: 'Compétitions', value: '${counts.competitions}', icon: Icons.emoji_events_outlined, color: AppColors.warning)),
      _tap(context, '/admin/teams',
          StatTile(label: 'Équipes', value: '${counts.teams}', icon: Icons.groups_outlined, color: AppColors.primary)),
      _tap(context, '/admin/fields',
          StatTile(label: 'Terrains', value: '${counts.fields}', icon: Icons.stadium_outlined, color: AppColors.info)),
      _tap(
          context,
          '/admin/users',
          StatTile(
            label: 'Utilisateurs',
            value: '${counts.users}',
            icon: Icons.people_outline,
            color: AppColors.info,
            caption: '+${counts.newUsersThisMonth} ce mois-ci',
          )),
      _tap(
          context,
          '/calendar',
          StatTile(
            label: 'Matchs',
            value: '${counts.matches}',
            icon: Icons.sports_soccer_outlined,
            color: AppColors.error,
            caption: '${counts.matchesPlayed} joués · ${counts.matchesToday} aujourd\'hui',
          )),
      _tap(context, '/activities',
          StatTile(label: 'Activités', value: '${counts.activities}', icon: Icons.event_note_outlined, color: AppColors.secondary)),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 6 : (MediaQuery.sizeOf(context).width >= 560 ? 3 : 2),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      mainAxisExtent: 150,
      children: tiles,
    );
  }

  Widget _tap(BuildContext context, String route, Widget child) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: () => context.push(route), child: child),
      );
}

// ---------------------------------------------------------------------------
// Card shell
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final bool dark;

  const _Card({required this.title, this.subtitle, this.trailing, required this.child, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? null : AppColors.card,
        gradient: dark ? AppColors.heroGradient : null,
        borderRadius: BorderRadius.circular(24),
        border: dark ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, box) {
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge?.copyWith(color: dark ? Colors.white : null)),
                if (subtitle != null) Text(subtitle!, style: text.bodySmall?.copyWith(color: dark ? Colors.white70 : null)),
              ],
            );
            if (trailing == null) return titleBlock;
            if (box.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [titleBlock, const SizedBox(height: 10), trailing!],
              );
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: titleBlock), trailing!]);
          }),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final List<(String, Color)> items;
  const _Legend(this.items);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final (label, color) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
      ],
    );
  }
}

String _monthLabel(String ym) {
  final d = DateTime.tryParse('$ym-01');
  if (d == null) return ym;
  final s = DateFormat('MMM', 'fr_FR').format(d);
  return s.replaceAll('.', '');
}

const _chartText = TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600);

FlTitlesData _monthTitles(List<String> labels, {double reserved = 28}) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: reserved,
        interval: 1,
        getTitlesWidget: (v, meta) => v % 1 == 0
            ? Padding(padding: const EdgeInsets.only(right: 4), child: Text('${v.toInt()}', style: _chartText, textAlign: TextAlign.right))
            : const SizedBox.shrink(),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (v, meta) {
          final i = v.toInt();
          if (i < 0 || i >= labels.length || v != i.toDouble()) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(top: 6), child: Text(labels[i], style: _chartText));
        },
      ),
    ),
  );
}

FlGridData get _grid => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [4, 4]),
    );

// ---------------------------------------------------------------------------
// Results chart ("resultat des matchs passés")
// ---------------------------------------------------------------------------

class _ResultsCard extends StatelessWidget {
  final List<MonthlyResult> months;
  const _ResultsCard({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxY = months.fold<int>(1, (m, r) => math.max(m, math.max(r.homeWins, math.max(r.draws, r.awayWins))));
    return _Card(
      title: 'Résultats des matchs passés',
      subtitle: 'Victoires à domicile, nuls et victoires à l\'extérieur par mois',
      trailing: const _Legend([
        ('Domicile', AppColors.success),
        ('Nuls', AppColors.warning),
        ('Extérieur', AppColors.info),
      ]),
      child: SizedBox(
        height: 240,
        child: months.every((m) => m.matches == 0)
            ? const Center(child: Text('Aucun match terminé sur la période.'))
            : BarChart(
                BarChartData(
                  maxY: (maxY + 1).toDouble(),
                  alignment: BarChartAlignment.spaceAround,
                  gridData: _grid,
                  borderData: FlBorderData(show: false),
                  titlesData: _monthTitles([for (final m in months) _monthLabel(m.month)]),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) {
                        const names = ['Domicile', 'Nuls', 'Extérieur'];
                        return BarTooltipItem(
                          '${names[ri]} : ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < months.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 4,
                        barRods: [
                          _rod(months[i].homeWins, AppColors.success),
                          _rod(months[i].draws, AppColors.warning),
                          _rod(months[i].awayWins, AppColors.info),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  BarChartRodData _rod(int v, Color c) => BarChartRodData(
        toY: v.toDouble(),
        color: c,
        width: 12,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      );
}

// ---------------------------------------------------------------------------
// Goals per month ("Statistiques des matchs")
// ---------------------------------------------------------------------------

class _GoalsCard extends StatelessWidget {
  final List<MonthlyResult> months;
  const _GoalsCard({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxY = months.fold<int>(1, (m, r) => math.max(m, r.goals));
    return _Card(
      title: 'Statistiques des matchs',
      subtitle: 'Buts marqués par mois',
      trailing: const _Legend([('Buts', AppColors.primary)]),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: (maxY + 2).toDouble(),
            gridData: _grid,
            borderData: FlBorderData(show: false),
            titlesData: _monthTitles([for (final m in months) _monthLabel(m.month)]),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                  '${months[g.x].goals} but(s) · ${months[g.x].matches} match(s)',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < months.length; i++)
                BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: months[i].goals.toDouble(),
                    width: 22,
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Résumé de l'état"
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final AdminDashboard data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final weeks = data.matchesByWeek;
    final text = Theme.of(context).textTheme;
    final maxY = weeks.fold<int>(1, (m, w) => math.max(m, w.matches));
    return _Card(
      dark: true,
      title: "Résumé de l'état",
      subtitle: 'Ce mois-ci',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Matches joués', style: text.labelLarge?.copyWith(color: Colors.white70)),
          Text('${data.matchesPlayedThisMonth}', style: text.displaySmall?.copyWith(color: AppColors.primaryLight)),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: (maxY + 1).toDouble(),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('S${v.toInt() + 1}', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                      ),
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.primaryLight,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: AppColors.primaryLight.withAlpha(50)),
                    spots: [for (var i = 0; i < weeks.length; i++) FlSpot(i.toDouble(), weeks[i].matches.toDouble())],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Managers ("Liste des responsables")
// ---------------------------------------------------------------------------

class _ManagersCard extends StatelessWidget {
  final List<DashboardManager> managers;
  final bool wide;
  const _ManagersCard({required this.managers, required this.wide});

  String _birth(String? raw) {
    final d = raw == null || raw.length < 10 ? null : DateTime.tryParse(raw.substring(0, 10));
    return d == null ? '—' : DateFormat('dd/MM/yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Card(
      title: 'Liste des responsables',
      subtitle: 'Postes honorifiques et personnel administratif',
      child: managers.isEmpty
          ? const Padding(padding: EdgeInsets.all(12), child: Text('Aucun responsable.'))
          : Column(
              children: [
                if (wide)
                  Container(
                    color: AppColors.surfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        for (final (label, flex) in const [('Utilisateur', 4), ('Genre', 2), ('Contacts', 3), ('Depuis', 2)])
                          Expanded(
                            flex: flex,
                            child: Text(label.toUpperCase(),
                                style: text.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                          ),
                      ],
                    ),
                  ),
                for (var i = 0; i < managers.length; i++) ...[
                  if (i > 0 || wide) const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: wide ? _row(context, managers[i]) : _tile(context, managers[i]),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _row(BuildContext context, DashboardManager m) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: NameCell(
            leading: AppAvatar(name: m.fullName, imageUrl: m.avatar, size: 40),
            title: m.fullName,
            subtitle: [m.poste, m.equipe].where((s) => s != null && s.isNotEmpty).join(' · '),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.genre ?? '—', style: text.titleSmall),
              Text(_birth(m.dateDeNaissance), style: text.bodySmall),
            ],
          ),
        ),
        Expanded(flex: 3, child: Text(m.telephone ?? '—', style: text.titleSmall?.copyWith(color: AppColors.success))),
        Expanded(
          flex: 2,
          child: Align(alignment: Alignment.centerLeft, child: StatusBadge(label: timeElapsed(m.depuis), color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, DashboardManager m) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        AppAvatar(name: m.fullName, imageUrl: m.avatar, size: 44),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.fullName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text([m.poste, m.equipe].where((s) => s != null && s.isNotEmpty).join(' · '),
                  style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${m.genre ?? '—'} · ${m.telephone ?? '—'}', style: text.bodySmall?.copyWith(color: AppColors.success)),
            ],
          ),
        ),
        StatusBadge(label: timeElapsed(m.depuis), color: AppColors.primary),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recent events
// ---------------------------------------------------------------------------

class _EventsCard extends StatelessWidget {
  final List<DashboardEvent> events;
  const _EventsCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Card(
      title: 'Événements récents',
      child: Column(
        children: [
          if (events.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Aucun événement.')),
          for (final e in events)
            InkWell(
              onTap: () => context.push('/matches/${e.id}'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(e.home ?? '—', style: text.titleSmall),
                        const StatusBadge(label: 'VS', color: AppColors.primary, solid: true),
                        Text(e.away ?? '—', style: text.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(longDate(e.date), style: text.bodySmall, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/calendar'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              iconAlignment: IconAlignment.end,
              label: const Text('Voir tout'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activities
// ---------------------------------------------------------------------------

class _ActivitiesCard extends StatelessWidget {
  final DashboardActivities activities;
  const _ActivitiesCard({required this.activities});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Card(
      title: 'Activités',
      trailing: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text('${activities.finished} terminée(s), ${activities.inProgress} en cours', style: text.bodySmall),
      ),
      child: Column(
        children: [
          if (activities.items.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Aucune activité.')),
          for (final a in activities.items)
            InkWell(
              onTap: () => context.push('/activities/${a.id}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 58,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.titre, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (a.lieu != null && a.lieu!.isNotEmpty)
                            Text('Lieu : ${a.lieu}', style: text.bodySmall?.copyWith(color: AppColors.success)),
                          Text(
                            'Le ${longDate(a.date)}${a.heure != null && a.heure!.length >= 5 ? ' à ${a.heure!.substring(0, 5)}' : ''}',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/activities'),
              icon: const Icon(Icons.arrow_forward, size: 18),
              iconAlignment: IconAlignment.end,
              label: const Text('Afficher tout'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tasks
// ---------------------------------------------------------------------------

class _TasksCard extends StatelessWidget {
  final List<DashboardTask> tasks;
  const _TasksCard({required this.tasks});

  static const _labels = ['En attente', 'Pigée', 'Effectuée', 'Annulée'];
  static const _colors = [AppColors.textSecondary, AppColors.primary, AppColors.success, AppColors.error];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Card(
      title: 'Liste des tâches',
      child: tasks.isEmpty
          ? const Text('Aucune tâche.')
          : Column(
              children: [
                for (final t in tasks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          t.statut == 2 ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 20,
                          color: _colors[t.statut.clamp(0, 3)],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.tache,
                                style: text.bodyLarge?.copyWith(
                                  decoration: t.statut == 2 ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(timeElapsed(t.createdAt), style: text.bodySmall),
                                  if (t.recipient.isNotEmpty) StatusBadge(label: 'À ${t.recipient}', color: AppColors.warning),
                                  StatusBadge(label: _labels[t.statut.clamp(0, 3)], color: _colors[t.statut.clamp(0, 3)]),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscriptions doughnut ("Répartition par montant")
// ---------------------------------------------------------------------------

class _PlansCard extends StatelessWidget {
  final List<PlanStat> stats;
  const _PlansCard({required this.stats});

  static const _palette = [AppColors.primary, AppColors.info, AppColors.warning, BrandTokens.marine700, AppColors.error];

  @override
  Widget build(BuildContext context) {
    final total = stats.fold<double>(0, (s, p) => s + p.montant);
    final withData = stats.where((p) => p.montant > 0).toList();
    final fmt = NumberFormat.decimalPattern('fr_FR');
    return _Card(
      title: 'Répartition par montant',
      subtitle: 'Abonnements par plan',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: withData.isEmpty
                ? const Center(child: Text("Aucun abonnement pour l'instant."))
                : PieChart(
                    PieChartData(
                      centerSpaceRadius: 46,
                      sectionsSpace: 3,
                      sections: [
                        for (var i = 0; i < withData.length; i++)
                          PieChartSectionData(
                            value: withData[i].montant,
                            color: _palette[i % _palette.length],
                            radius: 26,
                            title: '${(withData[i].montant / total * 100).round()}%',
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < stats.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: _palette[i % _palette.length], borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: Text(stats[i].nom, overflow: TextOverflow.ellipsis)),
                  const Spacer(),
                  Text('${stats[i].count} · ${fmt.format(stats[i].montant.round())} F CFA',
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Performance per month
// ---------------------------------------------------------------------------

class _PerformanceCard extends StatelessWidget {
  final List<PerfMonth> months;
  const _PerformanceCard({required this.months});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Performance',
      subtitle: 'Moyenne par mois (sur 100)',
      child: SizedBox(
        height: 180,
        child: months.isEmpty
            ? const Center(child: Text('Aucune performance enregistrée.'))
            : LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: _grid,
                  borderData: FlBorderData(show: false),
                  titlesData: _monthTitles([for (final m in months) _monthLabel(m.month)], reserved: 30).copyWith(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 25,
                        getTitlesWidget: (v, meta) => Text('${v.toInt()}', style: _chartText),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: AppColors.info.withAlpha(30)),
                      spots: [for (var i = 0; i < months.length; i++) FlSpot(i.toDouble(), months[i].avg)],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top performers
// ---------------------------------------------------------------------------

class _TopPerformersCard extends StatelessWidget {
  final List<TopPerformer> items;
  const _TopPerformersCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _Card(
      title: 'Meilleur Performeur',
      child: items.isEmpty
          ? const Text('Aucune donnée.')
          : Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: i == items.length - 1 ? null : const Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 22, child: Text('${i + 1}', style: text.titleSmall?.copyWith(color: AppColors.textTertiary))),
                        AppAvatar(name: items[i].fullName, imageUrl: items[i].avatar, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(items[i].fullName, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${items[i].moyenne.round()}/100', style: text.bodySmall),
                            ],
                          ),
                        ),
                        if (items[i].age != null) Text('${items[i].age} ans', style: text.bodySmall),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
