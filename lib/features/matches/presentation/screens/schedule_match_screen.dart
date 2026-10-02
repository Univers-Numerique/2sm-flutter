import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../competitions/data/competition_extras_repository.dart';
import '../../../fields/application/fields_providers.dart';
import '../../../teams/application/teams_providers.dart';
import '../../data/match_extras_repository.dart';
import '../../data/models/match_game.dart';
import '../widgets/match_widgets.dart';
import 'matches_list_screen.dart' show categoriesEquipe, genresEquipe;

typedef _Opt = ({int id, String name});

/// "Programmer un match" (compte/programmer-match.php), modification d'un
/// match à venir, et "Proposer un match amical" (proposer-un-match-amical.php,
/// [friendly] = true : hors compétition, l'équipe adverse reçoit une proposition).
class ScheduleMatchScreen extends ConsumerStatefulWidget {
  final MatchGame? existing;
  final int? competitionId;
  final bool friendly;
  const ScheduleMatchScreen({super.key, this.existing, this.competitionId, this.friendly = false});

  @override
  ConsumerState<ScheduleMatchScreen> createState() => _ScheduleMatchScreenState();
}

class _ScheduleMatchScreenState extends ConsumerState<ScheduleMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _home;
  int? _away;
  int _competition = 0;
  String? _categorie;
  String? _genre;
  int? _lieu;
  int _arbitre = 0, _touche1 = 0, _touche2 = 0, _comm1 = 0, _comm2 = 0, _chrono = 0, _annonceur = 0;
  DateTime? _date;
  TimeOfDay? _time;
  bool _loading = false;
  String? _error;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _competition = widget.friendly ? 0 : (m?.competitionId ?? widget.competitionId ?? 0);
    if (m != null) {
      _home = m.homeTeamId;
      _away = m.awayTeamId;
      _date = DateTime.tryParse(m.dateDebut ?? '');
      final p = (m.heureDebut ?? '').split(':');
      if (p.length >= 2) _time = TimeOfDay(hour: int.tryParse(p[0]) ?? 0, minute: int.tryParse(p[1]) ?? 0);
      _categorie = categoriesEquipe.contains(m.categorie) ? m.categorie : null;
      _genre = genresEquipe.contains(m.genre) ? m.genre : null;
      _lieu = m.lieu;
      _arbitre = m.arbitrePrincipalId ?? 0;
      _touche1 = m.arbitreTouche1Id ?? 0;
      _touche2 = m.arbitreTouche2Id ?? 0;
      _comm1 = m.commentateur1Id ?? 0;
      _comm2 = m.commentateur2Id ?? 0;
      _chrono = m.chronometreurId ?? 0;
      _annonceur = m.announcerId ?? 0;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _date == null || _time == null) {
      setState(() => _error = 'Renseignez les équipes, la date et l\'heure.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final saved = await ref.read(matchExtrasRepositoryProvider).save(MatchDraft(
            id: widget.existing?.id,
            homeTeamId: _home!,
            awayTeamId: _away!,
            dateDebut: apiDate(_date!),
            heureDebut: apiTime(_time!),
            competitionId: _competition,
            categorie: _categorie,
            genre: _genre,
            lieu: _lieu,
            arbitrePrincipal: _arbitre,
            arbitreTouche1: _touche1,
            arbitreTouche2: _touche2,
            commentateur1: _comm1,
            commentateur2: _comm2,
            chronometreur: _chrono,
            annonciateur: _annonceur,
          ));
      ref.invalidate(matchOverviewProvider(saved.id));
      if (_competition != 0) ref.invalidate(competitionOverviewProvider(_competition));
      if (!mounted) return;
      showSnack(context, widget.friendly ? "Proposition envoyée au responsable de l'équipe adverse." : (_editing ? 'Le match a été modifié.' : 'Le match a été programmé.'));
      context.pop();
    } on Failure catch (f) {
      setState(() => _error = f.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final uid = auth is AuthAuthenticated ? auth.user.id : -1;
    final allTeams = ref.watch(teamsListProvider).valueOrNull ?? const [];
    final fields = ref.watch(fieldsListProvider).valueOrNull ?? const [];
    final allCompetitions = ref.watch(allCompetitionsProvider).valueOrNull ?? const [];
    final overview = _competition != 0 ? ref.watch(competitionOverviewProvider(_competition)).valueOrNull : null;

    // Équipes proposées : celles de la compétition si elle est choisie ; en
    // match amical, mes équipes à domicile et toutes les autres à l'extérieur.
    List<_Opt> homeOpts;
    List<_Opt> awayOpts;
    if (widget.friendly) {
      homeOpts = [for (final t in allTeams.where((t) => t.isManagedBy(uid))) (id: t.id, name: t.nom)];
      awayOpts = [for (final t in allTeams.where((t) => !t.isManagedBy(uid))) (id: t.id, name: t.nom)];
    } else if (overview != null) {
      homeOpts = awayOpts = [for (final r in overview.classement) (id: r.teamId, name: r.nom)];
    } else {
      homeOpts = awayOpts = [for (final t in allTeams) (id: t.id, name: t.nom)];
    }
    final fieldOpts = overview != null && overview.terrains.isNotEmpty
        ? [for (final t in overview.terrains) (id: t.id, name: t.nomTerrain ?? 'Stade')]
        : [for (final f in fields) (id: f.id, name: f.nomTerrain)];

    _Opt? pick(List<_Opt> l, int? id) => l.where((o) => o.id == id).firstOrNull;

    List<_Opt> officials(String poste, String provPoste) {
      if (overview != null) {
        return [for (final p in overview.participants.where((p) => p.poste == poste)) (id: p.id, name: p.fullName)];
      }
      return ref.watch(officialsProvider(provPoste)).valueOrNull ?? const [];
    }

    final referees = officials('Arbitre', 'Arbitre');
    final commentators = officials('Commentateur', 'Commentateur');
    final timekeepers = officials('Chronométreur', 'Chronométreur');
    final announcers = officials('Annonceur Public', 'Annonceur Public');

    final title = widget.friendly ? 'Proposer un match amical' : (_editing ? 'Modifier le match' : 'Programmer un match');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroHeader(
                      title: title,
                      subtitle: widget.friendly ? "Le responsable de l'équipe adverse devra accepter votre proposition." : 'Remplissez les informations du match.',
                      leading: Icon(widget.friendly ? Icons.handshake_outlined : Icons.sports_soccer, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _drop<int>(
                            label: 'Équipe domicile',
                            value: pick(homeOpts, _home)?.id,
                            items: {for (final o in homeOpts) o.id: o.name},
                            required: true,
                            onChanged: (v) => setState(() => _home = v),
                          ),
                          _drop<int>(
                            label: 'Équipe extérieur',
                            value: pick(awayOpts, _away)?.id,
                            items: {for (final o in awayOpts.where((o) => o.id != _home)) o.id: o.name},
                            required: true,
                            onChanged: (v) => setState(() => _away = v),
                          ),
                          if (!widget.friendly)
                            _drop<int>(
                              label: 'Type de match',
                              value: _competition == 0 || allCompetitions.any((c) => c.id == _competition) ? _competition : 0,
                              items: {0: 'Hors compétition', for (final c in allCompetitions) c.id: c.nom},
                              onChanged: (v) => setState(() {
                                _competition = v ?? 0;
                                _home = null;
                                _away = null;
                                _lieu = null;
                              }),
                            ),
                          _drop<String>(
                            label: "Catégorie d'équipe",
                            value: _categorie,
                            items: {for (final c in categoriesEquipe) c: c},
                            onChanged: (v) => setState(() => _categorie = v),
                          ),
                          _drop<String>(
                            label: 'Genre',
                            value: _genre,
                            items: {for (final g in genresEquipe) g: g},
                            onChanged: (v) => setState(() => _genre = v),
                          ),
                          _drop<int>(
                            label: 'Stade',
                            value: pick(fieldOpts, _lieu)?.id,
                            items: {for (final o in fieldOpts) o.id: o.name},
                            onChanged: (v) => setState(() => _lieu = v),
                          ),
                          const Divider(height: 28),
                          Text('Officiels du match', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 10),
                          _official('Arbitre principal', referees, _arbitre, (v) => setState(() => _arbitre = v)),
                          _official('Arbitre de touche 1', referees, _touche1, (v) => setState(() => _touche1 = v)),
                          _official('Arbitre de touche 2', referees, _touche2, (v) => setState(() => _touche2 = v)),
                          _official('Commentateur 1', commentators, _comm1, (v) => setState(() => _comm1 = v)),
                          _official('Commentateur 2', commentators, _comm2, (v) => setState(() => _comm2 = v)),
                          _official('Chronométreur', timekeepers, _chrono, (v) => setState(() => _chrono = v)),
                          _official('Annonceur public', announcers, _annonceur, (v) => setState(() => _annonceur = v)),
                          const Divider(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: _date ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                                    );
                                    if (d != null) setState(() => _date = d);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Date de début', suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
                                    child: Text(_date == null ? 'Choisir' : formatDateFr(apiDate(_date!))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () async {
                                    final t = await showTimePicker(context: context, initialTime: _time ?? const TimeOfDay(hour: 16, minute: 0));
                                    if (t != null) setState(() => _time = t);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Heure de début', suffixIcon: Icon(Icons.schedule, size: 18)),
                                    child: Text(_time == null ? 'Choisir' : apiTime(_time!)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_error != null)
                            Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: Text(_loading ? 'Enregistrement…' : (widget.friendly ? 'ENVOYER LA PROPOSITION' : (_editing ? 'ENREGISTRER' : 'PROGRAMMER LE MATCH'))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drop<T>({
    required String label,
    required T? value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        key: ValueKey('$label-$value-${items.length}'),
        initialValue: items.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [for (final e in items.entries) DropdownMenuItem<T>(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))],
        onChanged: onChanged,
        validator: required ? (v) => v == null ? 'Champ requis' : null : null,
      ),
    );
  }

  Widget _official(String label, List<_Opt> options, int value, ValueChanged<int> onChanged) {
    return _drop<int>(
      label: label,
      value: value == 0 || options.any((o) => o.id == value) ? value : 0,
      items: {0: 'Non assigné', for (final o in options) o.id: o.name},
      onChanged: (v) => onChanged(v ?? 0),
    );
  }
}
