import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/players_providers.dart';
import '../../data/football_constants.dart';
import '../../data/models/player.dart';
import '../widgets/people_widgets.dart';

/// Career — port of `compte/parcours.php`: the teams a user played for
/// (`GET /users/{id}/positions`) and their game events
/// (`recent_events` of `GET /users/{id}/statistics`).
/// [userId] null = the signed-in user.
class CareerScreen extends ConsumerWidget {
  final int? userId;
  const CareerScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final id = userId ?? (auth is AuthAuthenticated ? auth.user.id : 0);
    final userAsync = ref.watch(userDetailProvider(id));
    final positionsAsync = ref.watch(userPositionsProvider(id));
    final statsAsync = ref.watch(userStatsProvider(id));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Parcours')),
      body: PageBody(
        onRefresh: () async {
          ref.invalidate(userPositionsProvider(id));
          ref.invalidate(userStatsProvider(id));
        },
        children: [
          userAsync.when(
            loading: () => const SkeletonBox(height: 110, radius: 24),
            error: (e, _) => ErrorState(error: e),
            data: (u) => HeroHeader(
              title: u.fullName,
              subtitle: u.mainPosition?.poste ?? 'Parcours sportif',
              leading: AppAvatar(name: u.fullName, imageUrl: u.avatar, size: 64, border: Border.all(color: Colors.white24, width: 2)),
              actions: [
                if (userId != null)
                  IconButton(
                    onPressed: () => context.push('/users/$id'),
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    tooltip: 'Voir le profil',
                  ),
              ],
            ),
          ),
          LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 860;
            final teams = SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Équipes', style: t.titleLarge),
                  const SizedBox(height: 8),
                  positionsAsync.when(
                    loading: () => const SkeletonBox(height: 120, radius: 16),
                    error: (e, _) => Text('$e'),
                    data: (list) {
                      if (list.isEmpty) return Text("Aucune équipe pour l'instant.", style: t.bodyMedium);
                      return Column(children: [for (final p in list) _TeamStep(position: p)]);
                    },
                  ),
                ],
              ),
            );
            final events = SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Faits de jeu', style: t.titleLarge),
                  const SizedBox(height: 8),
                  statsAsync.when(
                    loading: () => const SkeletonBox(height: 120, radius: 16),
                    error: (e, _) => Text('$e'),
                    data: (s) {
                      final list = s.recentEvents.where((e) => e.statut == 1).toList();
                      if (list.isEmpty) return Text('Aucun fait de jeu enregistré.', style: t.bodyMedium);
                      return Column(children: [for (final e in list) _EventStep(event: e)]);
                    },
                  ),
                ],
              ),
            );
            if (!wide) {
              return Column(children: [const SizedBox(height: 16), teams, const SizedBox(height: 16), events]);
            }
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: teams), const SizedBox(width: 16), Expanded(child: events)],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TeamStep extends StatelessWidget {
  final PlayerPosition position;
  const _TeamStep({required this.position});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: position.teamId == null ? null : () => context.push('/teams/${position.teamId}'),
      leading: AppAvatar(name: position.teamName ?? 'Équipe', imageUrl: position.teamLogo, size: 46, rounded: true),
      title: Text(position.teamName ?? 'Équipe', style: t.titleSmall),
      subtitle: Text([
        if (position.poste != null) position.poste!,
        if (position.categorie != null) position.categorie!,
        if (position.createdAt != null) 'depuis le ${formatDateFr(position.createdAt)}',
      ].join(' · ')),
      trailing: position.statut == 1 ? null : const StatusBadge(label: 'Inactif', color: AppColors.textTertiary),
    );
  }
}

class _EventStep extends StatelessWidget {
  final GameEventItem event;
  const _EventStep({required this.event});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final color = gameEventColor(event.jeu);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(14)),
        child: Icon(gameEventIcon(event.jeu), color: color),
      ),
      title: Text(event.jeu, style: t.titleSmall),
      subtitle: Text([
        if (event.teamName != null) event.teamName!,
        if (event.temps != null) "${event.temps}'",
        if (event.createdAt != null) formatDateFr(event.createdAt),
      ].join(' · ')),
      trailing: event.matchId == null
          ? null
          : TextButton(onPressed: () => context.push('/matches/${event.matchId}'), child: const Text('Voir le match')),
    );
  }
}
