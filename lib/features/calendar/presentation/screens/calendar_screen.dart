import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../admin/presentation/widgets/admin_widgets.dart' show DebouncedSearchField;
import '../../../competitions/application/competitions_providers.dart';
import '../../../teams/application/teams_providers.dart';
import '../../application/calendar_providers.dart';
import '../../data/calendar_repository.dart';

const _matchColor = AppColors.primary;
const _activityColor = AppColors.warning;

enum _CalendarView { month, agenda }

/// A match or an activity, normalised for display.
class _CalEvent {
  final DateTime day;
  final bool isMatch;
  final String title;
  final String kind;
  final String detail;
  final String time;
  final int statut;
  final String? logo;
  final String route;

  const _CalEvent({
    required this.day,
    required this.isMatch,
    required this.title,
    required this.kind,
    required this.detail,
    required this.time,
    required this.statut,
    required this.route,
    this.logo,
  });

  Color get color => isMatch ? _matchColor : _activityColor;
}

DateTime? _dayOf(String? raw) {
  if (raw == null || raw.length < 10) return null;
  return DateTime.tryParse(raw.substring(0, 10));
}

String _hhmm(String? raw) => raw == null || raw.length < 5 ? '' : raw.substring(0, 5);

String _truncateWords(String? text, int words) {
  if (text == null || text.trim().isEmpty) return '';
  final parts = text.trim().split(RegExp(r'\s+'));
  return parts.length <= words ? parts.join(' ') : '${parts.take(words).join(' ')}…';
}

List<_CalEvent> _buildEvents(CalendarData data) {
  final events = <_CalEvent>[];
  for (final m in data.matches) {
    final day = _dayOf(m.dateDebut);
    if (day == null) continue;
    final home = m.homeTeam?.nom ?? 'Équipe #${m.homeTeamId}';
    final away = m.awayTeam?.nom ?? 'Équipe #${m.awayTeamId}';
    final competition = m.competition?.nom;
    events.add(_CalEvent(
      day: day,
      isMatch: true,
      title: '$home - $away',
      kind: competition != null && competition.isNotEmpty ? 'Compétition de $competition' : 'Match amical',
      detail: [
        if (m.categorie != null) 'catégorie ${m.categorie}',
        if (m.genre != null) 'genre ${m.genre}',
      ].join(' · '),
      time: _hhmm(m.heureDebut),
      statut: m.statut,
      logo: m.homeTeam?.logo,
      route: '/matches/${m.id}',
    ));
  }
  for (final a in data.activities) {
    final day = _dayOf(a.date);
    if (day == null) continue;
    events.add(_CalEvent(
      day: day,
      isMatch: false,
      title: a.titre,
      kind: a.team?.nom != null ? 'Activité · ${a.team!.nom}' : 'Activité',
      detail: _truncateWords(a.contenu, 20),
      time: _hhmm(a.heure),
      statut: a.statut,
      logo: a.team?.logo,
      route: '/activities/${a.id}',
    ));
  }
  events.sort((x, y) {
    final c = x.day.compareTo(y.day);
    return c != 0 ? c : x.time.compareTo(y.time);
  });
  return events;
}

/// Calendar of matches + activities — legacy `compte/calendrier.php` and its
/// `manage/{matchs,equipes,competitions,activites}/calendrier.php` variants
/// (evoCalendar fed by `get.php?table=CALENDRIER`): search bar, scope filter
/// (global / équipe / compétition), month grid and agenda, coloured by event
/// type, tap opens the match or activity.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selected = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  _CalendarView _view = _CalendarView.month;

  void _setFilter(CalendarFilter f) => ref.read(calendarFilterProvider.notifier).state = f;

  void _goToMonth(CalendarFilter f, DateTime month) {
    _setFilter(f.copyWith(month: DateTime(month.year, month.month)));
    final today = DateTime.now();
    setState(() {
      _selected = (month.year == today.year && month.month == today.month)
          ? DateTime(today.year, today.month, today.day)
          : DateTime(month.year, month.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(calendarFilterProvider);
    final async = ref.watch(calendarDataProvider);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;
    final events = async.valueOrNull == null ? const <_CalEvent>[] : _buildEvents(async.valueOrNull!);
    final byDay = <DateTime, List<_CalEvent>>{};
    for (final e in events) {
      byDay.putIfAbsent(e.day, () => []).add(e);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calendrier')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 12, wide ? 24 : 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Toolbar(
                  filter: filter,
                  view: _view,
                  onView: (v) => setState(() => _view = v),
                  onFilter: _setFilter,
                ),
                const SizedBox(height: 10),
                _MonthHeader(
                  month: filter.month,
                  loading: async.isLoading,
                  onPrevious: () => _goToMonth(filter, DateTime(filter.month.year, filter.month.month - 1)),
                  onNext: () => _goToMonth(filter, DateTime(filter.month.year, filter.month.month + 1)),
                  onToday: () => _goToMonth(filter, DateTime.now()),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: async.hasError && async.valueOrNull == null
                      ? ErrorState(error: async.error!, onRetry: () => ref.invalidate(calendarDataProvider))
                      : async.isLoading && async.valueOrNull == null
                          ? const _CalendarSkeleton()
                          : _view == _CalendarView.agenda
                              ? _Agenda(events: events, month: filter.month)
                              : wide
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: _MonthGrid(
                                            month: filter.month,
                                            selected: _selected,
                                            byDay: byDay,
                                            rich: true,
                                            onSelect: (d) => setState(() => _selected = d),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 380,
                                          child: _DayPanel(day: _selected, events: byDay[_selected] ?? const []),
                                        ),
                                      ],
                                    )
                                  : ListView(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      children: [
                                        SizedBox(
                                          height: 330,
                                          child: _MonthGrid(
                                            month: filter.month,
                                            selected: _selected,
                                            byDay: byDay,
                                            rich: false,
                                            onSelect: (d) => setState(() => _selected = d),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        _DayEvents(day: _selected, events: byDay[_selected] ?? const []),
                                      ],
                                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar: search, scope, view
// ---------------------------------------------------------------------------

class _Toolbar extends ConsumerWidget {
  final CalendarFilter filter;
  final _CalendarView view;
  final ValueChanged<_CalendarView> onView;
  final ValueChanged<CalendarFilter> onFilter;
  const _Toolbar({required this.filter, required this.view, required this.onView, required this.onFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teams = ref.watch(teamsListProvider).valueOrNull ?? const [];
    final competitions = ref.watch(competitionsListProvider).valueOrNull ?? const [];

    final scopePicker = switch (filter.scope) {
      CalendarScope.global => null,
      CalendarScope.team => SizedBox(
          width: 240,
          child: DropdownButtonFormField<int>(
            value: teams.any((t) => t.id == filter.teamId) ? filter.teamId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Équipe', isDense: true, prefixIcon: Icon(Icons.groups_outlined)),
            items: [for (final t in teams) DropdownMenuItem(value: t.id, child: Text(t.nom, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => onFilter(filter.copyWith(teamId: v)),
          ),
        ),
      CalendarScope.competition => SizedBox(
          width: 260,
          child: DropdownButtonFormField<int>(
            value: competitions.any((c) => c.id == filter.competitionId) ? filter.competitionId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Compétition', isDense: true, prefixIcon: Icon(Icons.emoji_events_outlined)),
            items: [for (final c in competitions) DropdownMenuItem(value: c.id, child: Text(c.nom, overflow: TextOverflow.ellipsis))],
            onChanged: (v) => onFilter(filter.copyWith(competitionId: v)),
          ),
        ),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: DebouncedSearchField(initialValue: filter.search, onChanged: (v) => onFilter(filter.copyWith(search: v))),
          ),
          SegmentedButton<CalendarScope>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: CalendarScope.global, label: Text('Global'), icon: Icon(Icons.public, size: 16)),
              ButtonSegment(value: CalendarScope.team, label: Text('Équipe'), icon: Icon(Icons.groups_outlined, size: 16)),
              ButtonSegment(value: CalendarScope.competition, label: Text('Compétition'), icon: Icon(Icons.emoji_events_outlined, size: 16)),
            ],
            selected: {filter.scope},
            onSelectionChanged: (s) => onFilter(filter.copyWith(scope: s.first)),
          ),
          ?scopePicker,
          SegmentedButton<_CalendarView>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: const [
              ButtonSegment(value: _CalendarView.month, icon: Icon(Icons.calendar_view_month, size: 16), label: Text('Mois')),
              ButtonSegment(value: _CalendarView.agenda, icon: Icon(Icons.view_agenda_outlined, size: 16), label: Text('Agenda')),
            ],
            selected: {view},
            onSelectionChanged: (s) => onView(s.first),
          ),
          const _TypeLegend(),
        ],
      ),
    );
  }
}

class _TypeLegend extends StatelessWidget {
  const _TypeLegend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        );
    return Wrap(spacing: 14, children: [item(_matchColor, 'Matchs'), item(_activityColor, 'Activités')]);
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final bool loading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  const _MonthHeader({required this.month, required this.loading, required this.onPrevious, required this.onNext, required this.onToday});

  @override
  Widget build(BuildContext context) {
    final label = toBeginningOfSentenceCase(DateFormat('MMMM y', 'fr_FR').format(month));
    return Row(
      children: [
        IconButton.filledTonal(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Column(
            children: [
              Text(label, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              if (loading) const Padding(padding: EdgeInsets.only(top: 4), child: SizedBox(width: 60, child: LinearProgressIndicator(minHeight: 2))),
            ],
          ),
        ),
        TextButton(onPressed: onToday, child: const Text("Aujourd'hui")),
        IconButton.filledTonal(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(children: [Expanded(child: SkeletonBox(height: 400, radius: 24)), SizedBox(height: 12)]);
  }
}

// ---------------------------------------------------------------------------
// Month grid
// ---------------------------------------------------------------------------

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final Map<DateTime, List<_CalEvent>> byDay;
  final bool rich;
  final ValueChanged<DateTime> onSelect;
  const _MonthGrid({required this.month, required this.selected, required this.byDay, required this.rich, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((leading + daysInMonth) / 7).ceil();
    final today = DateTime.now();
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(w, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Column(
              children: [
                for (var r = 0; r < rows; r++)
                  Expanded(
                    child: Row(
                      children: [
                        for (var c = 0; c < 7; c++)
                          Expanded(
                            child: Builder(builder: (context) {
                              final dayNum = r * 7 + c - leading + 1;
                              if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();
                              final date = DateTime(month.year, month.month, dayNum);
                              final list = byDay[date] ?? const <_CalEvent>[];
                              return _DayCell(
                                day: dayNum,
                                events: list,
                                isToday: date.year == today.year && date.month == today.month && date.day == today.day,
                                isSelected: date == selected,
                                rich: rich,
                                onTap: () => onSelect(date),
                              );
                            }),
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

class _DayCell extends StatelessWidget {
  final int day;
  final List<_CalEvent> events;
  final bool isToday;
  final bool isSelected;
  final bool rich;
  final VoidCallback onTap;
  const _DayCell({required this.day, required this.events, required this.isToday, required this.isSelected, required this.rich, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final showChips = rich;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withAlpha(24) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? AppColors.primary : (isToday ? AppColors.secondary : AppColors.border.withAlpha(120)), width: isSelected || isToday ? 1.6 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isToday ? AppColors.secondary : Colors.transparent, shape: BoxShape.circle),
                child: Text(
                  '$day',
                  style: text.labelMedium?.copyWith(color: isToday ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              if (events.isNotEmpty)
                Expanded(
                  child: showChips
                      ? LayoutBuilder(builder: (context, box) {
                          final fit = (box.maxHeight / 20).floor().clamp(1, 3);
                          final shown = events.take(events.length > fit ? fit - 1 : fit).toList();
                          final more = events.length - shown.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final e in shown)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(color: e.color.withAlpha(34), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    e.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: e.color),
                                  ),
                                ),
                              if (more > 0) Text('+$more', style: text.labelSmall),
                            ],
                          );
                        })
                      : Align(
                          alignment: Alignment.bottomLeft,
                          child: Wrap(
                            spacing: 3,
                            runSpacing: 3,
                            children: [
                              for (final e in events.take(4))
                                Container(width: 7, height: 7, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day panel / events
// ---------------------------------------------------------------------------

class _DayPanel extends StatelessWidget {
  final DateTime day;
  final List<_CalEvent> events;
  const _DayPanel({required this.day, required this.events});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: _DayEvents(day: day, events: events));
  }
}

class _DayEvents extends StatelessWidget {
  final DateTime day;
  final List<_CalEvent> events;
  const _DayEvents({required this.day, required this.events});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = toBeginningOfSentenceCase(DateFormat('EEEE d MMMM', 'fr_FR').format(day));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Expanded(child: Text(title, style: text.titleMedium)),
              Text('${events.length} événement(s)', style: text.bodySmall),
            ],
          ),
        ),
        if (events.isEmpty)
          SurfaceCard(
            child: Row(
              children: [
                const Icon(Icons.event_busy_outlined, color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(child: Text('Rien de prévu ce jour-là.', style: text.bodyMedium)),
              ],
            ),
          )
        else
          for (final e in events) Padding(padding: const EdgeInsets.only(bottom: 10), child: _EventCard(event: e)),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final _CalEvent event;
  const _EventCard({required this.event});

  static const _matchLabels = ['À venir', 'En cours', 'Annulé', 'Terminé'];
  static const _activityLabels = ['Activité future', 'Activité en cours', 'Activité annulée', 'Activité terminée'];
  static const _statusColors = [AppColors.primary, AppColors.warning, AppColors.error, AppColors.success];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final s = event.statut.clamp(0, 3);
    final label = (event.isMatch ? _matchLabels : _activityLabels)[s];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(event.route),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: event.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppAvatar(name: event.title, imageUrl: event.logo, size: 38, rounded: true),
                          const SizedBox(width: 10),
                          Expanded(child: Text(event.title, style: text.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusBadge(
                            label: event.isMatch ? 'Match' : 'Activité',
                            color: event.color,
                            icon: event.isMatch ? Icons.sports_soccer : Icons.event_note_outlined,
                          ),
                          StatusBadge(label: label, color: _statusColors[s]),
                          if (event.time.isNotEmpty)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text('à ${event.time}', style: text.labelMedium),
                            ]),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(event.kind, style: text.bodyMedium),
                      if (event.detail.isNotEmpty) Text(event.detail, style: text.bodySmall),
                      const SizedBox(height: 6),
                      Text('En savoir plus', style: text.labelLarge?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Agenda (chronological list of the month)
// ---------------------------------------------------------------------------

class _Agenda extends StatelessWidget {
  final List<_CalEvent> events;
  final DateTime month;
  const _Agenda({required this.events, required this.month});

  @override
  Widget build(BuildContext context) {
    final inMonth = events.where((e) => e.day.year == month.year && e.day.month == month.month).toList();
    if (inMonth.isEmpty) {
      return const EmptyState(icon: Icons.event_busy_outlined, title: 'Aucun événement ce mois-ci', message: 'Changez de mois ou de filtre.');
    }
    final groups = <DateTime, List<_CalEvent>>{};
    for (final e in inMonth) {
      groups.putIfAbsent(e.day, () => []).add(e);
    }
    final days = groups.keys.toList()..sort();
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final d in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('${d.day}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(DateFormat('MMM', 'fr_FR').format(d).replaceAll('.', ''),
                          style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(toBeginningOfSentenceCase(DateFormat('EEEE', 'fr_FR').format(d)), style: text.titleMedium),
              ],
            ),
          ),
          LayoutBuilder(builder: (context, box) {
            final cols = box.maxWidth >= 900 ? 2 : 1;
            final w = (box.maxWidth - 12 * (cols - 1)) / cols;
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [for (final e in groups[d]!) SizedBox(width: w, child: _EventCard(event: e))],
            );
          }),
        ],
      ],
    );
  }
}
