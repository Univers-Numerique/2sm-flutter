import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../players/application/players_providers.dart';
import '../../../players/data/football_constants.dart';
import '../../../players/data/models/player.dart';
import '../../../players/data/players_repository.dart';
import '../../../players/presentation/widgets/people_widgets.dart';
import '../../application/teams_providers.dart';
import '../../data/models/team.dart';
import '../../data/models/team_member.dart';
import '../../data/teams_repository.dart';

const _perPage = 15;

/// "Gestion des membres" — port of `compte/mon-equipe.php` /
/// `manage/equipes/membres.php`: filters (catégorie / genre / nom), member
/// cards with Buts / Passes / Cartons, "Voir", and (manager) "Retirer".
class TeamMembersTab extends ConsumerStatefulWidget {
  final Team team;
  final bool isManager;
  const TeamMembersTab({super.key, required this.team, required this.isManager});

  @override
  ConsumerState<TeamMembersTab> createState() => _TeamMembersTabState();
}

class _TeamMembersTabState extends ConsumerState<TeamMembersTab> {
  String _search = '';
  String? _genre;
  String? _categorie;
  int _page = 1;

  Future<void> _remove(TeamMember m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text('${m.fullName} sera retiré de ${widget.team.nom}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.error), onPressed: () => Navigator.pop(context, true), child: const Text('Retirer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teamsRepositoryProvider).removeMember(widget.team.id, m.userId);
      ref.invalidate(teamDetailProvider(widget.team.id));
      ref.invalidate(teamMembersProvider(widget.team.id));
      ref.invalidate(teamMemberStatsProvider(widget.team.id));
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(teamDetailProvider(widget.team.id));
    final stats = ref.watch(teamMemberStatsProvider(widget.team.id)).valueOrNull ?? const MemberStatsBundle();
    final members = detail.valueOrNull?.members ?? widget.team.members;

    var list = members.where((m) {
      if (_search.isNotEmpty && !m.fullName.toLowerCase().contains(_search.toLowerCase())) return false;
      if (_genre != null && m.genre != _genre) return false;
      if (_categorie != null && m.categorie != _categorie) return false;
      return true;
    }).toList()
      ..sort((a, b) => (a.nom ?? '').toLowerCase().compareTo((b.nom ?? '').toLowerCase()));

    final lastPage = (list.length / _perPage).ceil().clamp(1, 999);
    final page = _page.clamp(1, lastPage);
    final shown = list.skip((page - 1) * _perPage).take(_perPage).toList();

    return PageBody(
      onRefresh: () async {
        ref.invalidate(teamDetailProvider(widget.team.id));
        ref.invalidate(teamMemberStatsProvider(widget.team.id));
      },
      children: [
        SurfaceCard(
          child: PeopleFilters(
            search: _search,
            genre: _genre,
            categorie: _categorie,
            onSearch: (v) => setState(() {
              _search = v;
              _page = 1;
            }),
            onGenre: (v) => setState(() {
              _genre = v;
              _page = 1;
            }),
            onCategorie: (v) => setState(() {
              _categorie = v;
              _page = 1;
            }),
          ),
        ),
        SectionHeader(
          title: '${list.length} membre${list.length > 1 ? 's' : ''}',
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
          trailing: widget.isManager
              ? OutlinedButton.icon(
                  onPressed: () => showCreateMemberDialog(context, ref, widget.team),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                  label: const Text('Créer un membre'),
                )
              : null,
        ),
        if (detail.isLoading && members.isEmpty)
          Column(children: [for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBox(height: 240, radius: 20))])
        else if (shown.isEmpty)
          const EmptyState(icon: Icons.group_off_outlined, title: 'Aucun membre', message: 'Aucun membre ne correspond à votre recherche.')
        else
          CardGrid(children: [
            for (final m in shown)
              PersonCard(
                name: m.fullName.isEmpty ? 'Membre #${m.userId}' : m.fullName,
                avatar: m.avatar,
                poste: m.poste,
                categorie: m.categorie,
                age: m.age,
                genre: m.genre,
                user: m.user,
                badge: m.userId == widget.team.ownerId ? 'Manager' : null,
                buts: stats.countersOf(m.userId).buts,
                passes: stats.countersOf(m.userId).passes,
                cartons: stats.countersOf(m.userId).cartons,
                actions: [
                  if (widget.isManager && m.userId != widget.team.ownerId)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () => _remove(m),
                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                      label: const Text('Retirer'),
                    ),
                  FilledButton.icon(
                    onPressed: () => context.push('/users/${m.userId}'),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Voir'),
                  ),
                ],
              ),
          ]),
        PagerBar(page: page, lastPage: lastPage, onPage: (p) => setState(() => _page = p)),
      ],
    );
  }
}

/// "Ajouter un membre" — port of `compte/ajouter-un-membre.php`: directory of
/// users who are not yet in the team (`GET /users`), with genre + name
/// filters and an "Intégrer à mon équipe" action.
class TeamAddMemberTab extends ConsumerStatefulWidget {
  final Team team;
  const TeamAddMemberTab({super.key, required this.team});

  @override
  ConsumerState<TeamAddMemberTab> createState() => _TeamAddMemberTabState();
}

class _TeamAddMemberTabState extends ConsumerState<TeamAddMemberTab> {
  String _search = '';
  String? _genre;
  int _page = 1;

  UserQuery get _query => UserQuery(search: _search, genre: _genre, page: _page);

  Future<void> _integrate(PlayerUser u) async {
    String type = 'Joueurs';
    String poste = 'Attaquant';
    String? categorie = 'Senior';
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Intégrer ${u.fullName}', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type de poste'),
                items: [for (final k in kPostesFootball.keys) DropdownMenuItem(value: k, child: Text(k))],
                onChanged: (v) => setSheet(() {
                  type = v!;
                  poste = kPostesFootball[v]!.first;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(type),
                initialValue: poste,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Poste'),
                items: [for (final p in kPostesFootball[type]!) DropdownMenuItem(value: p, child: Text(p))],
                onChanged: (v) => setSheet(() => poste = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: categorie,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: [for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setSheet(() => categorie = v),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.person_add_alt_1), label: const Text('Intégrer à mon équipe')),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teamsRepositoryProvider).addMember(widget.team.id, u.id, poste: poste, categorie: categorie, type: type);
      ref.invalidate(teamDetailProvider(widget.team.id));
      ref.invalidate(teamMembersProvider(widget.team.id));
      ref.invalidate(teamMemberStatsProvider(widget.team.id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${u.fullName} a rejoint ${widget.team.nom}.')));
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(usersPageProvider(_query));
    final memberIds = (ref.watch(teamDetailProvider(widget.team.id)).valueOrNull?.members ?? widget.team.members).map((m) => m.userId).toSet();

    return PageBody(
      onRefresh: () async => ref.invalidate(usersPageProvider(_query)),
      children: [
        SurfaceCard(
          child: PeopleFilters(
            search: _search,
            genre: _genre,
            showCategorie: false,
            categorie: null,
            onCategorie: (_) {},
            onSearch: (v) => setState(() {
              _search = v;
              _page = 1;
            }),
            onGenre: (v) => setState(() {
              _genre = v;
              _page = 1;
            }),
          ),
        ),
        const SizedBox(height: 12),
        pageAsync.when(
          loading: () => Column(children: [for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBox(height: 220, radius: 20))]),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(usersPageProvider(_query))),
          data: (page) {
            final candidates = page.users.where((u) => !memberIds.contains(u.id)).toList();
            if (candidates.isEmpty) {
              return const EmptyState(icon: Icons.person_search_outlined, title: 'Aucun utilisateur à ajouter', message: 'Tous les utilisateurs de cette page font déjà partie de votre équipe.');
            }
            return Column(children: [
              CardGrid(children: [
                for (final u in candidates)
                  PersonCard(
                    name: u.fullName,
                    avatar: u.avatar,
                    poste: u.mainPosition?.poste,
                    categorie: u.mainPosition?.categorie,
                    age: u.age,
                    genre: u.genre,
                    user: u,
                    onTap: () => context.push('/users/${u.id}'),
                    actions: [
                      FilledButton.icon(onPressed: () => _integrate(u), icon: const Icon(Icons.person_add_alt_1, size: 18), label: const Text('Intégrer à mon équipe')),
                    ],
                  ),
              ]),
              PagerBar(page: page.currentPage, lastPage: page.lastPage, onPage: (p) => setState(() => _page = p)),
            ]);
          },
        ),
      ],
    );
  }
}

/// "Créer un membre" modal (legacy `inscrireMembre()`): registers an account
/// with a temporary password and adds it to the team.
Future<void> showCreateMemberDialog(BuildContext context, WidgetRef ref, Team team) async {
  final prenoms = TextEditingController();
  final nom = TextEditingController();
  final email = TextEditingController();
  final tel = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String? categorie = 'Senior';
  bool busy = false;
  String? error;

  final password = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: const Text('Inscrire un membre'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: prenoms, decoration: const InputDecoration(labelText: 'Prénom'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
                const SizedBox(height: 10),
                TextFormField(controller: nom, decoration: const InputDecoration(labelText: 'Nom de famille'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
                const SizedBox(height: 10),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Adresse e-mail'),
                  validator: (v) => (v ?? '').contains('@') ? null : 'E-mail invalide',
                ),
                const SizedBox(height: 10),
                TextFormField(controller: tel, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numéro de téléphone'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  initialValue: categorie,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) => categorie = v,
                ),
                if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: AppColors.error))),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(ctx), child: const Text('Fermer')),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setD(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      final pass = await ref.read(teamsRepositoryProvider).createMember(
                            team.id,
                            nom: nom.text.trim(),
                            prenoms: prenoms.text.trim(),
                            email: email.text.trim(),
                            telephone: tel.text.trim(),
                            categorie: categorie,
                          );
                      if (ctx.mounted) Navigator.pop(ctx, pass);
                    } on Failure catch (e) {
                      setD(() {
                        busy = false;
                        error = e.message;
                      });
                    }
                  },
            child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  for (final c in [prenoms, nom, email, tel]) {
    c.dispose();
  }
  if (password != null && context.mounted) {
    ref.invalidate(teamDetailProvider(team.id));
    ref.invalidate(teamMembersProvider(team.id));
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inscription réussie'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Le membre a été ajouté avec succès. Communiquez-lui ce mot de passe temporaire :'),
          const SizedBox(height: 12),
          SelectableText(password, style: Theme.of(ctx).textTheme.headlineSmall),
        ]),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}
