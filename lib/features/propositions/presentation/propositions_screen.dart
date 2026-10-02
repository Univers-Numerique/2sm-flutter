import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_theme.dart';
import '../../../core/network/failure.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_ui.dart';
import '../../auth/application/auth_provider.dart';
import '../../matches/presentation/widgets/match_widgets.dart';
import '../data/propositions_repository.dart';

/// Propositions de matchs amicaux reçues / envoyées (`GET /propositions`),
/// avec accepter / refuser pour le proposé (`PUT /propositions/{id}`).
class PropositionsScreen extends ConsumerStatefulWidget {
  const PropositionsScreen({super.key});

  @override
  ConsumerState<PropositionsScreen> createState() => _PropositionsScreenState();
}

class _PropositionsScreenState extends ConsumerState<PropositionsScreen> {
  int? _busyId;
  int _filter = -1; // -1 toutes, 0 en attente, 1 acceptées, 2 refusées

  Future<void> _answer(Proposition p, bool accept) async {
    setState(() => _busyId = p.id);
    try {
      await ref.read(propositionsRepositoryProvider).answer(p.id, accept: accept);
      ref.invalidate(propositionsProvider);
      if (mounted) showSnack(context, accept ? 'Proposition acceptée.' : 'Proposition refusée.');
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final uid = auth is AuthAuthenticated ? auth.user.id : -1;
    final props = ref.watch(propositionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Propositions de matchs')),
      body: props.when(
        loading: () => const SkeletonList(count: 4, itemHeight: 150),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(propositionsProvider)),
        data: (all) {
          final list = _filter < 0 ? all : all.where((p) => p.statut == _filter).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(propositionsProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                const SizedBox(height: 8),
                FilterChips<int>(
                  selected: _filter,
                  onChanged: (v) => setState(() => _filter = v ?? -1),
                  options: const [
                    (value: -1, label: 'Toutes'),
                    (value: 0, label: 'En attente'),
                    (value: 1, label: 'Acceptées'),
                    (value: 2, label: 'Refusées'),
                  ],
                ),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(
                      icon: Icons.handshake_outlined,
                      title: 'Aucune proposition',
                      message: "Les propositions de matchs amicaux envoyées ou reçues s'affichent ici.",
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ResponsiveColumns(children: [
                      for (final p in list) _PropositionCard(p: p, mine: p.proposed.id == uid, busy: _busyId == p.id, onAnswer: _answer),
                    ]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PropositionCard extends StatelessWidget {
  final Proposition p;
  final bool mine;
  final bool busy;
  final Future<void> Function(Proposition p, bool accept) onAnswer;
  const _PropositionCard({required this.p, required this.mine, required this.busy, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final m = p.match;
    final statusColor = p.statut == 1 ? AppColors.success : (p.statut == 2 ? AppColors.error : AppColors.warning);
    final statusLabel = p.statut == 1 ? 'Acceptée' : (p.statut == 2 ? 'Refusée' : 'En attente');
    final other = mine ? p.proposer : p.proposed;

    return SurfaceCard(
      onTap: m == null ? null : () => context.push('/matches/${m.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(label: mine ? 'Reçue' : 'Envoyée', color: AppColors.info, icon: mine ? Icons.call_received : Icons.call_made),
              const Spacer(),
              StatusBadge(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          if (m != null)
            Row(
              children: [
                Expanded(child: _Side(name: m.homeTeam?.nom ?? '', logo: m.homeTeam?.logo)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('VS', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textTertiary)),
                ),
                Expanded(child: _Side(name: m.awayTeam?.nom ?? '', logo: m.awayTeam?.logo)),
              ],
            )
          else
            Text('Match #${p.entityId}', style: text.titleMedium),
          if (m != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.event_outlined, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(formatDateTimeFr(m.dateDebut, m.heureDebut), style: text.bodyMedium),
            ]),
            if (m.field?.nomTerrain != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  const Icon(Icons.stadium_outlined, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text(m.field!.nomTerrain!, style: text.bodyMedium),
                ]),
              ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              AppAvatar(name: other.name, imageUrl: other.avatar, size: 28),
              const SizedBox(width: 8),
              Expanded(child: Text(mine ? 'Proposé par ${other.name}' : 'Proposé à ${other.name}', style: text.bodySmall, overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (mine && p.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: busy ? null : () => onAnswer(p, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : () => onAnswer(p, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Side extends StatelessWidget {
  final String name;
  final String? logo;
  const _Side({required this.name, this.logo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(name: name, imageUrl: logo, size: 46, rounded: true),
        const SizedBox(height: 4),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
