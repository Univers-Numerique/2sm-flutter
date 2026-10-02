import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../matches/presentation/widgets/match_widgets.dart';
import '../../data/competition_extras_repository.dart';
import '../../data/models/competition_overview.dart';

/// Sélection d'une équipe pour une compétition (compte/selections.php) :
/// fiche équipe + responsable, liste des joueurs (sélectionnés en surbrillance),
/// bascule réservée au responsable tant que la sélection est ouverte.
class CompetitionSelectionScreen extends ConsumerStatefulWidget {
  final int competitionId;
  final int teamId;
  const CompetitionSelectionScreen({super.key, required this.competitionId, required this.teamId});

  @override
  ConsumerState<CompetitionSelectionScreen> createState() => _CompetitionSelectionScreenState();
}

class _CompetitionSelectionScreenState extends ConsumerState<CompetitionSelectionScreen> {
  Map<int, int> _override = {};
  int? _busy;

  ({int competitionId, int teamId}) get _args => (competitionId: widget.competitionId, teamId: widget.teamId);

  Future<void> _toggle(TeamSelectionPlayer p, int current) async {
    setState(() => _busy = p.id);
    try {
      await ref.read(competitionExtrasRepositoryProvider).setPlayerSelected(widget.competitionId, widget.teamId, p.id, current == 0);
      setState(() => _override = {..._override, p.id: current == 0 ? 1 : 0});
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(teamSelectionProvider(_args));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Sélection · ${info.valueOrNull?.teamName ?? 'Équipe'}')),
      body: info.when(
        loading: () => const SkeletonList(count: 5, itemHeight: 70),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(teamSelectionProvider(_args))),
        data: (i) {
          final canToggle = i.isOwner && i.selectionOpen;
          final selected = i.players.where((p) => (_override[p.id] ?? p.statut) == 1).length;
          return RefreshIndicator(
            onRefresh: () async {
              _override = {};
              ref.invalidate(teamSelectionProvider(_args));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HeroHeader(
                          title: i.teamName,
                          subtitle: i.teamLieu == null ? i.competitionName : 'Adresse : ${i.teamLieu}',
                          leading: AppAvatar(name: i.teamName, imageUrl: i.teamLogo, size: 56, rounded: true, border: Border.all(color: Colors.white24, width: 2)),
                          bottom: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              LabelBadge(label: i.competitionName, onDark: true, icon: Icons.emoji_events_outlined),
                              StatusBadge(
                                label: i.selectionOpen ? 'Sélection ouverte' : 'Sélection fermée',
                                color: i.selectionOpen ? AppColors.primaryLight : Colors.white70,
                                icon: i.selectionOpen ? Icons.lock_open_outlined : Icons.lock_outline,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SurfaceCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Responsable', style: text.titleMedium),
                              const SizedBox(height: 4),
                              InfoRow(icon: Icons.person_outline, label: 'Nom', value: i.responsable),
                              InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Téléphone',
                                child: i.telephone == null
                                    ? const Text('—')
                                    : InkWell(onTap: () => launchUrl(Uri.parse('tel:${i.telephone}')), child: Text(i.telephone!, style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600))),
                              ),
                              InfoRow(
                                icon: Icons.mail_outline,
                                label: 'Email',
                                child: i.email == null
                                    ? const Text('—')
                                    : InkWell(onTap: () => launchUrl(Uri.parse('mailto:${i.email}')), child: Text(i.email!, style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600))),
                              ),
                            ],
                          ),
                        ),
                        SectionHeader(title: 'Liste des sélections', subtitle: '$selected joueur(s) sélectionné(s) sur ${i.players.length}'),
                        if (i.isOwner && !i.selectionOpen)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: SurfaceCard(child: Text("La sélection est fermée : l'organisateur doit l'ouvrir pour la modifier.")),
                          ),
                        if (i.players.isEmpty) const EmptyState(icon: Icons.groups_outlined, title: 'Aucun joueur', message: "Cette équipe n'a pas encore de joueurs.") else
                        ResponsiveColumns(
                          spacing: 10,
                          children: [
                            for (final p in i.players)
                              Builder(builder: (_) {
                                final statut = _override[p.id] ?? p.statut;
                                return PersonTile(
                                  name: p.name,
                                  avatar: p.avatar,
                                  subtitle: [p.poste, if (p.age != null) '${p.age} ans'].whereType<String>().join(' | '),
                                  tint: statut == 1 ? AppColors.primary.withAlpha(20) : null,
                                  trailing: canToggle
                                      ? (_busy == p.id
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                          : IconButton(
                                              tooltip: statut == 1 ? 'Retirer de la sélection' : 'Sélectionner',
                                              icon: Icon(statut == 1 ? Icons.check_circle : Icons.add_circle_outline, color: statut == 1 ? AppColors.primary : AppColors.textTertiary),
                                              onPressed: () => _toggle(p, statut),
                                            ))
                                      : (statut == 1 ? const Icon(Icons.check_circle, color: AppColors.primary) : null),
                                );
                              }),
                          ],
                        ),
                      ],
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
