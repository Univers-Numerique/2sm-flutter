import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../follow/presentation/follow_button.dart';
import '../../../follow/data/follow_repository.dart';
import '../../../media/presentation/media_gallery.dart';
import '../../../teams/application/teams_providers.dart';
import '../../data/match_extras_repository.dart';
import '../../data/matches_repository.dart';
import '../../data/models/match_game.dart';
import '../../data/models/match_overview.dart';
import '../widgets/match_widgets.dart';

/// Icône + couleur d'un évènement de jeu (table `$playerStats` du legacy).
({IconData icon, Color color}) eventStyle(String jeu) {
  switch (jeu) {
    case 'Buts Marqués':
      return (icon: Icons.sports_soccer, color: AppColors.success);
    case 'Passes Décisives':
    case 'Passes Réussies':
    case 'Passes Longues Réussies':
    case 'Passes Courtes Réussies':
      return (icon: Icons.swap_calls, color: AppColors.success);
    case 'Coups Francs':
      return (icon: Icons.flag_outlined, color: AppColors.info);
    case 'Tirs au But':
      return (icon: Icons.gps_fixed, color: AppColors.secondary);
    case 'Tirs Cadrés':
      return (icon: Icons.gps_fixed, color: AppColors.success);
    case 'Tirs non Cadrés':
      return (icon: Icons.block, color: AppColors.error);
    case 'Corners':
      return (icon: Icons.outlined_flag, color: AppColors.secondaryLight);
    case 'Fautes Comises':
      return (icon: Icons.warning_amber_rounded, color: AppColors.error);
    case 'Cartons Jaunes':
      return (icon: Icons.style, color: AppColors.warning);
    case 'Cartons Rouges':
      return (icon: Icons.style, color: AppColors.error);
    case 'Debut de match':
    case 'Début de match':
    case 'Reprise de match':
      return (icon: Icons.play_circle_outline, color: AppColors.primary);
    case 'Pause':
      return (icon: Icons.pause_circle_outline, color: AppColors.warning);
    case 'Fin de match':
      return (icon: Icons.stop_circle_outlined, color: AppColors.error);
    default:
      return (icon: Icons.bolt, color: AppColors.textSecondary);
  }
}

/// Fiche d'un match (compte/details-match.php) : score, cinq onglets
/// (Statistiques, Évènements, Classements, Commentaires du jeu, Sélections),
/// suivre le match, médiatiser, annoncer, modifier.
class MatchDetailScreen extends ConsumerStatefulWidget {
  final int matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  int _tab = 0;
  static const _tabs = ['Statistiques', 'Évènements', 'Classements', 'Commentaires du jeu', 'Sélections'];

  Future<void> _setEvent(GameEvent e, bool valid) async {
    try {
      await ref.read(matchesRepositoryProvider).setEventStatus(widget.matchId, e.id, valid: valid);
      ref.invalidate(matchOverviewProvider(widget.matchId));
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(matchOverviewProvider(widget.matchId));
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Détails du match')),
      body: overview.when(
        loading: () => const SkeletonList(count: 3, itemHeight: 190),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(matchOverviewProvider(widget.matchId))),
        data: (o) {
          final m = o.match;
          final uid = user?.id ?? -1;
          final isAdmin = user?.isAdmin ?? false;
          final operator = m.canOperate(uid) || isAdmin;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchOverviewProvider(widget.matchId)),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ScoreHero(o: o),
                          const SizedBox(height: 14),
                          _ActionBar(o: o, user: user, operator: operator),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _tabs.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (_, i) => ChoiceChip(
                                label: Text(_tabs[i]),
                                selected: _tab == i,
                                showCheckmark: false,
                                selectedColor: AppColors.secondary,
                                backgroundColor: AppColors.card,
                                side: BorderSide(color: _tab == i ? AppColors.secondary : AppColors.border),
                                labelStyle: TextStyle(
                                    color: _tab == i ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w700),
                                onSelected: (_) => setState(() => _tab = i),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          switch (_tab) {
                            0 => _StatsTab(o: o),
                            1 => _EventsTab(o: o, canModerate: m.canModerateEvents(uid) || isAdmin, onToggle: _setEvent),
                            2 => _RankingTab(o: o),
                            3 => MatchMediaGallery(matchId: m.id, initial: o.medias, canPost: user != null, onChanged: () => ref.invalidate(matchOverviewProvider(m.id))),
                            _ => _SelectionsTab(o: o, userId: uid, onChanged: () => ref.invalidate(matchOverviewProvider(m.id))),
                          },
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  final MatchOverview o;
  const _ScoreHero({required this.o});

  @override
  Widget build(BuildContext context) {
    final m = o.match;
    final text = Theme.of(context).textTheme;
    final started = m.statut != MatchStatus.scheduled;
    final scoreStyle = AppTextStyles.score.copyWith(color: Colors.white, fontSize: 48);

    Widget team(MatchTeamRef? t, String fallback) => Expanded(
          child: Column(
            children: [
              GestureDetector(
                onTap: t == null ? null : () => context.push('/teams/${t.id}'),
                child: AppAvatar(name: t?.nom ?? fallback, imageUrl: t?.logo, size: 68, rounded: true, border: Border.all(color: Colors.white24, width: 2)),
              ),
              const SizedBox(height: 8),
              Text(t?.nom ?? fallback,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.secondary.withAlpha(50), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    LabelBadge(
                      label: m.competition?.nom ?? 'Match amical',
                      onDark: true,
                      icon: m.competition == null ? Icons.handshake_outlined : Icons.emoji_events_outlined,
                    ),
                  ],
                ),
              ),
              MatchStatusBadge(m.statut),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              team(m.homeTeam, 'Domicile'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  children: [
                    Text(started ? '${m.homeGoals} - ${m.awayGoals}' : 'VS', style: scoreStyle),
                    const SizedBox(height: 4),
                    Text(formatDateFr(m.dateDebut), style: text.labelMedium?.copyWith(color: Colors.white70)),
                    Text(formatTimeFr(m.heureDebut), style: text.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              team(m.awayTeam, 'Extérieur'),
            ],
          ),
          if (m.field?.nomTerrain != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stadium_outlined, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Flexible(child: Text(m.field!.nomTerrain!, style: text.bodySmall?.copyWith(color: Colors.white70))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  final MatchOverview o;
  final AppUser? user;
  final bool operator;
  const _ActionBar({required this.o, required this.user, required this.operator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = o.match;
    final uid = user?.id ?? -1;
    final isAnnouncer = m.isAnnouncedBy(uid);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (user != null) FollowButton(table: FollowTable.match, entityId: m.id, followLabel: 'Suivre ce match'),
        if (operator && !m.isFinished)
          FilledButton.icon(
            onPressed: () => context.push('/matches/${m.id}/live'),
            icon: const Icon(Icons.campaign_outlined),
            label: const Text('Annoncer ce match'),
          ),
        if (operator || isAnnouncer)
          OutlinedButton.icon(
            onPressed: () => context.push('/matches/${m.id}/media'),
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Médiater ce match'),
          ),
        if (m.isOwnedBy(uid) && m.isScheduled)
          OutlinedButton.icon(
            onPressed: () async {
              await context.push('/matches/${m.id}/edit', extra: m);
              ref.invalidate(matchOverviewProvider(m.id));
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier'),
          ),
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  final MatchOverview o;
  const _StatsTab({required this.o});

  int _h(String k) => o.homeStats[k] ?? 0;
  int _a(String k) => o.awayStats[k] ?? 0;

  @override
  Widget build(BuildContext context) {
    final m = o.match;
    final text = Theme.of(context).textTheme;
    final off = o.officials;
    final touches = [
      ('Tirs', _h('Tirs Cadrés') + _h('Tirs non Cadrés'), _a('Tirs Cadrés') + _a('Tirs non Cadrés')),
      ('Pénalty', _h('Tirs au But'), _a('Tirs au But')),
      ('Tirs cadrés', _h('Tirs Cadrés'), _a('Tirs Cadrés')),
      ('Tirs non cadrés', _h('Tirs non Cadrés'), _a('Tirs non Cadrés')),
      ('Coups francs', _h('Coups Francs'), _a('Coups Francs')),
      ('Corners', _h('Corners'), _a('Corners')),
      ('Cartons jaunes', _h('Cartons Jaunes'), _a('Cartons Jaunes')),
      ('Cartons rouges', _h('Cartons Rouges'), _a('Cartons Rouges')),
    ];

    final stats = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistiques du match', style: text.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text(m.homeTeam?.nom ?? '', style: text.labelLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800))),
              PossessionChart(home: o.homePossession, away: o.awayPossession),
              Expanded(child: Text(m.awayTeam?.nom ?? '', textAlign: TextAlign.end, style: text.labelLarge?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w800))),
            ],
          ),
          const Text('Possession', textAlign: TextAlign.center),
          const SizedBox(height: 6),
          StatCompareRow(label: 'Buts', home: m.homeGoals, away: m.awayGoals),
          for (final t in touches) StatCompareRow(label: t.$1, home: t.$2, away: t.$3),
          StatCompareRow(label: 'Possession', home: o.homePossession, away: o.awayPossession, percent: true),
          if (o.homeScorers.isNotEmpty || o.awayScorers.isNotEmpty) ...[
            const Divider(height: 26),
            Text('Buteurs', style: text.titleSmall),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final p in o.homeScorers) Text('⚽ ${p.fullName}')])),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [for (final p in o.awayScorers) Text('${p.fullName} ⚽')])),
              ],
            ),
          ],
        ],
      ),
    );

    final info = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations', style: text.titleMedium),
          const SizedBox(height: 6),
          InfoRow(icon: Icons.emoji_events_outlined, label: 'Compétition', value: m.competition?.nom ?? 'Match amical'),
          InfoRow(icon: Icons.stadium_outlined, label: 'Lieu', value: m.field?.nomTerrain),
          InfoRow(icon: Icons.sports, label: 'Arbitre principal', value: off.arbitrePrincipal),
          InfoRow(
              icon: Icons.flag_outlined,
              label: 'Arbitres de touche',
              value: [off.arbitreTouche1, off.arbitreTouche2].whereType<String>().join(' et ')),
          InfoRow(
              icon: Icons.mic_none,
              label: 'Commentateurs',
              value: [off.commentateur1, off.commentateur2].whereType<String>().join(' et ')),
          InfoRow(icon: Icons.timer_outlined, label: 'Chronométreur', value: off.chronometreur),
          InfoRow(icon: Icons.campaign_outlined, label: 'Annonceur public', value: off.annonciateur),
          InfoRow(icon: Icons.category_outlined, label: 'Catégorie', value: m.categorie),
          InfoRow(icon: Icons.wc, label: 'Genre', value: m.genre),
          InfoRow(icon: Icons.calendar_month_outlined, label: 'Saison', value: m.saison),
        ],
      ),
    );

    return ResponsiveColumns(children: [stats, info]);
  }
}

class _EventsTab extends StatelessWidget {
  final MatchOverview o;
  final bool canModerate;
  final Future<void> Function(GameEvent e, bool valid) onToggle;
  const _EventsTab({required this.o, required this.canModerate, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final events = o.events;
    if (events.isEmpty) {
      return const EmptyState(icon: Icons.timeline, title: 'Aucun évènement', message: "Les évènements du match s'afficheront ici en direct.");
    }
    final m = o.match;
    String teamName(int id) => id == m.homeTeamId ? (m.homeTeam?.nom ?? '') : (id == m.awayTeamId ? (m.awayTeam?.nom ?? '') : '');
    String? teamLogo(int id) => id == m.homeTeamId ? m.homeTeam?.logo : (id == m.awayTeamId ? m.awayTeam?.logo : null);

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(alignment: Alignment.centerLeft, child: Text('Statistiques de jeu', style: text.titleMedium)),
          ),
          for (final e in events)
            Container(
              color: e.isValid ? null : AppColors.error.withAlpha(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: eventStyle(e.jeu).color.withAlpha(28), borderRadius: BorderRadius.circular(12)),
                    child: Icon(eventStyle(e.jeu).icon, color: eventStyle(e.jeu).color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.jeu, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700, decoration: e.isValid ? null : TextDecoration.lineThrough)),
                        Row(
                          children: [
                            if (e.player != null) ...[
                              AppAvatar(name: e.player!.fullName, imageUrl: e.player!.avatar, size: 18),
                              const SizedBox(width: 6),
                              Flexible(child: Text(e.player!.fullName, style: text.bodySmall, overflow: TextOverflow.ellipsis)),
                            ],
                            if (teamName(e.teamId).isNotEmpty) ...[
                              const SizedBox(width: 8),
                              AppAvatar(name: teamName(e.teamId), imageUrl: teamLogo(e.teamId), size: 16, rounded: true),
                              const SizedBox(width: 4),
                              Flexible(child: Text(teamName(e.teamId), style: text.bodySmall, overflow: TextOverflow.ellipsis)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text("${e.temps}'", style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  if (canModerate) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: e.isValid ? AppColors.error : AppColors.success),
                      onPressed: () => onToggle(e, !e.isValid),
                      child: Text(e.isValid ? 'Annuler' : 'Valider'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  final MatchOverview o;
  const _RankingTab({required this.o});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = o.ranking;
    if (r.isEmpty) {
      return const EmptyState(icon: Icons.leaderboard_outlined, title: 'Pas encore de classement', message: 'Aucun but, passe ou carton enregistré.');
    }
    MatchPlayerRank? best(int Function(MatchPlayerRank) f) {
      final list = [...r]..sort((a, b) => f(b).compareTo(f(a)));
      return f(list.first) > 0 ? list.first : null;
    }

    Widget highlight(String title, IconData icon, Color color, MatchPlayerRank? p, String unit) => SurfaceCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.labelMedium),
                    Text(p?.name ?? '—', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    if (p != null) Text(unit, style: text.bodySmall),
                  ],
                ),
              ),
              if (p != null) AppAvatar(name: p.name, imageUrl: p.avatar, size: 40),
            ],
          ),
        );

    final bs = best((p) => p.buts);
    final ps = best((p) => p.passes);
    final cj = best((p) => p.cartonsJaunes);
    final cr = best((p) => p.cartonsRouges);

    return Column(
      children: [
        ResponsiveColumns(maxColumns: 2, children: [
          highlight('Meilleur buteur', Icons.sports_soccer, AppColors.success, bs, '${bs?.buts} buts'),
          highlight('Meilleur passeur', Icons.swap_calls, AppColors.info, ps, '${ps?.passes} passes décisives'),
          highlight('Carton jaune', Icons.style, AppColors.warning, cj, '${cj?.cartonsJaunes} cartons jaunes'),
          highlight('Carton rouge', Icons.style, AppColors.error, cr, '${cr?.cartonsRouges} cartons rouges'),
        ]),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 42,
              columns: const [
                DataColumn(label: Text('#')),
                DataColumn(label: Text('Joueur')),
                DataColumn(label: Text('Équipe')),
                DataColumn(label: Text('Buts'), numeric: true),
                DataColumn(label: Text('Passes'), numeric: true),
                DataColumn(label: Text('CJ'), numeric: true),
                DataColumn(label: Text('CR'), numeric: true),
              ],
              rows: [
                for (var i = 0; i < r.length; i++)
                  DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Row(children: [AppAvatar(name: r[i].name, imageUrl: r[i].avatar, size: 26), const SizedBox(width: 8), Text(r[i].name)])),
                    DataCell(Row(children: [AppAvatar(name: r[i].teamName, imageUrl: r[i].teamLogo, size: 24, rounded: true), const SizedBox(width: 6), Text(r[i].teamName)])),
                    DataCell(Text('${r[i].buts}')),
                    DataCell(Text('${r[i].passes}')),
                    DataCell(Text('${r[i].cartonsJaunes}')),
                    DataCell(Text('${r[i].cartonsRouges}')),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionsTab extends ConsumerWidget {
  final MatchOverview o;
  final int userId;
  final VoidCallback onChanged;
  const _SelectionsTab({required this.o, required this.userId, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = o.match;
    final homeOwner = ref.watch(teamDetailProvider(m.homeTeamId)).valueOrNull?.isManagedBy(userId) ?? false;
    final awayOwner = ref.watch(teamDetailProvider(m.awayTeamId)).valueOrNull?.isManagedBy(userId) ?? false;
    return ResponsiveColumns(children: [
      _TeamSelection(matchId: m.id, team: m.homeTeam, teamId: m.homeTeamId, players: o.homeSelection, canEdit: homeOwner, onChanged: onChanged),
      _TeamSelection(matchId: m.id, team: m.awayTeam, teamId: m.awayTeamId, players: o.awaySelection, canEdit: awayOwner, onChanged: onChanged),
    ]);
  }
}

class _TeamSelection extends ConsumerStatefulWidget {
  final int matchId;
  final MatchTeamRef? team;
  final int teamId;
  final List<SelectedPlayer> players;
  final bool canEdit;
  final VoidCallback onChanged;

  const _TeamSelection({required this.matchId, required this.team, required this.teamId, required this.players, required this.canEdit, required this.onChanged});

  @override
  ConsumerState<_TeamSelection> createState() => _TeamSelectionState();
}

class _TeamSelectionState extends ConsumerState<_TeamSelection> {
  late List<SelectedPlayer> _players = widget.players;

  @override
  void didUpdateWidget(covariant _TeamSelection old) {
    super.didUpdateWidget(old);
    _players = widget.players;
  }

  Future<void> _toggle(SelectedPlayer p) async {
    try {
      final statut = await ref.read(matchExtrasRepositoryProvider).toggleSelection(widget.matchId, widget.teamId, p.id);
      setState(() => _players = [for (final x in _players) x.id == p.id ? x.copyWith(statut: statut) : x]);
      widget.onChanged();
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = widget.team;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: t?.nom ?? '?', imageUrl: t?.logo, size: 44, rounded: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t?.nom ?? '', style: text.titleMedium),
                    Text('Joueurs sélectionnés pour ce match', style: text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_players.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('Aucun joueur dans cette équipe.')),
          for (final p in _players)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PersonTile(
                name: p.name,
                avatar: p.avatar,
                subtitle: [p.poste, if (p.age != null) '${p.age} ans'].whereType<String>().join(' | '),
                tint: p.statut == 1 ? AppColors.primary.withAlpha(20) : null,
                trailing: widget.canEdit
                    ? IconButton(
                        tooltip: p.statut == 1 ? 'Retirer' : 'Convoquer',
                        icon: Icon(p.statut == 1 ? Icons.check_circle : Icons.add_circle_outline, color: p.statut == 1 ? AppColors.primary : AppColors.textTertiary),
                        onPressed: () => _toggle(p),
                      )
                    : (p.statut == 1 ? const Icon(Icons.check_circle, color: AppColors.primary) : null),
              ),
            ),
        ],
      ),
    );
  }
}
