import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../matches/presentation/widgets/match_widgets.dart';
import '../../data/competition_extras_repository.dart';
import '../../data/models/competition_overview.dart';

const _postesMatch = [
  'Arbitre',
  'Commentateur',
  'Chronométreur',
  'Annonceur Public',
  'Opérateur de Caméra',
  'Coordinateur des Médias',
];

/// Ajouter des ressources à une compétition (compte/ajouter-ressources-a-competition.php) :
/// `type` = utilisateurs (participants/officiels), equipes ou terrains (stades).
class CompetitionResourcesScreen extends ConsumerStatefulWidget {
  final int competitionId;
  final String type;
  const CompetitionResourcesScreen({super.key, required this.competitionId, required this.type});

  @override
  ConsumerState<CompetitionResourcesScreen> createState() => _CompetitionResourcesScreenState();
}

class _CompetitionResourcesScreenState extends ConsumerState<CompetitionResourcesScreen> {
  final _search = TextEditingController();
  String? _genre;
  String? _poste;
  List<CompetitionResource>? _items;
  Object? _error;
  bool _loading = true;
  int? _busyId;

  String get _title => switch (widget.type) {
        'utilisateurs' => 'Ajouter un participant',
        'equipes' => 'Ajouter une équipe',
        _ => 'Ajouter un stade',
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(competitionExtrasRepositoryProvider).resources(
            widget.competitionId,
            widget.type,
            nom: _search.text.trim(),
            genre: _genre,
            poste: _poste,
          );
      if (mounted) setState(() => _items = items);
    } on Failure catch (f) {
      if (mounted) setState(() => _error = f);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(CompetitionResource r) async {
    setState(() => _busyId = r.id);
    try {
      final linked = await ref.read(competitionExtrasRepositoryProvider).toggleResource(widget.competitionId, widget.type, r.id);
      ref.invalidate(competitionOverviewProvider(widget.competitionId));
      if (mounted) {
        setState(() => _items = [for (final x in _items!) x.id == r.id ? x.copyWith(linked: linked) : x]);
      }
    } on Failure catch (f) {
      if (mounted) showSnack(context, f.message, error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUsers = widget.type == 'utilisateurs';
    final isTeam = widget.type == 'equipes';
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _load),
                  ),
                ),
                if (isUsers) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _poste,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Poste'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Tous les postes')),
                            for (final p in _postesMatch) DropdownMenuItem(value: p, child: Text(p)),
                          ],
                          onChanged: (v) {
                            _poste = v;
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          initialValue: _genre,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Genre'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('Tous')),
                            DropdownMenuItem(value: 'Masculin', child: Text('Masculin')),
                            DropdownMenuItem(value: 'Féminin', child: Text('Féminin')),
                          ],
                          onChanged: (v) {
                            _genre = v;
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const SkeletonList(count: 6, itemHeight: 68)
                : _error != null
                    ? ErrorState(error: _error!, onRetry: _load)
                    : (_items ?? const []).isEmpty
                        ? const EmptyState(icon: Icons.search_off, title: 'Aucun résultat', message: 'Essayez une autre recherche.')
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                            children: [
                              ResponsiveColumns(
                                spacing: 10,
                                children: [
                                  for (final r in _items!)
                                    PersonTile(
                                      name: r.title,
                                      avatar: r.image,
                                      subtitle: r.subtitle,
                                      tint: r.linked ? AppColors.primary.withAlpha(18) : null,
                                      trailing: _busyId == r.id
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                          : r.linked
                                              ? OutlinedButton(
                                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                                  onPressed: () => _toggle(r),
                                                  child: const Text('Retirer'),
                                                )
                                              : FilledButton(onPressed: () => _toggle(r), child: Text(isTeam ? 'Ajouter' : 'Ajouter')),
                                    ),
                                ],
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
