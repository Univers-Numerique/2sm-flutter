import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_config.dart';
import '../../data/models/admin_models.dart';
import '../widgets/admin_widgets.dart';

/// Legacy `admin/equipes.php`: search + asc/desc order, table (équipe,
/// responsable, lieu, "Gérer"), "Créer mon équipe" and pagination.
class AdminTeamsScreen extends ConsumerWidget {
  const AdminTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminTeamsFilterProvider);
    final async = ref.watch(adminTeamsProvider);
    void update(AdminListFilter f) => ref.read(adminTeamsFilterProvider.notifier).state = f;

    final columns = <AdminColumn<AdminTeamRow>>[
      AdminColumn(
        label: 'Équipe',
        flex: 4,
        sortKey: 'nom',
        cell: (c, t) => NameCell(
          leading: AppAvatar(name: t.nom, imageUrl: t.logo, size: 44, rounded: true),
          title: t.nom,
        ),
      ),
      AdminColumn(
        label: 'Responsable',
        flex: 3,
        cell: (c, t) => t.owner == null
            ? const Text('—')
            : NameCell(
                leading: AppAvatar(name: t.owner!.fullName, imageUrl: t.owner!.avatar, size: 30),
                title: t.owner!.fullName,
              ),
      ),
      AdminColumn(label: 'Lieu', flex: 3, cell: (c, t) => Text(t.lieu ?? '—')),
      AdminColumn(label: 'Membres', flex: 2, cell: (c, t) => Text('${t.membersCount}')),
      AdminColumn(label: 'Statut', flex: 2, cell: (c, t) => _TeamStatus(t.statut)),
      AdminColumn(
        label: 'Action',
        width: 110,
        cell: (c, t) => FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
          onPressed: () => context.push('/admin/manage/equipes/${t.id}'),
          child: const Text('Gérer'),
        ),
      ),
    ];

    return AdminScaffold(
      title: 'Administration',
      section: AdminSection.teams,
      body: AdminListPage<AdminTeamRow>(
        title: 'Équipes',
        subtitle: 'Toutes les équipes de la plateforme.',
        headerAction: FilledButton.icon(
          onPressed: () => context.push('/teams/create'),
          icon: const Icon(Icons.add),
          label: const Text('Créer mon équipe'),
        ),
        filters: FilterBar(
          children: [
            SizedBox(
              width: 300,
              child: DebouncedSearchField(
                initialValue: filter.search,
                onChanged: (v) => update(filter.copyWith(search: v)),
              ),
            ),
            OrderToggle(ascending: filter.ascending, onChanged: (v) => update(filter.copyWith(ascending: v))),
          ],
        ),
        async: async,
        onPage: (p) => update(filter.copyWith(page: p)),
        onRetry: () => ref.invalidate(adminTeamsProvider),
        emptyIcon: Icons.groups_outlined,
        emptyTitle: 'Aucune équipe trouvée',
        emptyMessage: filter.search.isNotEmpty ? 'Essayez une autre recherche.' : null,
        wideBody: (context, rows) => AdminDataTable<AdminTeamRow>(
          columns: columns,
          rows: rows,
          sortKey: 'nom',
          ascending: filter.ascending,
          onSort: (_) => update(filter.copyWith(ascending: !filter.ascending)),
          onRowTap: (t) => context.push('/teams/${t.id}'),
        ),
        narrowBody: (context, rows) => [
          for (final t in rows) Padding(padding: const EdgeInsets.only(bottom: 10), child: _TeamCard(team: t)),
        ],
      ),
    );
  }
}

class _TeamStatus extends StatelessWidget {
  final int statut;
  const _TeamStatus(this.statut);

  @override
  Widget build(BuildContext context) {
    final o = AdminStatus.optionFor(AdminEntity.equipes, statut);
    return Align(alignment: Alignment.centerLeft, child: StatusBadge(label: o.label, color: o.color, icon: o.icon));
  }
}

class _TeamCard extends StatelessWidget {
  final AdminTeamRow team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      onTap: () => context.push('/teams/${team.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: team.nom, imageUrl: team.logo, size: 52, rounded: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.nom, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(team.lieu ?? '—', style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _TeamStatus(team.statut),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              if (team.owner != null) ...[
                AppAvatar(name: team.owner!.fullName, imageUrl: team.owner!.avatar, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Responsable : ${team.owner!.fullName}', style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ] else
                const Spacer(),
              const Icon(Icons.people_outline, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('${team.membersCount}', style: text.labelMedium),
              const SizedBox(width: 12),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(72, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: () => context.push('/admin/manage/equipes/${team.id}'),
                child: const Text('Gérer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
