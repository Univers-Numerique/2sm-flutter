import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../data/match_extras_repository.dart';
import '../../data/matches_repository.dart';
import '../../data/models/match_game.dart';
import '../../data/models/match_overview.dart';
import '../widgets/match_widgets.dart';
import 'match_detail_screen.dart' show eventStyle;

/// Console d'arbitrage / d'annonce en direct (compte/arbitrage.php) :
/// démarrer, stopper, reprendre, terminer ; évènements par équipe (buts,
/// passes, tirs, pénalty, coups francs, corners, cartons, fautes, passes,
/// centres, interceptions, tacles...) attribués à un joueur avec le temps de
/// jeu du chronomètre ; annulation/validation des évènements saisis.
///
/// Chaque action passe directement par l'API (le score doit être recalculé
/// par le serveur) : aucune saisie hors-ligne.
class MatchLiveConsoleScreen extends ConsumerStatefulWidget {
  final int matchId;
  const MatchLiveConsoleScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchLiveConsoleScreen> createState() => _MatchLiveConsoleScreenState();
}

class _MatchLiveConsoleScreenState extends ConsumerState<MatchLiveConsoleScreen> {
  Timer? _ticker;
  int _seconds = 0;
  bool _running = false;
  bool _synced = false;
  bool _busy = false;

  static const _startMarks = {'Debut de match', 'Début de match', 'Reprise de match'};

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int _parse(String temps) {
    final p = temps.split(':');
    if (p.length == 2) return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
    if (p.length == 1) return (int.tryParse(p[0]) ?? 0) * 60;
    return 0;
  }

  String get _clock => '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';

  /// Recale le chronomètre sur les évènements du serveur (dernier temps, en marche ou pas).
  void _sync(MatchOverview o) {
    final valid = o.events.where((e) => e.isValid).toList();
    final last = valid.isEmpty ? null : valid.last;
    final marks = valid.where((e) => e.teamId == 0).toList();
    final running = o.match.isInProgress && marks.isNotEmpty && _startMarks.contains(marks.last.jeu);
    _seconds = last == null ? 0 : _parse(last.temps);
    _running = running;
    _ticker?.cancel();
    if (running) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
    }
    _synced = true;
  }

  void _reload() {
    _synced = false;
    ref.invalidate(matchOverviewProvider(widget.matchId));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      _reload();
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    } catch (_) {
      if (mounted) showSnack(context, 'Une erreur est survenue.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logEvent(MatchOverview o, int teamId, String jeu) async {
    final pool = teamId == o.match.homeTeamId ? o.homeSelection : o.awaySelection;
    final selected = pool.where((p) => p.statut == 1).toList();
    final players = selected.isEmpty ? pool : selected;
    final player = await showModalBottomSheet<SelectedPlayer>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(children: [
                Icon(eventStyle(jeu).icon, color: eventStyle(jeu).color),
                const SizedBox(width: 10),
                Expanded(child: Text('$jeu — choisir le joueur', style: Theme.of(ctx).textTheme.titleMedium)),
              ]),
            ),
            Expanded(
              child: players.isEmpty
                  ? const Center(child: Text('Aucun joueur dans cette équipe.'))
                  : ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: players.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(ctx, players[i]),
                          child: PersonTile(name: players[i].name, avatar: players[i].avatar, subtitle: players[i].poste),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    if (player == null) return;
    await _run(() async {
      await ref.read(matchesRepositoryProvider).logEvent(
            o.match.id,
            jeu: jeu,
            teamId: teamId,
            playerId: player.id,
            temps: _clock,
          );
    });
  }

  Future<void> _end(MatchOverview o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer le match ?'),
        content: Text('Score final : ${o.match.homeGoals} - ${o.match.awayGoals}. Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminer')),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(matchesRepositoryProvider).end(o.match.id);
    });
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(matchOverviewProvider(widget.matchId));
    return Scaffold(
      appBar: AppBar(title: const Text('Annoncer ce match')),
      body: overview.when(
        loading: () => const SkeletonList(count: 3, itemHeight: 160),
        error: (e, _) => ErrorState(error: e, onRetry: _reload),
        data: (o) {
          if (!_synced) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _sync(o));
            });
          }
          return _body(o);
        },
      ),
    );
  }

  Widget _body(MatchOverview o) {
    final m = o.match;
    final text = Theme.of(context).textTheme;
    final recent = o.events.reversed.take(12).toList();

    Widget controlButton(String label, IconData icon, VoidCallback? onTap, {Color? color}) => FilledButton.icon(
          style: color == null ? null : FilledButton.styleFrom(backgroundColor: color),
          onPressed: _busy ? null : onTap,
          icon: Icon(icon),
          label: Text(label),
        );

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MatchStatusBadge(m.statut),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
                              child: Row(children: [
                                Icon(_running ? Icons.timer_outlined : Icons.pause_circle_outline, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(_clock, style: text.titleMedium?.copyWith(color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()])),
                              ]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Column(children: [
                                AppAvatar(name: m.homeTeam?.nom ?? '?', imageUrl: m.homeTeam?.logo, size: 60, rounded: true),
                                const SizedBox(height: 6),
                                Text(m.homeTeam?.nom ?? '', textAlign: TextAlign.center, style: text.titleSmall?.copyWith(color: Colors.white)),
                              ]),
                            ),
                            Text('${m.homeGoals} - ${m.awayGoals}', style: AppTextStyles.score.copyWith(color: Colors.white, fontSize: 48)),
                            Expanded(
                              child: Column(children: [
                                AppAvatar(name: m.awayTeam?.nom ?? '?', imageUrl: m.awayTeam?.logo, size: 60, rounded: true),
                                const SizedBox(height: 6),
                                Text(m.awayTeam?.nom ?? '', textAlign: TextAlign.center, style: text.titleSmall?.copyWith(color: Colors.white)),
                              ]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      if (m.isScheduled) controlButton('Démarrer le match', Icons.play_arrow, () => _run(() => ref.read(matchesRepositoryProvider).start(m.id))),
                      if (m.isInProgress && _running)
                        controlButton('Stopper le match', Icons.pause, () => _run(() => ref.read(matchExtrasRepositoryProvider).pause(m.id)), color: AppColors.warning),
                      if (m.isInProgress && !_running)
                        controlButton('Reprendre le match', Icons.play_arrow, () => _run(() => ref.read(matchExtrasRepositoryProvider).resume(m.id))),
                      if (m.isInProgress) controlButton('Terminer le match', Icons.stop, () => _end(o), color: AppColors.error),
                      if (m.isFinished) const StatusBadge(label: 'Match terminé', color: AppColors.success, icon: Icons.check_circle),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (m.isInProgress)
                    ResponsiveColumns(children: [
                      _TeamPanel(name: m.homeTeam?.nom ?? 'Domicile', logo: m.homeTeam?.logo, enabled: !_busy, onEvent: (jeu) => _logEvent(o, m.homeTeamId, jeu)),
                      _TeamPanel(name: m.awayTeam?.nom ?? 'Extérieur', logo: m.awayTeam?.logo, enabled: !_busy, onEvent: (jeu) => _logEvent(o, m.awayTeamId, jeu)),
                    ])
                  else
                    const EmptyState(icon: Icons.sports, title: 'Saisie indisponible', message: 'La saisie des évènements est disponible pendant le match.'),
                  const SectionHeader(title: 'Derniers évènements'),
                  if (recent.isEmpty)
                    const SurfaceCard(child: Text('Aucun évènement pour le moment.'))
                  else
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          for (final e in recent)
                            ListTile(
                              dense: true,
                              tileColor: e.isValid ? null : AppColors.error.withAlpha(18),
                              leading: Icon(eventStyle(e.jeu).icon, color: eventStyle(e.jeu).color),
                              title: Text(e.jeu, style: TextStyle(decoration: e.isValid ? null : TextDecoration.lineThrough, fontWeight: FontWeight.w700)),
                              subtitle: Text(e.player?.fullName ?? ''),
                              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text("${e.temps}'", style: const TextStyle(fontWeight: FontWeight.w800)),
                                if (e.teamId != 0)
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: e.isValid ? AppColors.error : AppColors.success),
                                    onPressed: _busy ? null : () => _run(() => ref.read(matchesRepositoryProvider).setEventStatus(m.id, e.id, valid: !e.isValid)),
                                    child: Text(e.isValid ? 'Annuler' : 'Valider'),
                                  ),
                              ]),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPanel extends StatelessWidget {
  final String name;
  final String? logo;
  final bool enabled;
  final void Function(String jeu) onEvent;
  const _TeamPanel({required this.name, this.logo, required this.enabled, required this.onEvent});

  Widget _btn(String jeu) {
    final s = eventStyle(jeu);
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(foregroundColor: s.color, side: BorderSide(color: s.color.withAlpha(90)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      onPressed: enabled ? () => onEvent(jeu) : null,
      icon: Icon(s.icon, size: 18),
      label: Text(GameEventType.label(jeu)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AppAvatar(name: name, imageUrl: logo, size: 36, rounded: true),
            const SizedBox(width: 10),
            Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final j in GameEventType.primary) _btn(j)]),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Statistiques de jeu', style: TextStyle(fontWeight: FontWeight.w700)),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, runSpacing: 8, children: [for (final j in GameEventType.secondary) _btn(j)]),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
