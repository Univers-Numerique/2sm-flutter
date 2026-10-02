import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../teams/application/teams_providers.dart';
import '../../application/activities_providers.dart';
import '../../data/activities_repository.dart';
import '../../data/models/activity.dart';
import '../widgets/activity_widgets.dart';
import 'create_activity_screen.dart';

/// Legacy `activites.php` (all activities, team + status filters) and
/// `mes-activites.php` (my activities + "Ajouter une activité").
class ActivitiesListScreen extends ConsumerStatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  ConsumerState<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends ConsumerState<ActivitiesListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  int? _mineStatut;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const CreateActivityScreen()));
    if (created == true) _refresh();
  }

  void _refresh() {
    ref.invalidate(filteredActivitiesProvider);
    ref.invalidate(myActivitiesProvider);
  }

  Future<void> _changeStatus(Activity a, int statut) async {
    try {
      await ref.read(activitiesRepositoryProvider).setStatus(a.id, statut);
      _refresh();
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    // API: creating an activity needs manager level (statut >= 3, admin or a team-manager position).
    final canCreate = auth is AuthAuthenticated && (auth.user.statut >= 3 || auth.user.isAdmin);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités'),
        actions: [
          IconButton(tooltip: 'Actualiser', onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Calendrier', onPressed: () => context.push('/calendar'), icon: const Icon(Icons.calendar_month_outlined)),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Toutes les activités'), Tab(text: 'Mes activités')],
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une activité'),
            )
          : null,
      body: TabBarView(controller: _tabs, children: [_allTab(), _mineTab()]),
    );
  }

  Widget _allTab() {
    final filter = ref.watch(activityFilterProvider);
    final async = ref.watch(filteredActivitiesProvider);
    final teams = ref.watch(teamsListProvider).valueOrNull ?? const [];
    final me = _meId();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<int?>(
            initialValue: filter.teamId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Équipe', prefixIcon: Icon(Icons.groups_outlined), isDense: true),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Toutes les équipes')),
              for (final t in teams) DropdownMenuItem<int?>(value: t.id, child: Text(t.nom, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => ref.read(activityFilterProvider.notifier).state = filter.copyWith(teamId: v, clearTeamId: v == null),
          ),
        ),
        _statusChips(
          filter.statut,
          (v) => ref.read(activityFilterProvider.notifier).state = filter.copyWith(statut: v, clearStatut: v == null),
        ),
        Expanded(
          child: async.when(
            loading: () => const SkeletonList(count: 5, itemHeight: 120),
            error: (e, _) => ErrorState(error: e, onRetry: _refresh),
            data: (items) => _list(items, me, emptyMessage: 'Aucune activité trouvée'),
          ),
        ),
      ],
    );
  }

  Widget _mineTab() {
    final me = _meId();
    final async = ref.watch(myActivitiesProvider);
    final all = ref.watch(filteredActivitiesProvider);
    return Column(
      children: [
        _statusChips(_mineStatut, (v) => setState(() => _mineStatut = v)),
        Expanded(
          child: async.when(
            loading: () => const SkeletonList(count: 5, itemHeight: 120),
            error: (e, _) => ErrorState(error: e, onRetry: _refresh),
            data: (participating) {
              final byId = <int, Activity>{for (final a in participating) a.id: a};
              for (final a in all.valueOrNull ?? const <Activity>[]) {
                if (a.ownerId == me) byId[a.id] = a;
              }
              var items = byId.values.toList()..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
              if (_mineStatut != null) items = items.where((a) => a.statut == _mineStatut).toList();
              return _list(items, me, emptyMessage: "Vous n'avez aucune activité pour le moment");
            },
          ),
        ),
      ],
    );
  }

  int _meId() {
    final s = ref.watch(authNotifierProvider);
    return s is AuthAuthenticated ? s.user.id : -1;
  }

  Widget _statusChips(int? selected, void Function(int?) onSelect) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: const Text('Toutes les activités'), selected: selected == null, onSelected: (_) => onSelect(null)),
          ),
          for (final s in [ActivityStatus.planned, ActivityStatus.started, ActivityStatus.cancelled, ActivityStatus.finished])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(activityStatusIcon(s), size: 16, color: activityStatusColor(s)),
                label: Text(Activity.statusLabel(s)),
                selected: selected == s,
                onSelected: (_) => onSelect(selected == s ? null : s),
              ),
            ),
        ],
      ),
    );
  }

  Widget _list(List<Activity> items, int me, {required String emptyMessage}) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        title: emptyMessage,
        action: FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Ajouter une activité')),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 720 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 200,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final a = items[i];
            final owner = a.ownerId == me;
            return ActivityCard(
              activity: a,
              onTap: () => context.push('/activities/${a.id}'),
              actions: owner && (a.isPlanned || a.isStarted)
                  ? ActivityStatusActions(activity: a, compact: true, onChange: (s) => _changeStatus(a, s))
                  : null,
            );
          },
        );
      }),
    );
  }
}
