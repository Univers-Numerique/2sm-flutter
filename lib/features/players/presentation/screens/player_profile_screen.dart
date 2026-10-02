import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../follow/data/follow_repository.dart';
import '../../../follow/presentation/follow_button.dart';
import '../../../teams/application/teams_providers.dart';
import '../../../teams/data/teams_repository.dart';
import '../../application/players_providers.dart';
import '../../data/football_constants.dart';
import '../../data/models/player.dart';
import '../widgets/people_widgets.dart';
import '../widgets/skill_radar.dart';

/// Player / user page — port of `compte/infos-utilisateur.php` and
/// `manage/utilisateurs/infos-utilisateur.php`.
class PlayerProfileScreen extends ConsumerWidget {
  final int userId;
  const PlayerProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userDetailProvider(userId)).valueOrNull?.fullName ?? 'Profil';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: PlayerProfileBody(userId: userId),
    );
  }
}

/// The profile content, reusable inside another scaffold (own profile tab).
class PlayerProfileBody extends ConsumerWidget {
  final int userId;
  final List<Widget> trailing;
  final List<Widget> leadingActions;
  const PlayerProfileBody({super.key, required this.userId, this.trailing = const [], this.leadingActions = const []});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userId));
    final statsAsync = ref.watch(userStatsProvider(userId));
    final auth = ref.watch(authNotifierProvider);
    final meId = auth is AuthAuthenticated ? auth.user.id : null;
    final isSelf = meId == userId;

    Future<void> refresh() async {
      ref.invalidate(userDetailProvider(userId));
      ref.invalidate(userStatsProvider(userId));
      ref.invalidate(userPerformancesProvider(userId));
      await ref.read(userDetailProvider(userId).future).catchError((_) => const PlayerUser(id: 0));
    }

    return userAsync.when(
      loading: () => const SkeletonList(count: 4, itemHeight: 140),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(userDetailProvider(userId))),
      data: (user) {
        final stats = statsAsync.valueOrNull;
        return PageBody(
          onRefresh: refresh,
          children: [
            _Hero(user: user, stats: stats, isSelf: isSelf, actions: leadingActions),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final left = <Widget>[
                _AccountCard(user: user, isSelf: isSelf),
                ..._positionCards(user, meId, ref),
              ];
              final right = <Widget>[
                _SkillsCard(statsAsync: statsAsync),
                _SkillsByTypeCard(type: 'Techniques', title: 'Compétences techniques', statsAsync: statsAsync),
                _SkillsByTypeCard(type: 'Physiques', title: 'Compétences physiques', statsAsync: statsAsync),
                _HistoryCard(userId: userId),
                ...trailing,
              ];
              Widget stack(List<Widget> l) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final w in l) Padding(padding: const EdgeInsets.only(bottom: 16), child: w)],
                  );
              if (!wide) return stack([...right.take(3), ...left, ...right.skip(3)]);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: stack(left)),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: stack(right)),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  List<Widget> _positionCards(PlayerUser user, int? meId, WidgetRef ref) {
    final teams = ref.watch(teamsListProvider).valueOrNull ?? const [];
    final actives = user.positions.where((p) => p.teamId != null).toList();
    if (actives.isEmpty) {
      return [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informations du membre', style: Theme.of(ref.context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text("Ce membre n'appartient à aucune équipe pour le moment.", style: Theme.of(ref.context).textTheme.bodyMedium),
            ],
          ),
        ),
      ];
    }
    return [
      for (final p in actives)
        _PositionCard(
          key: ValueKey('pos-${p.id}'),
          position: p,
          canEdit: meId != null && teams.any((t) => t.id == p.teamId && t.ownerId == meId),
        ),
    ];
  }
}

class _Hero extends StatelessWidget {
  final PlayerUser user;
  final UserStats? stats;
  final bool isSelf;
  final List<Widget> actions;
  const _Hero({required this.user, required this.stats, required this.isSelf, required this.actions});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sub = [if (user.profession != null) user.profession!, if (user.ville != null) user.ville!].join(' · ');
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
              AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 88, border: Border.all(color: Colors.white24, width: 3)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: t.headlineSmall?.copyWith(color: Colors.white)),
                    if (sub.isNotEmpty) Text(sub, style: t.bodyMedium?.copyWith(color: Colors.white70)),
                    if (user.email != null) Text(user.email!, style: t.bodySmall?.copyWith(color: Colors.white60)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (user.mainPosition?.poste != null)
                          StatusBadge(label: user.mainPosition!.poste!, color: Colors.white, icon: Icons.badge_outlined),
                        if (user.age != null) StatusBadge(label: '${user.age} ans', color: Colors.white),
                        if (user.genre != null) StatusBadge(label: user.genre!, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.citation != null) ...[
            const SizedBox(height: 14),
            Text('« ${user.citation} »', style: t.bodyMedium?.copyWith(color: Colors.white70, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!isSelf) FollowButton(table: FollowTable.user, entityId: user.id, followLabel: "M'abonner", unfollowLabel: 'Me désabonner', onDark: true),
              if (!isSelf)
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/messaging/private/${user.id}'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Messages'),
                ),
              ...actions,
            ],
          ),
          if (stats != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _HeroStat(value: stats!.totalMatches, label: 'Matchs'),
                _HeroStat(value: stats!.totalGoals, label: 'Buts'),
                _HeroStat(value: stats!.teamsCount, label: 'Équipes'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final int value;
  final String label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text('$value', style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            Text(label, style: t.bodySmall?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final PlayerUser user;
  final bool isSelf;
  const _AccountCard({required this.user, required this.isSelf});

  @override
  Widget build(BuildContext context) {
    final dob = user.dateDeNaissance == null ? null : '${formatDateFr(user.dateDeNaissance)}${user.age != null ? ' (${user.age} ans)' : ''}';
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Détails du compte', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          InfoRow(icon: Icons.work_outline, label: 'Profession', value: user.profession),
          InfoRow(icon: Icons.location_on_outlined, label: 'Emplacement', value: user.adresse),
          InfoRow(icon: Icons.wc, label: 'Genre', value: user.genre),
          InfoRow(icon: Icons.email_outlined, label: 'E-mail', value: user.email),
          InfoRow(icon: Icons.phone_outlined, label: 'Téléphone', value: user.telephone),
          InfoRow(icon: Icons.cake_outlined, label: 'Naissance', value: dob),
          if (user.pays != null || user.ville != null)
            InfoRow(icon: Icons.public, label: 'Pays / ville', value: [user.pays, user.ville].where((e) => e != null).join(' · ')),
          if (user.dateInscription != null)
            InfoRow(icon: Icons.event_available_outlined, label: 'Inscrit', value: formatDateFr(user.dateInscription)),
          if (user.biographie != null) InfoRow(icon: Icons.info_outline, label: 'Biographie', value: user.biographie),
          if (user.hasSocials) ...[
            const SizedBox(height: 4),
            SocialLinks(user: user),
          ],
        ],
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  final AsyncValue<UserStats> statsAsync;
  const _SkillsCard({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compétences du joueur', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          statsAsync.when(
            loading: () => const SkeletonBox(height: 220, radius: 16),
            error: (e, _) => Text('$e'),
            data: (s) {
              final counters = s.eventsByType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkillRadar(skills: s.skills),
                  if (counters.isNotEmpty) ...[
                    const Divider(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final e in counters)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: gameEventColor(e.key).withAlpha(24), borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(gameEventIcon(e.key), size: 20, color: gameEventColor(e.key)),
                                const SizedBox(width: 8),
                                Text(e.key, style: Theme.of(context).textTheme.labelMedium),
                                const SizedBox(width: 10),
                                Text('${e.value}', style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SkillsByTypeCard extends StatelessWidget {
  final String type;
  final String title;
  final AsyncValue<UserStats> statsAsync;
  const _SkillsByTypeCard({required this.type, required this.title, required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.titleLarge),
          const SizedBox(height: 10),
          statsAsync.when(
            loading: () => const SkeletonBox(height: 90, radius: 16),
            error: (e, _) => Text('$e'),
            data: (s) {
              final list = s.skillsOfType(type);
              if (list.isEmpty) return Text('Aucune évaluation enregistrée.', style: t.bodyMedium);
              // Group by category, in the legacy order of the reference lists.
              final order = kCompetences[type]!.keys.toList();
              final groups = <String, List<Skill>>{};
              for (final sk in list) {
                groups.putIfAbsent(sk.categorie ?? 'Autres', () => []).add(sk);
              }
              final keys = groups.keys.toList()
                ..sort((a, b) {
                  final ia = order.indexOf(a);
                  final ib = order.indexOf(b);
                  return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
                });
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final k in keys) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 8),
                      child: Text(k, style: t.labelLarge?.copyWith(color: AppColors.primary)),
                    ),
                    SkillGrid(skills: groups[k]!),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final int userId;
  const _HistoryCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userPerformancesProvider(userId));
    final t = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historique des évaluations', style: t.titleLarge),
          const SizedBox(height: 8),
          async.when(
            loading: () => const SkeletonBox(height: 80, radius: 16),
            error: (e, _) => Text('$e'),
            data: (list) {
              if (list.isEmpty) return Text('Aucune évaluation.', style: t.bodyMedium);
              return Column(
                children: [
                  for (final s in list.take(8))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(skillIcon(s.performance), color: AppColors.primary),
                      title: Text(s.performance),
                      subtitle: Text([if (s.type != null) s.type!, formatDateFr(s.createdAt)].join(' · ')),
                      trailing: Text(s.valeur.toStringAsFixed(0), style: t.titleMedium),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// "Informations du membre" + "Statistiques de l'équipe" for one position.
/// Editable by the manager of that team (legacy `$disabled` rule).
class _PositionCard extends ConsumerStatefulWidget {
  final PlayerPosition position;
  final bool canEdit;
  const _PositionCard({super.key, required this.position, required this.canEdit});

  @override
  ConsumerState<_PositionCard> createState() => _PositionCardState();
}

class _PositionCardState extends ConsumerState<_PositionCard> {
  late String? _type = widget.position.type;
  late String? _poste = widget.position.poste;
  late String? _categorie = widget.position.categorie;
  late final _pied = TextEditingController(text: widget.position.piedFort ?? '');
  late final _maillot = TextEditingController(text: widget.position.numeroDeMaillot ?? '');
  late final _taille = TextEditingController(text: widget.position.taille?.toString() ?? '');
  late final _poids = TextEditingController(text: widget.position.poids?.toString() ?? '');
  late final _nationalite = TextEditingController(text: widget.position.nationalite ?? '');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_pied, _maillot, _taille, _poids, _nationalite]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final p = widget.position;
    setState(() => _saving = true);
    try {
      await ref.read(teamsRepositoryProvider).addMember(
        p.teamId!,
        p.userId,
        poste: _poste ?? 'Joueur',
        categorie: _categorie,
        type: _type,
        extra: {
          'pied_fort': _pied.text.trim(),
          'numero_de_maillot': _maillot.text.trim(),
          'taille': double.tryParse(_taille.text.replaceAll(',', '.')),
          'poids': double.tryParse(_poids.text.replaceAll(',', '.')),
          'nationalite': _nationalite.text.trim(),
        },
      );
      ref.invalidate(userDetailProvider(p.userId));
      ref.invalidate(teamMembersProvider(p.teamId!));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informations du joueur enregistrées.')));
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    final t = Theme.of(context).textTheme;
    final teamStats = ref.watch(teamDetailProvider(p.teamId!)).valueOrNull?.statistics;
    final allPostes = [for (final e in kPostesFootball.values) ...e];
    final postes = {...allPostes, ?_poste}.toList();
    final types = {...kPostesFootball.keys, ?_type}.toList();
    final enabled = widget.canEdit;

    Widget field(String label, TextEditingController c, {TextInputType? type}) => TextField(
          controller: c,
          enabled: enabled,
          keyboardType: type,
          decoration: InputDecoration(labelText: label, isDense: true),
        );

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations du membre', style: t.titleLarge),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/teams/${p.teamId}'),
            child: Row(
              children: [
                AppAvatar(name: p.teamName ?? 'Équipe', imageUrl: p.teamLogo, size: 56, rounded: true),
                const SizedBox(width: 12),
                Expanded(child: Text(p.teamName ?? 'Équipe', style: t.titleMedium)),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final two = c.maxWidth >= 420;
            Widget pair(Widget a, Widget b) => two
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)])
                : Column(children: [a, const SizedBox(height: 12), b]);
            return Column(
              children: [
                pair(
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type de poste', isDense: true),
                    items: [for (final e in types) DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))],
                    onChanged: enabled ? (v) => setState(() => _type = v) : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _poste,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Poste', isDense: true),
                    items: [for (final e in postes) DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))],
                    onChanged: enabled ? (v) => setState(() => _poste = v) : null,
                  ),
                ),
                const SizedBox(height: 12),
                pair(field('Pied fort', _pied), field('Numéro de maillot', _maillot, type: TextInputType.number)),
                const SizedBox(height: 12),
                pair(
                  DropdownButtonFormField<String?>(
                    initialValue: _categorie,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Catégorie', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('—')),
                      for (final e in {...kCategories, ?_categorie})
                        DropdownMenuItem(value: e, child: Text(e)),
                    ],
                    onChanged: enabled ? (v) => setState(() => _categorie = v) : null,
                  ),
                  field('Taille (m)', _taille, type: const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(height: 12),
                pair(field('Poids (kg)', _poids, type: const TextInputType.numberWithOptions(decimal: true)), field('Nationalité', _nationalite)),
              ],
            );
          }),
          if (enabled) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: const Text('Enregistrer les informations du joueur'),
            ),
          ],
          if (teamStats != null) ...[
            const Divider(height: 32),
            Text("Statistiques de l'équipe", style: t.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: StatTile(label: 'Victoires', value: '${teamStats.wins}', icon: Icons.emoji_events_outlined, color: AppColors.success)),
                const SizedBox(width: 10),
                Expanded(child: StatTile(label: 'Nuls', value: '${teamStats.draws}', icon: Icons.drag_handle, color: AppColors.warning)),
                const SizedBox(width: 10),
                Expanded(child: StatTile(label: 'Défaites', value: '${teamStats.defeats}', icon: Icons.trending_down, color: AppColors.error)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
