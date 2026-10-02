import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../matches/presentation/widgets/match_widgets.dart';
import '../../application/fields_providers.dart';
import '../../data/fields_repository.dart';
import '../../data/models/field.dart';

final _defaultFieldProvider = FutureProvider.autoDispose<Field?>((ref) {
  return ref.watch(fieldsRepositoryProvider).defaultField();
});

/// Terrains / stades (compte/terrains.php, manage/terrains) : recherche, tri
/// croissant/décroissant, terrains à proximité (`/fields/nearby`), terrain par
/// défaut (`/fields/default`), lien "Localiser le terrain".
class FieldsListScreen extends ConsumerStatefulWidget {
  const FieldsListScreen({super.key});

  @override
  ConsumerState<FieldsListScreen> createState() => _FieldsListScreenState();
}

class _FieldsListScreenState extends ConsumerState<FieldsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _asc = true;
  List<Field>? _nearby;
  String? _nearbyLabel;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _askNearby() async {
    final lat = TextEditingController(text: '5.3364');
    final lng = TextEditingController(text: '-4.0267');
    final radius = TextEditingController(text: '25');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terrains à proximité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Latitude')),
            const SizedBox(height: 10),
            TextField(controller: lng, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Longitude')),
            const SizedBox(height: 10),
            TextField(controller: radius, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rayon (km)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Rechercher')),
        ],
      ),
    );
    if (ok != true) return;
    final la = double.tryParse(lat.text.replaceAll(',', '.'));
    final lo = double.tryParse(lng.text.replaceAll(',', '.'));
    final r = double.tryParse(radius.text.replaceAll(',', '.')) ?? 10;
    if (la == null || lo == null) {
      if (mounted) showSnack(context, 'Coordonnées invalides.', error: true);
      return;
    }
    try {
      final list = await ref.read(fieldsRepositoryProvider).nearby(lat: la, lng: lo, radiusKm: r);
      if (mounted) {
        setState(() {
          _nearby = list;
          _nearbyLabel = 'À moins de ${r.toStringAsFixed(0)} km';
        });
      }
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    } catch (_) {
      if (mounted) showSnack(context, 'Recherche impossible hors connexion.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsListProvider);
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final canCreate = user != null && (user.isAdmin || user.statut >= 3);
    final defaultField = ref.watch(_defaultFieldProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terrains'),
        actions: [
          IconButton(tooltip: 'Terrains à proximité', icon: const Icon(Icons.near_me_outlined), onPressed: _askNearby),
          IconButton(
            tooltip: _asc ? 'Tri croissant' : 'Tri décroissant',
            icon: Icon(_asc ? Icons.sort_by_alpha : Icons.arrow_downward),
            onPressed: () => setState(() => _asc = !_asc),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/fields/create'),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un stade'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(fieldsListProvider);
          setState(() => _nearby = null);
        },
        child: fieldsAsync.when(
          loading: () => const SkeletonList(count: 5, itemHeight: 110),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(fieldsListProvider)),
          data: (all) {
            final query = _query.trim().toLowerCase();
            var source = _nearby ?? all;
            var filtered = query.isEmpty
                ? [...source]
                : source.where((f) => f.nomTerrain.toLowerCase().contains(query) || (f.lieu?.toLowerCase().contains(query) ?? false)).toList();
            if (_nearby == null) {
              filtered.sort((a, b) => _asc ? a.nomTerrain.compareTo(b.nomTerrain) : b.nomTerrain.compareTo(a.nomTerrain));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher ici',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                if (_nearby != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(children: [
                      StatusBadge(label: _nearbyLabel ?? 'À proximité', color: AppColors.info, icon: Icons.near_me_outlined),
                      const Spacer(),
                      TextButton(onPressed: () => setState(() => _nearby = null), child: const Text('Tous les terrains')),
                    ]),
                  ),
                if (defaultField != null && _nearby == null && query.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SurfaceCard(
                      child: Row(children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Terrain par défaut : ${defaultField.nomTerrain}', style: Theme.of(context).textTheme.titleSmall)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(icon: Icons.stadium_outlined, title: 'Aucun terrain', message: 'Aucun terrain ne correspond à cette recherche.'),
                  )
                else
                  ResponsiveColumns(
                    maxColumns: 2,
                    children: [
                      for (final f in filtered)
                        _FieldCard(
                          field: f,
                          isDefault: defaultField?.id == f.id,
                          canEdit: user != null && (user.isAdmin || f.isOwnedBy(user.id)),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final Field field;
  final bool isDefault;
  final bool canEdit;
  const _FieldCard({required this.field, required this.isDefault, required this.canEdit});

  Future<void> _openInMaps(BuildContext context) async {
    final ok = await launchUrl(Uri.parse(field.mapsUrl), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, "Impossible d'ouvrir Maps.", error: true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCover(
            imageUrl: field.photo,
            height: 140,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            overlay: Row(
              children: [
                Expanded(child: Text(field.nomTerrain, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleLarge?.copyWith(color: Colors.white))),
                if (isDefault) const StatusBadge(label: 'Par défaut', color: AppColors.warning, icon: Icons.star_rounded, solid: true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (field.lieu != null)
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(child: Text(field.lieu!, style: text.bodyMedium)),
                  ]),
                if (field.distanceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: StatusBadge(label: '${field.distanceKm!.toStringAsFixed(1)} km', color: AppColors.info, icon: Icons.near_me_outlined),
                  ),
                if (field.owner != null && field.owner!.fullName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      AppAvatar(name: field.owner!.fullName, size: 20),
                      const SizedBox(width: 6),
                      Text('Ajouté par ${field.owner!.fullName}', style: text.bodySmall),
                    ]),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openInMaps(context),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text('Localiser le terrain'),
                    ),
                    const Spacer(),
                    if (canEdit) IconButton(tooltip: 'Modifier', icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/fields/create', extra: field)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
