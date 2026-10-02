import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_config.dart';
import '../../data/models/admin_models.dart';
import '../widgets/admin_widgets.dart';
import '../../../../shared/widgets/app_ui.dart';

/// Legacy `admin/terrains.php`: search + order, cards (photo, nom, lieu,
/// "Ajouté par", "Localiser le terrain", "Gérer") and pagination.
class AdminFieldsScreen extends ConsumerWidget {
  const AdminFieldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminFieldsFilterProvider);
    final async = ref.watch(adminFieldsProvider);
    void update(AdminListFilter f) => ref.read(adminFieldsFilterProvider.notifier).state = f;

    return AdminScaffold(
      title: 'Administration',
      section: AdminSection.fields,
      body: AdminListPage<AdminFieldRow>(
        title: 'Terrains',
        subtitle: 'Stades et terrains enregistrés.',
        headerAction: FilledButton.icon(
          onPressed: () => context.push('/fields/create'),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un terrain'),
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
        onRetry: () => ref.invalidate(adminFieldsProvider),
        emptyIcon: Icons.stadium_outlined,
        emptyTitle: 'Aucun terrain trouvé',
        emptyMessage: filter.search.isNotEmpty ? 'Essayez une autre recherche.' : null,
        wideBody: (context, rows) => GridView.builder(
          padding: const EdgeInsets.only(bottom: 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 340,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: rows.length,
          itemBuilder: (context, i) => _FieldCard(field: rows[i]),
        ),
        narrowBody: (context, rows) => [
          for (final f in rows)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: SizedBox(height: 340, child: _FieldCard(field: f))),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final AdminFieldRow field;
  const _FieldCard({required this.field});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = AdminStatus.optionFor(AdminEntity.terrains, field.statut);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AppCover(
                imageUrl: field.photo,
                height: 150,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: StatusBadge(label: status.label, color: status.color, icon: status.icon, solid: true),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field.nomTerrain, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 15, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(child: Text(field.lieu ?? '—', style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    field.owner == null ? 'Ajouté par —' : 'Ajouté par ${field.owner!.fullName}',
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => launchUrl(Uri.parse(field.mapsUrl), mode: LaunchMode.externalApplication),
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Localiser', overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.push('/admin/manage/terrains/${field.id}'),
                          child: const Text('Gérer'),
                        ),
                      ),
                    ],
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
