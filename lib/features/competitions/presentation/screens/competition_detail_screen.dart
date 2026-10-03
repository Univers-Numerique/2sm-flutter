import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_guard.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../follow/data/follow_repository.dart';
import '../../../follow/presentation/follow_button.dart';
import '../../../matches/data/models/match_game.dart';
import '../../../matches/presentation/widgets/match_widgets.dart';
import '../../../teams/application/teams_providers.dart';
import '../../data/competition_extras_repository.dart';
import '../../data/competitions_repository.dart';
import '../../data/models/competition.dart';
import '../../data/models/competition_overview.dart';
import 'competitions_list_screen.dart' show competitionStatusColor;
import 'schedule_matches_sheet.dart';

/// Fiche compétition (compte/details-competition.php) : couverture, suivi,
/// ouvrir/fermer la sélection, puis cinq onglets — Description (statistiques
/// + stades), Équipes (classement), Matchs, Participants, Classement des joueurs.
class CompetitionDetailScreen extends ConsumerStatefulWidget {
  final int competitionId;
  const CompetitionDetailScreen({super.key, required this.competitionId});

  @override
  ConsumerState<CompetitionDetailScreen> createState() => _CompetitionDetailScreenState();
}

class _CompetitionDetailScreenState extends ConsumerState<CompetitionDetailScreen> {
  static const _tabs = ['Description', 'Équipes', 'Matchs', 'Participants', 'Classement des joueurs'];
  int _tab = 0;

  int get _id => widget.competitionId;

  void _refresh() => ref.invalidate(competitionOverviewProvider(_id));

  Future<void> _run(Future<String?> Function() action) async {
    try {
      final message = await action();
      _refresh();
      if (message != null && mounted) showSnack(context, message);
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    }
  }

  Future<void> _toggleSelection(Competition c) => _run(() async {
        await ref.read(competitionExtrasRepositoryProvider).setSelectionOpen(c.id, c.selection == 0);
        return c.selection == 0 ? 'La sélection est ouverte.' : 'La sélection est fermée.';
      });

  Future<void> _schedule(Competition c) async {
    final created = await showScheduleMatchesSheet(context, competitionId: c.id, defaultDate: c.dateDebut);
    if (created != null) {
      _refresh();
      if (mounted) showSnack(context, '$created match(s) programmé(s).');
    }
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Effacer les matchs ?'),
        content: const Text('Tous les matchs de la compétition (scores, évènements, photos et sélections liés) seront supprimés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Effacer')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final n = await ref.read(competitionExtrasRepositoryProvider).clearMatches(_id);
      return '$n match(s) effacé(s).';
    });
  }

  Future<void> _registerTeam(Competition c, List<int> alreadyIn) async {
    if (!await requireAccount(context, ref, reason: 'inscrire votre équipe')) return;
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated || !mounted) return;
    final teams = (ref.read(teamsListProvider).valueOrNull ?? const []).where((t) => t.isManagedBy(auth.user.id) && !alreadyIn.contains(t.id)).toList();
    if (teams.isEmpty) {
      showSnack(context, "Aucune de vos équipes n'est disponible pour l'inscription.", error: true);
      return;
    }
    final team = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('Inscrire une équipe', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
            for (final t in teams)
              ListTile(
                leading: AppAvatar(name: t.nom, imageUrl: t.logo, size: 40, rounded: true),
                title: Text(t.nom),
                onTap: () => Navigator.pop(ctx, t.id),
              ),
          ],
        ),
      ),
    );
    if (team == null) return;
    await _run(() async {
      await ref.read(competitionExtrasRepositoryProvider).register(c.id, team);
      return 'Équipe inscrite à la compétition.';
    });
  }

  Future<void> _delete(Competition c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la compétition ?'),
        content: Text('« ${c.nom} » sera définitivement supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(competitionsRepositoryProvider).delete(c.id);
      if (mounted) context.pop();
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(competitionOverviewProvider(_id));
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(overview.valueOrNull?.competition.nom ?? 'Compétition'),
        actions: [
          if (overview.valueOrNull != null && user != null && (overview.value!.competition.isOwnedBy(user.id) || user.isAdmin))
            PopupMenuButton<String>(
              onSelected: (v) async {
                final c = overview.value!.competition;
                if (v == 'edit') {
                  await context.push('/competitions/create', extra: c);
                  _refresh();
                } else if (v == 'delete') {
                  await _delete(c);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
            ),
        ],
      ),
      body: overview.when(
        loading: () => const SkeletonList(count: 3, itemHeight: 200),
        error: (e, _) => ErrorState(error: e, onRetry: _refresh),
        data: (o) {
          final c = o.competition;
          final isOwner = user != null && c.isOwnedBy(user.id);
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(o: o, isOwner: isOwner, canFollow: true, onToggleSelection: () => _toggleSelection(c)),
                          const SizedBox(height: 14),
                          PillTabs(tabs: _tabs, selected: _tab, onSelected: (i) => setState(() => _tab = i)),
                          const SizedBox(height: 14),
                          switch (_tab) {
                            0 => _DescriptionTab(o: o, isOwner: isOwner),
                            1 => _TeamsTab(
                                o: o,
                                isOwner: isOwner,
                                canRegister: true, // visiteur : la connexion est proposée au clic
                                onRegister: () => _registerTeam(c, o.classement.map((r) => r.teamId).toList()),
                              ),
                            2 => _MatchesTab(o: o, isOwner: isOwner, onSchedule: () => _schedule(c), onClear: _clear),
                            3 => _ParticipantsTab(o: o, isOwner: isOwner, onRemove: (p) => _run(() async {
                                  await ref.read(competitionExtrasRepositoryProvider).toggleResource(_id, 'utilisateurs', p.id);
                                  return 'Participant retiré.';
                                })),
                            _ => _PlayersTab(o: o),
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

class _Header extends ConsumerWidget {
  final CompetitionOverview o;
  final bool isOwner;
  final bool canFollow;
  final VoidCallback onToggleSelection;
  const _Header({required this.o, required this.isOwner, required this.canFollow, required this.onToggleSelection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = o.competition;
    final text = Theme.of(context).textTheme;
    final progress = (o.progression / 100).clamp(0.0, 1.0);
    final followers = o.followers;
    final info = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(icon: Icons.calendar_today_outlined, label: 'Date de début', value: formatDateFr(c.dateDebut)),
          InfoRow(icon: Icons.schedule, label: 'Heure de début', value: formatTimeFr(c.heureDebut)),
          InfoRow(icon: Icons.stadium_outlined, label: 'Lieu', value: o.terrains.isEmpty ? null : o.terrains.first.nomTerrain),
          InfoRow(icon: Icons.category_outlined, label: 'Catégorie', value: c.categorie),
          InfoRow(icon: Icons.wc, label: 'Genre', value: c.genre),
          if (c.owner != null) InfoRow(icon: Icons.person_outline, label: 'Organisateur', value: c.owner!.fullName),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Progression de la compétition', style: text.labelMedium),
              const Spacer(),
              Text('${o.progression.round()}%', style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.surfaceVariant)),
        ],
      ),
    );

    final follow = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suivie par', style: text.titleSmall),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                height: 34,
                width: 34.0 + (followers.length.clamp(0, 5)) * 22,
                child: Stack(
                  children: [
                    for (var i = 0; i < followers.length.clamp(0, 5); i++)
                      Positioned(
                        left: i * 22.0,
                        child: AppAvatar(name: followers[i].fullName, imageUrl: followers[i].avatar, size: 34, border: Border.all(color: Colors.white, width: 2)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(followers.length > 5 ? '+${followers.length - 5}' : (followers.isEmpty ? 'Aucun abonné' : ''), style: text.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (canFollow) FollowButton(table: FollowTable.competition, entityId: c.id, followLabel: 'Suivre cette compétition'),
              if (isOwner)
                OutlinedButton.icon(
                  onPressed: onToggleSelection,
                  icon: Icon(c.selection == 0 ? Icons.lock_open_outlined : Icons.lock_outline),
                  label: Text(c.selection == 0 ? 'Ouvrir la sélection' : 'Fermer la sélection'),
                ),
            ],
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCover(
          imageUrl: c.photo,
          height: 200,
          overlay: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.nom, style: text.headlineSmall?.copyWith(color: Colors.white)),
                    if (c.saison != null) Text('Saison ${c.saison}', style: text.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              StatusBadge(
                label: CompetitionStatus.label(c.statut),
                color: competitionStatusColor(c.statut) == AppColors.matchLive ? AppColors.matchLive : Colors.white,
                solid: c.statut == CompetitionStatus.inProgress,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ResponsiveColumns(children: [info, follow]),
      ],
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  final CompetitionOverview o;
  final bool isOwner;
  const _DescriptionTab({required this.o, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final c = o.competition;
    final s = o.stats;
    final text = Theme.of(context).textTheme;
    final tiles = [
      ("Nombre d'équipes participantes", s.equipes, Icons.groups_outlined, AppColors.primary),
      ('Nombre de matchs', s.matchs, Icons.sports_soccer, AppColors.secondary),
      ('Nombre de matchs en cours', s.enCours, Icons.play_circle_outline, AppColors.matchLive),
      ('Nombre de matchs joués', s.termines, Icons.check_circle_outline, AppColors.success),
      ('Nombre de matchs futures', s.futurs, Icons.event_outlined, AppColors.info),
      ('Nombre de buts', s.buts, Icons.sports_score, AppColors.success),
      ('Nombre de passes décisives', s.passes, Icons.swap_calls, AppColors.info),
      ('Nombre de cartons jaunes', s.cartonsJaunes, Icons.style, AppColors.warning),
      ('Nombre de cartons rouges', s.cartonsRouges, Icons.style, AppColors.error),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description', style: text.titleLarge),
              const SizedBox(height: 8),
              Text(c.description == null || c.description!.isEmpty ? 'Aucune description.' : c.description!, style: text.bodyLarge),
              const SizedBox(height: 8),
              Text('Venez soutenir votre équipe préférée et profitez du spectacle.', style: text.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SectionHeader(title: 'Statistiques'),
        LayoutBuilder(builder: (context, cons) {
          final cols = cons.maxWidth >= 900 ? 5 : (cons.maxWidth >= 560 ? 3 : 2);
          final w = (cons.maxWidth - 12 * (cols - 1)) / cols;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final t in tiles) SizedBox(width: w, height: 132, child: StatTile(label: t.$1, value: '${t.$2}', icon: t.$3, color: t.$4)),
            ],
          );
        }),
        SectionHeader(
          title: 'Stades',
          trailing: isOwner
              ? TextButton.icon(
                  onPressed: () => context.push('/competitions/${c.id}/resources/terrains'),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un stade'),
                )
              : null,
        ),
        if (o.terrains.isEmpty)
          const SurfaceCard(child: Text('Aucun stade rattaché à cette compétition.'))
        else
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: o.terrains.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final t = o.terrains[i];
                return SizedBox(
                  width: 240,
                  child: SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCover(imageUrl: t.photo, height: 104, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.nomTerrain ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                              Text(t.lieu ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TeamsTab extends StatelessWidget {
  final CompetitionOverview o;
  final bool isOwner;
  final bool canRegister;
  final VoidCallback onRegister;
  const _TeamsTab({required this.o, required this.isOwner, required this.canRegister, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final c = o.competition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Équipes participantes',
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          trailing: Wrap(
            spacing: 6,
            children: [
              if (canRegister)
                TextButton.icon(onPressed: onRegister, icon: const Icon(Icons.how_to_reg_outlined), label: const Text('Inscrire mon équipe')),
              if (isOwner)
                TextButton.icon(
                  onPressed: () => context.push('/competitions/${c.id}/resources/equipes'),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une équipe'),
                ),
            ],
          ),
        ),
        StandingsTable(rows: o.classement, onTeamTap: (r) => context.push('/competitions/${c.id}/teams/${r.teamId}/selection')),
        const SizedBox(height: 8),
        Text('Touchez une équipe pour voir sa sélection de joueurs.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _MatchesTab extends StatefulWidget {
  final CompetitionOverview o;
  final bool isOwner;
  final VoidCallback onSchedule;
  final VoidCallback onClear;
  const _MatchesTab({required this.o, required this.isOwner, required this.onSchedule, required this.onClear});

  @override
  State<_MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends State<_MatchesTab> {
  String? _day;
  int? _statut;

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final c = o.competition;
    final text = Theme.of(context).textTheme;
    final days = (o.matchs.map((m) => (m.dateDebut ?? '').split('T').first).where((d) => d.isNotEmpty).toSet().toList()..sort());
    final filtered = o.matchs.where((m) {
      if (_day != null && (m.dateDebut ?? '').split('T').first != _day) return false;
      if (_statut != null && m.statut != _statut) return false;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Liste des Matches', style: text.titleLarge)),
          ],
        ),
        if (widget.isOwner) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => context.push('/matches/create', extra: c.id),
                icon: const Icon(Icons.add),
                label: const Text('Programmer un match'),
              ),
              OutlinedButton.icon(onPressed: widget.onSchedule, icon: const Icon(Icons.auto_awesome_motion_outlined), label: const Text('Programmer plusieurs matchs')),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                onPressed: widget.onClear,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Effacer les matchs'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _Filter<String>(
              hint: 'Toutes les journées',
              value: _day,
              items: {for (var i = 0; i < days.length; i++) days[i]: 'JOURNEE ${i + 1} (${formatDateFr(days[i], withDay: false)})'},
              onChanged: (v) => setState(() => _day = v),
            ),
            _Filter<int>(
              hint: 'Tous les matchs',
              value: _statut,
              items: const {0: 'Matchs futures', 1: 'Matchs en cours', 2: 'Matchs annulés', 3: 'Matchs terminés'},
              onChanged: (v) => setState(() => _statut = v),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const EmptyState(icon: Icons.event_busy_outlined, title: 'Aucun match', message: 'Aucun match programmé pour ce filtre.')
        else
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < filtered.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MatchRow(match: filtered[i], isOwner: widget.isOwner, competitionId: c.id),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Filter<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  const _Filter({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: items.containsKey(value) ? value : null,
          isExpanded: true,
          hint: Text(hint),
          items: [
            DropdownMenuItem<T?>(value: null, child: Text(hint)),
            for (final e in items.entries) DropdownMenuItem<T?>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final MatchGame match;
  final bool isOwner;
  final int competitionId;
  const _MatchRow({required this.match, required this.isOwner, required this.competitionId});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final started = match.statut != MatchStatus.scheduled;
    return InkWell(
      onTap: () => context.push('/matches/${match.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('n° ${match.id}', style: text.labelSmall),
                const SizedBox(width: 10),
                Expanded(child: Text(formatDateTimeFr(match.dateDebut, match.heureDebut), style: text.labelMedium)),
                MatchStatusBadge(match.statut),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(child: Text(match.homeTeam?.nom ?? '', textAlign: TextAlign.end, overflow: TextOverflow.ellipsis, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                      const SizedBox(width: 8),
                      AppAvatar(name: match.homeTeam?.nom ?? '?', imageUrl: match.homeTeam?.logo, size: 32, rounded: true),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                  child: Text(started ? '${match.homeGoals} - ${match.awayGoals}' : 'VS', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: Row(
                    children: [
                      AppAvatar(name: match.awayTeam?.nom ?? '?', imageUrl: match.awayTeam?.logo, size: 32, rounded: true),
                      const SizedBox(width: 8),
                      Flexible(child: Text(match.awayTeam?.nom ?? '', overflow: TextOverflow.ellipsis, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isOwner && match.isScheduled)
                  TextButton(onPressed: () => context.push('/matches/${match.id}/edit', extra: match), child: const Text('Modifier')),
                TextButton(onPressed: () => context.push('/matches/${match.id}'), child: const Text('Infos')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  final CompetitionOverview o;
  final bool isOwner;
  final void Function(CompetitionParticipant p) onRemove;
  const _ParticipantsTab({required this.o, required this.isOwner, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Liste des utilisateurs',
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          trailing: isOwner
              ? TextButton.icon(
                  onPressed: () => context.push('/competitions/${o.competition.id}/resources/utilisateurs'),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Ajouter un participant'),
                )
              : null,
        ),
        if (o.participants.isEmpty)
          const EmptyState(icon: Icons.people_outline, title: 'Aucun participant', message: 'Arbitres, commentateurs et autres officiels apparaîtront ici.')
        else
          ResponsiveColumns(
            spacing: 10,
            maxColumns: 2,
            children: [
              for (final p in o.participants)
                PersonTile(
                  name: p.fullName,
                  avatar: p.avatar,
                  subtitle: [p.poste, if (p.age != null) '${p.age} ans'].whereType<String>().join(' · '),
                  trailing: isOwner
                      ? TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: () => onRemove(p),
                          icon: const Icon(Icons.person_remove_outlined, size: 18),
                          label: const Text('Retirer'),
                        )
                      : null,
                ),
            ],
          ),
        const SizedBox(height: 10),
        Text('${o.participants.length} utilisateur(s) trouvé(s)', style: text.bodySmall),
      ],
    );
  }
}

class _PlayersTab extends StatelessWidget {
  final CompetitionOverview o;
  const _PlayersTab({required this.o});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = o.joueurs;
    if (r.isEmpty) {
      return const EmptyState(icon: Icons.leaderboard_outlined, title: 'Pas encore de classement', message: 'Aucun but, passe ou carton enregistré.');
    }
    PlayerRank? best(int Function(PlayerRank) f) {
      final list = [...r]..sort((a, b) => f(b).compareTo(f(a)));
      return f(list.first) > 0 ? list.first : null;
    }

    Widget highlight(String title, IconData icon, Color color, PlayerRank? p, String unit) => SurfaceCard(
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
              if (p != null) AppAvatar(name: p.name, imageUrl: p.avatar, size: 42),
            ],
          ),
        );

    final bs = best((p) => p.buts);
    final ps = best((p) => p.passes);
    final cj = best((p) => p.cartonsJaunes);
    final cr = best((p) => p.cartonsRouges);

    return Column(
      children: [
        LayoutBuilder(builder: (context, cons) {
          final cols = cons.maxWidth >= 900 ? 4 : (cons.maxWidth >= 560 ? 2 : 1);
          final w = (cons.maxWidth - 12 * (cols - 1)) / cols;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: w, child: highlight('Meilleur butteur', Icons.sports_soccer, AppColors.success, bs, '${bs?.buts} buts')),
            SizedBox(width: w, child: highlight('Meilleur passeur', Icons.swap_calls, AppColors.info, ps, '${ps?.passes} passes décisives')),
            SizedBox(width: w, child: highlight('Carton jaune', Icons.style, AppColors.warning, cj, '${cj?.cartonsJaunes} cartons jaunes')),
            SizedBox(width: w, child: highlight('Carton rouge', Icons.style, AppColors.error, cr, '${cr?.cartonsRouges} cartons rouges')),
          ]);
        }),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 42,
              columns: const [
                DataColumn(label: Text('Position')),
                DataColumn(label: Text('Joueur')),
                DataColumn(label: Text('Équipe')),
                DataColumn(label: Text('Buts marqués'), numeric: true),
                DataColumn(label: Text('Passes décisives'), numeric: true),
                DataColumn(label: Text('Cartons jaunes'), numeric: true),
                DataColumn(label: Text('Cartons rouges'), numeric: true),
              ],
              rows: [
                for (var i = 0; i < r.length; i++)
                  DataRow(cells: [
                    DataCell(Text('${i + 1}')),
                    DataCell(Row(children: [AppAvatar(name: r[i].name, imageUrl: r[i].avatar, size: 28), const SizedBox(width: 8), Text(r[i].name)])),
                    DataCell(Row(children: [AppAvatar(name: r[i].teamName, imageUrl: r[i].teamLogo, size: 26, rounded: true), const SizedBox(width: 6), Text(r[i].teamName)])),
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
