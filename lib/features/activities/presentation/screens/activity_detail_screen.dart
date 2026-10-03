import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_guard.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../social_common/social_utils.dart';
import '../../application/activities_providers.dart';
import '../../data/activities_repository.dart';
import '../../data/models/activity.dart';
import '../../data/models/activity_task.dart';
import '../widgets/activity_widgets.dart';
import 'create_activity_screen.dart';

/// Legacy `details-activite.php`: tabs Activité / Tâches / Liste de présences /
/// Rapports, with invited/present/absent/tasks counters and owner controls.
class ActivityDetailScreen extends ConsumerStatefulWidget {
  final int activityId;
  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  int get id => widget.activityId;

  void _reload() {
    ref.invalidate(activityDetailProvider(id));
    ref.invalidate(activityTasksProvider(id));
    ref.invalidate(activityReportsProvider(id));
    ref.invalidate(filteredActivitiesProvider);
    ref.invalidate(myActivitiesProvider);
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _reload();
    } on Failure catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activityDetailProvider(id));
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user.id : -1;

    return async.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Activité')), body: const SkeletonList(count: 4, itemHeight: 110)),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Activité')), body: ErrorState(error: e, onRetry: _reload)),
      data: (activity) {
        final tasks = ref.watch(activityTasksProvider(id)).valueOrNull ?? const <ActivityTask>[];
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(activity.titre, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
                if (activity.ownerId == me)
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await _confirm(context, 'Supprimer cette activité ?', 'Cette action est définitive.');
                        if (ok == true) {
                          await _run(() => ref.read(activitiesRepositoryProvider).delete(id));
                          if (context.mounted) Navigator.of(context).maybePop();
                        }
                      }
                    },
                    itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text("Supprimer l'activité"))],
                  ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [Tab(text: 'Activité'), Tab(text: 'Tâches'), Tab(text: 'Liste de présences'), Tab(text: 'Rapports')],
              ),
            ),
            body: TabBarView(children: [
              _InfoTab(activity: activity, me: me, taskCount: tasks.length, onEdit: () => _edit(activity), run: _run),
              _TasksTab(activity: activity, me: me, tasks: tasks, run: _run),
              _AttendanceTab(activity: activity, me: me, run: _run),
              _ReportsTab(activityId: id),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _edit(Activity a) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => CreateActivityScreen(existing: a)));
    if (ok == true) _reload();
  }
}

Future<bool?> _confirm(BuildContext context, String title, String message) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
      ],
    ),
  );
}

// ---------------------------------------------------------------- Activité --

class _InfoTab extends ConsumerWidget {
  final Activity activity;
  final int me;
  final int taskCount;
  final VoidCallback onEdit;
  final Future<void> Function(Future<void> Function()) run;
  const _InfoTab({required this.activity, required this.me, required this.taskCount, required this.onEdit, required this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final repo = ref.read(activitiesRepositoryProvider);
    final isOwner = activity.ownerId == me;
    final color = activityStatusColor(activity.statut);
    final joined = activity.isParticipant(me);

    final main = SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              if (activity.team != null)
                AppAvatar(name: activity.team!.nom, imageUrl: activity.team!.logo, size: 64, rounded: true)
              else
                DateBadgeTile(date: activity.date, color: Colors.white, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(activity.titre, style: text.titleLarge?.copyWith(color: Colors.white)),
                  if (activity.team != null) Text(activity.team!.nom, style: text.bodyMedium?.copyWith(color: Colors.white70)),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if ((activity.contenu ?? '').isNotEmpty) Text(activity.contenu!, style: text.bodyLarge),
              const SizedBox(height: 12),
              if (activity.owner != null)
                Row(children: [
                  AppAvatar(name: activity.owner!.fullName, imageUrl: activity.owner!.avatar, size: 46),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(activity.owner!.fullName, style: text.titleSmall),
                    Text('Organisateur', style: text.bodySmall?.copyWith(color: AppColors.primary)),
                  ]),
                ]),
              const Divider(height: 28),
              InfoRow(icon: Icons.place_outlined, label: 'Lieu', value: activity.lieu),
              InfoRow(
                icon: Icons.event_outlined,
                label: 'Date',
                value: 'Le ${formatLongDate(activity.date)}${(activity.heure ?? '').isNotEmpty ? ' à ${hhmm(activity.heure!)}' : ''}',
              ),
              if ((activity.categorie ?? '').isNotEmpty) InfoRow(icon: Icons.category_outlined, label: 'Catégorie', value: activity.categorie),
              if ((activity.genre ?? '').isNotEmpty) InfoRow(icon: Icons.wc_outlined, label: 'Genre', value: activity.genre),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(activityStatusIcon(activity.statut), color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(Activity.statusLabel(activity.statut), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );

    final side = Column(children: [
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
        children: [
          StatTile(label: 'Personnes conviées', value: '${activity.invitedCount}', icon: Icons.groups_outlined),
          StatTile(label: 'Personnes présentes', value: '${activity.presentCount}', icon: Icons.how_to_reg_outlined, color: AppColors.success),
          StatTile(label: 'Personnes absentes', value: '${activity.absentCount}', icon: Icons.person_off_outlined, color: AppColors.error),
          StatTile(label: 'Nombre de tâches', value: '$taskCount', icon: Icons.assignment_turned_in_outlined, color: AppColors.info),
        ],
      ),
      const SizedBox(height: 16),
      if (isOwner) ...[
        if (activity.isPlanned)
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Mettre à jour'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          ),
        ActivityStatusActions(activity: activity, onChange: (s) => run(() => repo.setStatus(activity.id, s))),
      ] else if (!activity.isCancelled && !activity.isFinished)
        joined
            ? OutlinedButton.icon(
                onPressed: () => run(() => repo.leave(activity.id)),
                icon: const Icon(Icons.logout),
                label: const Text('Se désinscrire'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              )
            : FilledButton.icon(
                onPressed: () async {
                  if (await requireAccount(context, ref, reason: 'participer à cette activité')) run(() => repo.join(activity.id));
                },
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text('Participer'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              ),
    ]);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: main),
              const SizedBox(width: 16),
              Expanded(child: side),
            ])
          else ...[main, const SizedBox(height: 16), side],
        ],
      );
    });
  }
}

// ------------------------------------------------------------------ Tâches --

class _TasksTab extends ConsumerWidget {
  final Activity activity;
  final int me;
  final List<ActivityTask> tasks;
  final Future<void> Function(Future<void> Function()) run;
  const _TasksTab({required this.activity, required this.me, required this.tasks, required this.run});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    int? user;
    final ctrl = TextEditingController();
    final participants = activity.participants ?? const <ActivityParticipant>[];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Ajouter une tâche'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              initialValue: user,
              isExpanded: true,
              decoration: const InputDecoration(labelText: "Sélectionner l'utilisateur"),
              items: [
                for (final p in participants) DropdownMenuItem(value: p.id, child: Text(p.fullName, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setS(() => user = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Description de la tâche')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ENREGISTRER LA TÂCHE')),
          ],
        ),
      ),
    );
    if (ok == true && user != null && ctrl.text.trim().isNotEmpty) {
      await run(() => ref.read(activitiesRepositoryProvider).createTask(activity.id, assigneeId: user!, tache: ctrl.text.trim(), teamId: activity.teamId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(activitiesRepositoryProvider);
    final isOwner = activity.ownerId == me;
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: Text('Liste des tâches', style: text.titleLarge)),
          if (isOwner)
            FilledButton.icon(onPressed: () => _add(context, ref), icon: const Icon(Icons.add), label: const Text('Ajouter une tâche')),
        ]),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState(icon: Icons.assignment_outlined, title: 'Aucune tâche disponible'))
        else
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    AppAvatar(name: t.owner?.fullName ?? '?', imageUrl: t.owner?.avatar, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t.owner?.fullName ?? 'Utilisateur #${t.assigneeId}', style: text.titleSmall),
                        Text(timeAgo(t.createdAt), style: text.bodySmall?.copyWith(color: AppColors.primary)),
                      ]),
                    ),
                    StatusBadge(label: ActivityTask.statusLabel(t.statut), color: taskStatusColor(t.statut), icon: taskStatusIcon(t.statut)),
                  ]),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.tache, style: text.bodyLarge)),
                  Row(children: [
                    if (t.assigneeId == me && t.statut == TaskStatus.todo)
                      Expanded(child: _btn('Piger', Icons.thumb_up_outlined, AppColors.primary, () => run(() => repo.setTaskStatus(t.id, 1)))),
                    if ((isOwner || t.assigneeId == me) && !t.isDone && !t.isCancelled) ...[
                      if (t.assigneeId == me && t.statut == TaskStatus.todo) const SizedBox(width: 8),
                      Expanded(child: _btn('Effectuer', Icons.check_circle_outline, AppColors.success, () => run(() => repo.setTaskStatus(t.id, 2)))),
                    ],
                    if (isOwner && !t.isDone && !t.isCancelled) ...[
                      const SizedBox(width: 8),
                      Expanded(child: _btn('Annuler', Icons.cancel_outlined, AppColors.error, () => run(() => repo.setTaskStatus(t.id, 3)))),
                    ],
                  ]),
                ]),
              ),
            ),
      ],
    );
  }

  Widget _btn(String label, IconData icon, Color c, VoidCallback onTap) => FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(label),
        style: FilledButton.styleFrom(backgroundColor: c, minimumSize: const Size(0, 40)),
      );
}

// --------------------------------------------------------------- Présences --

class _AttendanceTab extends ConsumerWidget {
  final Activity activity;
  final int me;
  final Future<void> Function(Future<void> Function()) run;
  const _AttendanceTab({required this.activity, required this.me, required this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(activitiesRepositoryProvider);
    final isOwner = activity.ownerId == me;
    final participants = activity.participants ?? const <ActivityParticipant>[];
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: Text('Liste de présence', style: text.titleLarge)),
          StatusBadge(label: '${activity.presentCount}/${activity.invitedCount} présents', color: AppColors.success, icon: Icons.how_to_reg_outlined),
        ]),
        const SizedBox(height: 12),
        if (participants.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState(icon: Icons.groups_outlined, title: 'Aucun participant pour le moment'))
        else
          for (final p in participants)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SurfaceCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  Checkbox(
                    value: p.isPresent,
                    onChanged: (isOwner || p.id == me)
                        ? (v) => run(() => repo.setAttendance(activity.id, present: v ?? false, userId: p.id == me ? null : p.id))
                        : null,
                  ),
                  AppAvatar(name: p.fullName, imageUrl: p.avatar, size: 46),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p.fullName, style: text.titleSmall)),
                  StatusBadge(
                    label: p.isPresent ? 'Présent' : 'Absent',
                    color: p.isPresent ? AppColors.success : AppColors.textTertiary,
                  ),
                ]),
              ),
            ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Rapports --

class _ReportsTab extends ConsumerWidget {
  final int activityId;
  const _ReportsTab({required this.activityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityReportsProvider(activityId));
    final text = Theme.of(context).textTheme;
    return async.when(
      loading: () => const SkeletonList(count: 4, itemHeight: 96),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(activityReportsProvider(activityId))),
      data: (reports) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Rapports de performances', style: text.titleLarge),
          const SizedBox(height: 12),
          if (reports.isEmpty)
            const Padding(padding: EdgeInsets.only(top: 40), child: EmptyState(icon: Icons.insights_outlined, title: 'Aucun rapport de performance disponible'))
          else
            for (final r in reports)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      AppAvatar(name: r.user?.fullName ?? '?', imageUrl: r.user?.avatar, size: 46),
                      const SizedBox(width: 12),
                      Expanded(child: Text(r.user?.fullName ?? 'Joueur #${r.userId}', style: text.titleSmall)),
                      Text(timeAgo(r.createdAt), style: text.bodySmall),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: Text(r.performance, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700))),
                      Text(r.valueLabel, style: text.headlineSmall?.copyWith(color: AppColors.primary)),
                    ]),
                    if ((r.type ?? '').isNotEmpty || (r.categorie ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(spacing: 8, children: [
                          if ((r.type ?? '').isNotEmpty) StatusBadge(label: r.type!, color: AppColors.info),
                          if ((r.categorie ?? '').isNotEmpty) StatusBadge(label: r.categorie!, color: AppColors.textSecondary),
                        ]),
                      ),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}
