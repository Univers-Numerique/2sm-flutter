import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../follow/data/follow_repository.dart';
import '../../../matches/presentation/screens/matches_list_screen.dart';
import '../../../follow/presentation/follow_button.dart';
import '../../../players/presentation/widgets/people_widgets.dart';
import '../../application/teams_providers.dart';
import '../../data/models/team.dart';
import '../../data/teams_repository.dart';
import '../widgets/team_dashboard_tab.dart';
import '../widgets/team_members_tabs.dart';
import '../widgets/team_performances_tab.dart';
import 'create_team_screen.dart';

/// Tabs of the team hub, in display order.
enum TeamTab { dashboard, members, add, performances, competitions }

/// One screen for everyone: the PHP app split this into a read-only member
/// view (`compte/infos-equipe.php`, `compte/mon-equipe.php`) and a separate
/// manager console (`manage/equipes/*`) — here the same screen reveals the
/// management tabs and actions when the signed-in user owns the team.
class TeamDetailScreen extends ConsumerWidget {
  final int teamId;
  final TeamTab initialTab;
  const TeamDetailScreen({super.key, required this.teamId, this.initialTab = TeamTab.dashboard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user : null;

    return teamAsync.when(
      loading: () => Scaffold(appBar: AppBar(title: const Text('Équipe')), body: const SkeletonList(count: 3, itemHeight: 150)),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Équipe')),
        body: ErrorState(error: e, onRetry: () => ref.invalidate(teamDetailProvider(teamId))),
      ),
      data: (team) {
        final isManager = me != null && team.isManagedBy(me.id);
        final isMember = isManager || (me != null && (team.hasMember(me.id) || me.isAdmin));
        final tabs = <TeamTab>[
          TeamTab.dashboard,
          TeamTab.members,
          if (isManager) TeamTab.add,
          if (isMember) TeamTab.performances,
          TeamTab.competitions,
        ];
        final initial = tabs.contains(initialTab) ? tabs.indexOf(initialTab) : 0;
        return DefaultTabController(
          key: ValueKey('${team.id}-${tabs.length}'),
          length: tabs.length,
          initialIndex: initial,
          child: Scaffold(
            appBar: AppBar(
              title: Text(team.nom),
              actions: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.apps),
                    tooltip: "Menu de l'équipe",
                    onPressed: () {
                      final controller = DefaultTabController.of(ctx);
                      _showMenu(ctx, ref, team, isManager, (t) {
                        final i = tabs.indexOf(t);
                        if (i >= 0) controller.animateTo(i);
                      });
                    },
                  ),
                ),
              ],
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: _TeamHeader(team: team, isManager: isManager, canFollow: me != null && !isManager)),
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [for (final t in tabs) Tab(text: _label(t))],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  for (final t in tabs)
                    switch (t) {
                      TeamTab.dashboard => TeamDashboardTab(team: team),
                      TeamTab.members => TeamMembersTab(team: team, isManager: isManager),
                      TeamTab.add => TeamAddMemberTab(team: team),
                      TeamTab.performances => TeamPerformancesTab(teamId: team.id, isManager: isManager),
                      TeamTab.competitions => _CompetitionsTab(team: team),
                    },
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _label(TeamTab t) => switch (t) {
        TeamTab.dashboard => 'Tableau de bord',
        TeamTab.members => 'Gestion des membres',
        TeamTab.add => 'Ajouter un membre',
        TeamTab.performances => 'Performances',
        TeamTab.competitions => 'Compétitions',
      };

  void _showMenu(BuildContext context, WidgetRef ref, Team team, bool isManager, void Function(TeamTab) goTo) {
    Widget item(IconData icon, String label, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
            ]),
          ),
        );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Menu de l'équipe", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                item(Icons.dashboard_outlined, 'Tableau de bord', () => goTo(TeamTab.dashboard)),
                item(Icons.event_note_outlined, 'Nos activités', () => context.push('/activities')),
                item(Icons.sports_soccer, 'Nos matchs', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MatchesListScreen()))),
                item(Icons.calendar_month_outlined, 'Notre calendrier', () => context.push('/calendar')),
                item(Icons.groups_2_outlined, 'Gestion des membres', () => goTo(TeamTab.members)),
                item(Icons.emoji_events_outlined, 'Nos compétitions', () => goTo(TeamTab.competitions)),
                if (isManager) item(Icons.person_add_alt_1_outlined, 'Ajouter un membre', () => goTo(TeamTab.add)),
                if (isManager) item(Icons.person_add_outlined, 'Créer un membre', () => showCreateMemberDialog(context, ref, team)),
                item(Icons.list_alt_outlined, 'Liste des équipes', () => context.push('/teams')),
                item(Icons.workspace_premium_outlined, 'Abonnements', () => context.push('/plans')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(color: Theme.of(context).scaffoldBackgroundColor, elevation: overlapsContent ? 1 : 0, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _TeamHeader extends ConsumerWidget {
  final Team team;
  final bool isManager;
  final bool canFollow;
  const _TeamHeader({required this.team, required this.isManager, required this.canFollow});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final owner = team.owner;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.secondary.withAlpha(50), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppAvatar(name: team.nom, imageUrl: team.logo, size: 84, rounded: true, border: Border.all(color: Colors.white24, width: 3)),
                  if (isManager) Positioned(right: -6, bottom: -6, child: _LogoUploadButton(teamId: team.id)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.nom, style: t.headlineSmall?.copyWith(color: Colors.white)),
                    if (team.lieu != null)
                      Row(children: [
                        const Icon(Icons.place_outlined, size: 15, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(child: Text(team.lieu!, style: t.bodyMedium?.copyWith(color: Colors.white70))),
                      ]),
                    if (owner != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Responsable : ${owner.fullName}', style: t.bodySmall?.copyWith(color: Colors.white60)),
                      ),
                  ],
                ),
              ),
              if (isManager)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  tooltip: 'Mise à jour des informations',
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateTeamScreen(team: team))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 6, children: [
            StatusBadge(label: '${team.members.isNotEmpty ? team.members.length : (team.membersCount ?? 0)} membres', color: Colors.white, icon: Icons.groups_2_outlined),
            if (team.statistics != null) StatusBadge(label: '${team.statistics!.points} pts', color: Colors.white, icon: Icons.emoji_events_outlined),
            StatusBadge(label: '${team.competitions.length} compétition${team.competitions.length > 1 ? 's' : ''}', color: Colors.white, icon: Icons.military_tech_outlined),
          ]),
          if (canFollow) ...[
            const SizedBox(height: 14),
            FollowButton(table: FollowTable.team, entityId: team.id, followLabel: 'Suivre cette équipe', unfollowLabel: 'Ne plus suivre cette équipe', onDark: true),
            const SizedBox(height: 6),
            Text("Suivre cette équipe vous permet d'être informé(e) de toutes les activités et événements en son sein.", style: t.bodySmall?.copyWith(color: Colors.white60)),
          ],
        ],
      ),
    );
  }
}

class _CompetitionsTab extends StatelessWidget {
  final Team team;
  const _CompetitionsTab({required this.team});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return PageBody(
      children: [
        if (team.competitions.isEmpty)
          const EmptyState(icon: Icons.emoji_events_outlined, title: 'Aucune compétition', message: "Cette équipe n'est inscrite à aucune compétition.")
        else
          CardGrid(children: [
            for (final c in team.competitions)
              SurfaceCard(
                onTap: () => context.push('/competitions/${c.id}'),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCover(imageUrl: c.photo, height: 110, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.nom, style: t.titleMedium),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, children: [
                          if (c.saison != null) StatusBadge(label: c.saison!, color: AppColors.info),
                          if (c.categorie != null) StatusBadge(label: c.categorie!, color: AppColors.secondaryLight),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
          ]),
      ],
    );
  }
}

/// Small camera-icon button overlaid on the team logo, visible to managers
/// only. Picks an image from the gallery and uploads it via
/// TeamsRepository.uploadLogo.
class _LogoUploadButton extends ConsumerStatefulWidget {
  final int teamId;
  const _LogoUploadButton({required this.teamId});

  @override
  ConsumerState<_LogoUploadButton> createState() => _LogoUploadButtonState();
}

class _LogoUploadButtonState extends ConsumerState<_LogoUploadButton> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(teamsRepositoryProvider).uploadLogo(widget.teamId, File(picked.path));
      ref.invalidate(teamDetailProvider(widget.teamId));
      ref.invalidate(teamsListProvider);
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _uploading ? null : _pickAndUpload,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: _uploading
              ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
