import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/teams_providers.dart';
import 'team_detail_screen.dart';

/// "Mon équipe" entry point (legacy `compte/mon-equipe.php` /
/// `manage/equipes/`): opens the team the signed-in user manages, at the
/// requested [tab], or invites them to create one.
class MyTeamScreen extends ConsumerWidget {
  final TeamTab tab;
  const MyTeamScreen({super.key, this.tab = TeamTab.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsListProvider);
    final auth = ref.watch(authNotifierProvider);
    final meId = auth is AuthAuthenticated ? auth.user.id : null;

    return teamsAsync.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Mon équipe')), body: const SkeletonList(count: 3, itemHeight: 140)),
      error: (e, _) => Scaffold(appBar: AppBar(title: const Text('Mon équipe')), body: ErrorState(error: e, onRetry: () => ref.invalidate(teamsListProvider))),
      data: (teams) {
        final mine = meId == null ? null : teams.where((t) => t.ownerId == meId).firstOrNull;
        if (mine != null) return TeamDetailScreen(teamId: mine.id, initialTab: tab);
        return Scaffold(
          appBar: AppBar(title: const Text('Mon équipe')),
          body: EmptyState(
            icon: Icons.shield_outlined,
            title: "Vous n'avez pas encore d'équipe",
            message: 'Créez votre équipe pour gérer vos membres, activités et compétitions.',
            action: FilledButton.icon(onPressed: () => context.push('/teams/create'), icon: const Icon(Icons.add), label: const Text('Créer mon équipe')),
          ),
        );
      },
    );
  }
}
