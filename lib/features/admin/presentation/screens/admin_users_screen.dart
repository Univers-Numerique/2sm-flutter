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

/// Legacy `admin/utilisateurs.php`: filters (poste grouped by category,
/// catégorie, genre, nom), table (nom complet, catégorie, genre, âge, poste,
/// équipe, "Gérer") and pagination.
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminUsersFilterProvider);
    final async = ref.watch(adminUsersProvider);
    void update(AdminUsersFilter f) => ref.read(adminUsersFilterProvider.notifier).state = f;

    final columns = <AdminColumn<AdminUserRow>>[
      AdminColumn(
        label: 'Nom complet',
        flex: 4,
        sortKey: 'nom',
        cell: (c, u) => NameCell(
          leading: AppAvatar(name: u.fullName, imageUrl: u.avatar, size: 40),
          title: u.fullName.isEmpty ? '—' : u.fullName,
          subtitle: u.email,
        ),
      ),
      AdminColumn(label: 'Catégorie', flex: 2, cell: (c, u) => Text(u.categorie ?? '—')),
      AdminColumn(label: 'Genre', flex: 2, cell: (c, u) => _GenreText(u.genre)),
      AdminColumn(label: 'Âge', flex: 2, sortKey: 'age', cell: (c, u) => _AgeBadge(u.age)),
      AdminColumn(label: 'Poste', flex: 3, cell: (c, u) => Text(u.poste ?? '—')),
      AdminColumn(
        label: 'Équipe',
        flex: 3,
        cell: (c, u) => Text(u.equipe ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      AdminColumn(label: 'Statut', flex: 2, cell: (c, u) => _UserStatusBadge(u)),
      AdminColumn(label: 'Action', width: 110, cell: (c, u) => _ManageButton(entity: AdminEntity.utilisateurs, id: u.id)),
    ];

    return AdminScaffold(
      title: 'Administration',
      section: AdminSection.users,
      body: AdminListPage<AdminUserRow>(
        title: 'Utilisateurs',
        subtitle: 'Recherchez, filtrez et gérez les comptes de la plateforme.',
        filters: _Filters(filter: filter, onChange: update),
        async: async,
        onPage: (p) => update(filter.copyWith(page: p)),
        onRetry: () => ref.invalidate(adminUsersProvider),
        emptyIcon: Icons.person_search_outlined,
        emptyTitle: 'Aucun utilisateur trouvé',
        emptyMessage: filter.hasFilters ? 'Modifiez ou réinitialisez les filtres.' : null,
        wideBody: (context, rows) => AdminDataTable<AdminUserRow>(
          columns: columns,
          rows: rows,
          sortKey: filter.sort,
          ascending: filter.ascending,
          onSort: (key) => update(filter.copyWith(
            sort: key,
            ascending: filter.sort == key ? !filter.ascending : true,
          )),
          onRowTap: (u) => context.push('/admin/manage/utilisateurs/${u.id}'),
        ),
        narrowBody: (context, rows) => [
          for (final u in rows) Padding(padding: const EdgeInsets.only(bottom: 10), child: _UserCard(user: u)),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  final AdminUsersFilter filter;
  final ValueChanged<AdminUsersFilter> onChange;
  const _Filters({required this.filter, required this.onChange});

  @override
  Widget build(BuildContext context) {
    AdminUsersFilter keep({String? poste, String? categorie, String? genre, String? search, bool clearPoste = false, bool clearCategorie = false, bool clearGenre = false}) {
      return filter.copyWith(
        search: search ?? filter.search,
        poste: poste ?? filter.poste,
        categorie: categorie ?? filter.categorie,
        genre: genre ?? filter.genre,
        clearPoste: clearPoste,
        clearCategorie: clearCategorie,
        clearGenre: clearGenre,
        sort: filter.sort,
        ascending: filter.ascending,
      );
    }

    final posteItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('Tous les postes')),
      for (final entry in adminPostesByCategory.entries) ...[
        DropdownMenuItem<String?>(
          value: '__group_${entry.key}',
          enabled: false,
          child: Text(
            entry.key.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.6),
          ),
        ),
        for (final p in entry.value) DropdownMenuItem<String?>(value: p, child: Text(p, overflow: TextOverflow.ellipsis)),
      ],
    ];

    return FilterBar(
      children: [
        FilterDropdown<String>(
          label: 'Poste',
          width: 250,
          value: filter.poste,
          items: posteItems,
          onChanged: (v) => onChange(keep(poste: v, clearPoste: v == null)),
        ),
        FilterDropdown<String>(
          label: 'Catégorie',
          value: filter.categorie,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Toutes les catégories')),
            for (final c in adminCategories) DropdownMenuItem<String?>(value: c, child: Text(c)),
          ],
          onChanged: (v) => onChange(keep(categorie: v, clearCategorie: v == null)),
        ),
        FilterDropdown<String>(
          label: 'Genre',
          width: 160,
          value: filter.genre,
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Tous')),
            for (final g in adminGenres) DropdownMenuItem<String?>(value: g, child: Text(g)),
          ],
          onChanged: (v) => onChange(keep(genre: v, clearGenre: v == null)),
        ),
        SizedBox(
          width: 260,
          child: DebouncedSearchField(
            initialValue: filter.search ?? '',
            onChanged: (v) => onChange(filter.copyWith(
              search: v,
              clearSearch: v.isEmpty,
              genre: filter.genre,
              poste: filter.poste,
              categorie: filter.categorie,
              sort: filter.sort,
              ascending: filter.ascending,
            )),
          ),
        ),
        if (filter.hasFilters)
          TextButton.icon(
            onPressed: () => onChange(const AdminUsersFilter()),
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: const Text('Réinitialiser'),
          ),
      ],
    );
  }
}

class _GenreText extends StatelessWidget {
  final String? genre;
  const _GenreText(this.genre);

  @override
  Widget build(BuildContext context) {
    if (genre == null || genre!.isEmpty) return const Text('—');
    return Text(
      genre!,
      style: TextStyle(fontWeight: FontWeight.w600, color: genre == 'Masculin' ? AppColors.info : AppColors.error),
    );
  }
}

class _AgeBadge extends StatelessWidget {
  final int? age;
  const _AgeBadge(this.age);

  @override
  Widget build(BuildContext context) {
    if (age == null) return const Text('—');
    return Align(alignment: Alignment.centerLeft, child: StatusBadge(label: '$age ans', color: AppColors.primary));
  }
}

class _UserStatusBadge extends StatelessWidget {
  final AdminUserRow user;
  const _UserStatusBadge(this.user);

  @override
  Widget build(BuildContext context) {
    if (user.isBlocked) {
      return const Align(alignment: Alignment.centerLeft, child: StatusBadge(label: 'Bloqué', color: AppColors.error, icon: Icons.block));
    }
    if (user.isAdmin) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: StatusBadge(label: 'Administrateur', color: AppColors.secondary, icon: Icons.shield_outlined),
      );
    }
    final o = AdminStatus.optionFor(AdminEntity.utilisateurs, user.statut);
    return Align(alignment: Alignment.centerLeft, child: StatusBadge(label: o.label, color: o.color, icon: o.icon));
  }
}

class _ManageButton extends StatelessWidget {
  final AdminEntity entity;
  final int id;
  const _ManageButton({required this.entity, required this.id});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size(80, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
      onPressed: () => context.push('/admin/manage/${entity.key}/$id'),
      child: const Text('Gérer'),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUserRow user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      onTap: () => context.push('/admin/manage/utilisateurs/${user.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName.isEmpty ? '—' : user.fullName, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (user.email != null) Text(user.email!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _UserStatusBadge(user),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (user.age != null) StatusBadge(label: '${user.age} ans', color: AppColors.primary),
              if (user.genre != null)
                StatusBadge(label: user.genre!, color: user.genre == 'Masculin' ? AppColors.info : AppColors.error),
              if (user.categorie != null) StatusBadge(label: user.categorie!, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 10),
          InfoRow(icon: Icons.sports_soccer_outlined, label: 'Poste', value: user.poste),
          InfoRow(icon: Icons.groups_outlined, label: 'Équipe', value: user.equipe),
          Align(alignment: Alignment.centerRight, child: _ManageButton(entity: AdminEntity.utilisateurs, id: user.id)),
        ],
      ),
    );
  }
}
