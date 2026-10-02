import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_config.dart';
import '../../data/models/admin_models.dart';
import '../widgets/admin_widgets.dart';

/// Legacy `admin/competitions.php`: filters (statut, catégorie, genre, nom),
/// "Créer une competition", one card per competition (photo, catégorie,
/// genre, statut, description, déroulement with progress bar, "Voir les
/// détails", "Gérer") and pagination.
class AdminCompetitionsScreen extends ConsumerWidget {
  const AdminCompetitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(adminCompetitionsFilterProvider);
    final async = ref.watch(adminCompetitionsProvider);
    void update(AdminCompetitionsFilter f) => ref.read(adminCompetitionsFilterProvider.notifier).state = f;

    AdminCompetitionsFilter keep({
      int? statut,
      bool clearStatut = false,
      String? categorie,
      bool clearCategorie = false,
      String? genre,
      bool clearGenre = false,
      String? search,
    }) =>
        filter.copyWith(
          search: search ?? filter.search,
          statut: statut ?? filter.statut,
          clearStatut: clearStatut,
          categorie: categorie ?? filter.categorie,
          clearCategorie: clearCategorie,
          genre: genre ?? filter.genre,
          clearGenre: clearGenre,
        );

    return AdminScaffold(
      title: 'Administration',
      section: AdminSection.competitions,
      body: AdminListPage<AdminCompetitionRow>(
        title: 'Compétitions',
        subtitle: 'Championnats et coupes de la plateforme.',
        headerAction: FilledButton.icon(
          onPressed: () => context.push('/competitions/create'),
          icon: const Icon(Icons.add),
          label: const Text('Créer une compétition'),
        ),
        filters: FilterBar(
          children: [
            FilterDropdown<int>(
              label: 'Statut',
              width: 210,
              value: filter.statut,
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Toutes les compétitions')),
                for (final o in AdminStatus.competitions) DropdownMenuItem<int?>(value: o.value, child: Text(o.label)),
              ],
              onChanged: (v) => update(keep(statut: v, clearStatut: v == null)),
            ),
            FilterDropdown<String>(
              label: 'Catégorie',
              value: filter.categorie,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Toutes les catégories')),
                for (final c in adminCategories) DropdownMenuItem<String?>(value: c, child: Text(c)),
              ],
              onChanged: (v) => update(keep(categorie: v, clearCategorie: v == null)),
            ),
            FilterDropdown<String>(
              label: 'Genre',
              width: 160,
              value: filter.genre,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Tous')),
                for (final g in adminGenres) DropdownMenuItem<String?>(value: g, child: Text(g)),
              ],
              onChanged: (v) => update(keep(genre: v, clearGenre: v == null)),
            ),
            SizedBox(
              width: 260,
              child: DebouncedSearchField(
                initialValue: filter.search,
                onChanged: (v) => update(keep(search: v)),
              ),
            ),
            if (filter.hasFilters)
              TextButton.icon(
                onPressed: () => update(const AdminCompetitionsFilter()),
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Réinitialiser'),
              ),
          ],
        ),
        async: async,
        onPage: (p) => update(filter.copyWith(page: p)),
        onRetry: () => ref.invalidate(adminCompetitionsProvider),
        emptyIcon: Icons.emoji_events_outlined,
        emptyTitle: 'Aucune compétition trouvée',
        emptyMessage: filter.hasFilters ? 'Modifiez ou réinitialisez les filtres.' : null,
        wideBody: (context, rows) => ListView.separated(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, i) => _CompetitionCard(competition: rows[i], wide: true),
        ),
        narrowBody: (context, rows) => [
          for (final c in rows)
            Padding(padding: const EdgeInsets.only(bottom: 16), child: _CompetitionCard(competition: c, wide: false)),
        ],
      ),
    );
  }
}

String _formatDate(String? raw) {
  final d = raw == null || raw.length < 10 ? null : DateTime.tryParse(raw.substring(0, 10));
  return d == null ? '—' : DateFormat('d MMMM y', 'fr_FR').format(d);
}

String _formatTime(String? raw) => raw == null || raw.length < 5 ? '—' : raw.substring(0, 5);

class _CompetitionCard extends StatelessWidget {
  final AdminCompetitionRow competition;
  final bool wide;
  const _CompetitionCard({required this.competition, required this.wide});

  @override
  Widget build(BuildContext context) {
    final c = competition;
    final status = AdminStatus.optionFor(AdminEntity.competitions, c.statut);
    final text = Theme.of(context).textTheme;

    final cover = AppCover(
      imageUrl: c.photo,
      height: wide ? 320 : 190,
      borderRadius: wide
          ? const BorderRadius.horizontal(left: Radius.circular(20))
          : const BorderRadius.vertical(top: Radius.circular(20)),
      overlay: Text(c.nom, style: text.titleLarge?.copyWith(color: Colors.white)),
    );

    final info = Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusBadge(label: status.label, color: status.color, icon: status.icon),
              if (c.categorie != null) StatusBadge(label: 'Catégorie : ${c.categorie}', color: AppColors.primary),
              if (c.genre != null)
                StatusBadge(label: c.genre!, color: c.genre == 'Masculin' ? AppColors.info : AppColors.error),
              if (c.saison != null) StatusBadge(label: c.saison!, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text('Description', style: text.titleMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(
            (c.description == null || c.description!.isEmpty) ? 'Aucune description.' : c.description!,
            style: text.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text('Venez soutenir votre équipe préférée et profitez du spectacle.', style: text.bodySmall),
          const SizedBox(height: 14),
          Text('Déroulement', style: text.titleMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          InfoRow(icon: Icons.calendar_today_outlined, label: 'Date de début', value: _formatDate(c.dateDebut)),
          InfoRow(icon: Icons.schedule_outlined, label: 'Heure de début', value: _formatTime(c.heureDebut)),
          InfoRow(icon: Icons.place_outlined, label: 'Lieu', value: c.nomTerrain),
          const SizedBox(height: 6),
          Text('Progression de la compétition', style: text.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (c.progression / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceVariant,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${c.progression.round()}%', style: text.labelLarge?.copyWith(color: AppColors.success)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${c.matchesFinishedCount} match(s) terminé(s) sur ${c.matchesCount}', style: text.bodySmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(onPressed: () => context.push('/competitions/${c.id}'), child: const Text('Voir les détails')),
              FilledButton(onPressed: () => context.push('/admin/manage/competitions/${c.id}'), child: const Text('Gérer')),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [SizedBox(width: 340, child: cover), Expanded(child: info)],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [cover, info]),
    );
  }
}
