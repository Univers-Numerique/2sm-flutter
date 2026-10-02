import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../application/players_providers.dart';
import '../../data/models/player.dart';
import '../../data/players_repository.dart';
import '../widgets/people_widgets.dart';

/// User directory — port of `compte/utilisateurs.php` (table with poste /
/// catégorie / genre / nom filters, 20 per page). Uses `GET /users`.
class UsersDirectoryScreen extends ConsumerStatefulWidget {
  const UsersDirectoryScreen({super.key});

  @override
  ConsumerState<UsersDirectoryScreen> createState() => _UsersDirectoryScreenState();
}

class _UsersDirectoryScreenState extends ConsumerState<UsersDirectoryScreen> {
  String _search = '';
  String? _genre;
  String? _categorie;
  String? _poste;
  int _page = 1;

  UserQuery get _query => UserQuery(search: _search, genre: _genre, categorie: _categorie, poste: _poste, page: _page);

  void _set(VoidCallback f) => setState(() {
        f();
        _page = 1;
      });

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(usersPageProvider(_query));
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Utilisateurs')),
      body: PageBody(
        onRefresh: () async => ref.invalidate(usersPageProvider(_query)),
        children: [
          HeroHeader(
            title: 'Annuaire des utilisateurs',
            subtitle: pageAsync.valueOrNull == null ? 'Joueurs, staff et supporters' : '${pageAsync.value!.total} membres inscrits',
            leading: const Icon(Icons.groups_2_outlined, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            child: PeopleFilters(
              search: _search,
              genre: _genre,
              categorie: _categorie,
              poste: _poste,
              showPoste: true,
              onSearch: (v) => _set(() => _search = v),
              onGenre: (v) => _set(() => _genre = v),
              onCategorie: (v) => _set(() => _categorie = v),
              onPoste: (v) => _set(() => _poste = v),
            ),
          ),
          const SizedBox(height: 12),
          pageAsync.when(
            loading: () => Column(children: [for (var i = 0; i < 5; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 84, radius: 20))]),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(usersPageProvider(_query))),
            data: (page) {
              if (page.users.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: EmptyState(icon: Icons.person_search_outlined, title: 'Aucun utilisateur trouvé', message: 'Modifiez vos filtres de recherche.'),
                );
              }
              return LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth >= 860;
                return Column(
                  children: [
                    if (wide) const _HeaderRow(),
                    for (final u in page.users) Padding(padding: const EdgeInsets.only(bottom: 10), child: wide ? _WideRow(user: u) : _NarrowRow(user: u)),
                    PagerBar(page: page.currentPage, lastPage: page.lastPage, onPage: (p) => setState(() => _page = p)),
                    Text('Page ${page.currentPage} sur ${page.lastPage}', textAlign: TextAlign.center, style: t.bodySmall),
                  ],
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary);
    Widget h(String l, int flex) => Expanded(flex: flex, child: Text(l, style: s));
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(children: [h('Utilisateur', 4), h('Catégorie', 2), h('Genre', 2), h('Âge', 1), h('Poste', 3), h('Équipe', 3), const SizedBox(width: 90)]),
    );
  }
}

Color _genreColor(String? g) => g == 'Masculin' ? AppColors.info : (g == null ? AppColors.textTertiary : AppColors.error);

class _WideRow extends StatelessWidget {
  final PlayerUser user;
  const _WideRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pos = user.mainPosition;
    return SurfaceCard(
      onTap: () => context.push('/users/${user.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(children: [
              AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.fullName, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(user.email ?? '', style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
          Expanded(flex: 2, child: Text(pos?.categorie ?? '—', style: t.bodyMedium)),
          Expanded(flex: 2, child: Text(user.genre ?? '—', style: t.bodyMedium?.copyWith(color: _genreColor(user.genre), fontWeight: FontWeight.w700))),
          Expanded(flex: 1, child: user.age == null ? const Text('—') : Align(alignment: Alignment.centerLeft, child: StatusBadge(label: '${user.age} ans'))),
          Expanded(flex: 3, child: Text(pos?.poste ?? '—', style: t.bodyMedium)),
          Expanded(flex: 3, child: _TeamCell(position: pos)),
          SizedBox(width: 90, child: FilledButton(onPressed: () => context.push('/users/${user.id}'), child: const Text('Infos'))),
        ],
      ),
    );
  }
}

class _TeamCell extends StatelessWidget {
  final PlayerPosition? position;
  const _TeamCell({required this.position});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (position?.teamName == null) return const Text('—');
    return Row(children: [
      AppAvatar(name: position!.teamName!, imageUrl: position!.teamLogo, size: 30, rounded: true),
      const SizedBox(width: 8),
      Expanded(child: Text(position!.teamName!, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _NarrowRow extends StatelessWidget {
  final PlayerUser user;
  const _NarrowRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pos = user.mainPosition;
    return SurfaceCard(
      onTap: () => context.push('/users/${user.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName, style: t.titleSmall),
                Text(user.email ?? '', style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (user.genre != null) StatusBadge(label: user.genre!, color: _genreColor(user.genre)),
            if (user.age != null) StatusBadge(label: '${user.age} ans'),
            if (pos?.categorie != null) StatusBadge(label: pos!.categorie!, color: AppColors.secondaryLight),
            if (pos?.poste != null) StatusBadge(label: pos!.poste!, color: AppColors.warning),
          ]),
          if (pos?.teamName != null) ...[
            const SizedBox(height: 10),
            _TeamCell(position: pos),
          ],
        ],
      ),
    );
  }
}
