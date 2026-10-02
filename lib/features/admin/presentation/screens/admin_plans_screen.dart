import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../application/admin_providers.dart';
import '../../data/models/plan.dart';
import '../../data/plans_repository.dart';
import '../widgets/admin_widgets.dart';

String formatPlanPrice(double prix) => '${NumberFormat.decimalPattern('fr_FR').format(prix.round())} F CFA';

/// Subscription plans: list (image, nom, prix, description, statut) with
/// create / edit / activate / delete — the list side of legacy
/// `admin/plan.php` (the form is [AdminPlanFormScreen]).
class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansListProvider);
    final wide = isAdminWide(context);

    return AdminScaffold(
      title: 'Administration',
      section: AdminSection.plans,
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(plansListProvider.future),
        child: ListView(
          padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Plans d'abonnement", style: Theme.of(context).textTheme.headlineSmall),
                      Text('Offres proposées aux équipes.', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push('/admin/plans/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un plan'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            plansAsync.when(
              loading: () => Column(children: [for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBox(height: 120, radius: 20))]),
              error: (e, _) => SizedBox(height: 300, child: ErrorState(error: e, onRetry: () => ref.invalidate(plansListProvider))),
              data: (plans) {
                if (plans.isEmpty) {
                  return const SizedBox(
                    height: 320,
                    child: EmptyState(
                      icon: Icons.card_membership_outlined,
                      title: 'Aucun plan pour le moment',
                      message: "Créez votre premier plan d'abonnement.",
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = (constraints.maxWidth / 380).floor().clamp(1, 4);
                    const gap = 16.0;
                    final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [for (final p in plans) SizedBox(width: width, child: _PlanCard(plan: p))],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final Plan plan;
  const _PlanCard({required this.plan});

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(plansRepositoryProvider).update(plan.id, statut: plan.statut == 1 ? 0 : 1);
      ref.invalidate(plansListProvider);
    } on Failure catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce plan ?'),
        content: Text('« ${plan.nom} » sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(plansRepositoryProvider).delete(plan.id);
      ref.invalidate(plansListProvider);
    } on Failure catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final active = plan.statut == 1;
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
                imageUrl: plan.image,
                height: 140,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: StatusBadge(
                  label: active ? 'Actif' : 'Inactif',
                  color: active ? AppColors.success : AppColors.warning,
                  solid: true,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.nom, style: text.titleLarge),
                const SizedBox(height: 2),
                Text(formatPlanPrice(plan.prix), style: text.titleMedium?.copyWith(color: AppColors.primary)),
                const SizedBox(height: 8),
                Text(
                  (plan.description == null || plan.description!.isEmpty) ? 'Aucune description.' : plan.description!,
                  style: text.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => context.push('/admin/plans/${plan.id}/edit', extra: plan),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Modifier'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => _toggle(context, ref),
                      icon: Icon(active ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 18),
                      label: Text(active ? 'Désactiver' : 'Activer'),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => _delete(context, ref),
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    ),
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
