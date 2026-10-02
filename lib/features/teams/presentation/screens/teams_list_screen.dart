import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../players/presentation/widgets/people_widgets.dart';
import '../../application/teams_providers.dart';
import '../../data/models/team.dart';

/// Teams directory — port of `compte/equipes.php` / `manage/equipes/index.php`:
/// name search, team (logo, name, address) + responsable (avatar, name,
/// email) + "Voir", and "Créer mon équipe" / "Voir mon équipe".
class TeamsListScreen extends ConsumerStatefulWidget {
  const TeamsListScreen({super.key});

  @override
  ConsumerState<TeamsListScreen> createState() => _TeamsListScreenState();
}

class _TeamsListScreenState extends ConsumerState<TeamsListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamsListProvider);
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user : null;
    // Legacy rule: `$_SESSION["statut"] > 2` may create a team.
    final canCreate = me != null && (me.statut > 2 || me.isAdmin);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Équipes'),
        actions: [
          if (canCreate)
            IconButton(icon: const Icon(Icons.add), tooltip: 'Créer une équipe', onPressed: () => context.push('/teams/create')),
        ],
      ),
      body: PageBody(
        onRefresh: () async => ref.invalidate(teamsListProvider),
        children: [
          teamsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (teams) {
              final mine = me == null ? null : teams.where((t) => t.ownerId == me.id).firstOrNull;
              return HeroHeader(
                title: 'Toutes les équipes',
                subtitle: '${teams.length} équipe${teams.length > 1 ? 's' : ''} sur la plateforme',
                leading: const Icon(Icons.groups_2_outlined, color: Colors.white, size: 36),
                bottom: (canCreate || mine != null)
                    ? Wrap(spacing: 10, runSpacing: 8, children: [
                        if (mine != null)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.secondary),
                            onPressed: () => context.push('/teams/${mine.id}'),
                            icon: const Icon(Icons.shield_outlined, size: 18),
                            label: const Text('Voir mon équipe'),
                          ),
                        if (canCreate && mine == null)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.secondary),
                            onPressed: () => context.push('/teams/create'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Créer mon équipe'),
                          ),
                        if (canCreate && mine != null)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
                            onPressed: () => context.push('/teams/create'),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Créer une autre équipe'),
                          ),
                      ])
                    : null,
              );
            },
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: TextField(
              decoration: const InputDecoration(hintText: 'Rechercher ici', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 12),
          teamsAsync.when(
            loading: () => Column(children: [for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBox(height: 120, radius: 20))]),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(teamsListProvider)),
            data: (teams) {
              final list = teams.where((t) {
                if (_search.isEmpty) return true;
                return t.nom.toLowerCase().contains(_search) || (t.lieu ?? '').toLowerCase().contains(_search);
              }).toList();
              if (list.isEmpty) {
                return const EmptyState(icon: Icons.groups_outlined, title: 'Aucune équipe', message: "Aucune équipe ne correspond à votre recherche.");
              }
              return CardGrid(children: [for (final t in list) _TeamCard(team: t, mine: me != null && t.ownerId == me.id)]);
            },
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final bool mine;
  const _TeamCard({required this.team, required this.mine});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final owner = team.owner;
    return SurfaceCard(
      onTap: () => context.push('/teams/${team.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AppAvatar(name: team.nom, imageUrl: team.logo, size: 60, rounded: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(team.nom, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (team.lieu != null)
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Expanded(child: Text(team.lieu!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
              ]),
            ),
            if (mine) const StatusBadge(label: 'Mon équipe', solid: true),
          ]),
          if (owner != null) ...[
            const Divider(height: 24),
            Row(children: [
              AppAvatar(name: owner.fullName, imageUrl: owner.avatar, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(owner.fullName, style: t.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (owner.email != null) Text(owner.email!, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          Row(children: [
            StatusBadge(label: '${team.membersCount ?? team.members.length} membres', icon: Icons.groups_2_outlined, color: AppColors.info),
            const Spacer(),
            FilledButton(onPressed: () => context.push('/teams/${team.id}'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18)), child: const Text('Voir')),
          ]),
        ],
      ),
    );
  }
}
