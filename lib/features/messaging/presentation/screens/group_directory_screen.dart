import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../application/messaging_providers.dart';

/// Legacy `groupes-de-conversation.php`: "Groupes de discussion" directory
/// with search, asc/desc sort and a card per group ("En savoir plus").
class GroupDirectoryScreen extends ConsumerWidget {
  const GroupDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(groupDirectoryQueryProvider);
    final async = ref.watch(groupDirectoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Groupes de discussion')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/messaging/groups/create'),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Créer un groupe'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(hintText: 'Rechercher ici', prefixIcon: Icon(Icons.search), isDense: true),
                onSubmitted: (v) => ref.read(groupDirectoryQueryProvider.notifier).state = query.copyWith(search: v.trim()),
              ),
            ),
            const SizedBox(width: 8),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.arrow_upward, size: 16), label: Text('Croissant')),
                ButtonSegment(value: true, icon: Icon(Icons.arrow_downward, size: 16), label: Text('Décroissant')),
              ],
              selected: {query.descending},
              onSelectionChanged: (s) => ref.read(groupDirectoryQueryProvider.notifier).state = query.copyWith(descending: s.first),
            ),
          ]),
        ),
        Expanded(
          child: async.when(
            loading: () => const SkeletonList(count: 4, itemHeight: 200),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(groupDirectoryProvider)),
            data: (groups) {
              if (groups.isEmpty) return const EmptyState(icon: Icons.groups_outlined, title: 'Aucun groupe trouvé');
              return LayoutBuilder(builder: (context, c) {
                final cols = (c.maxWidth / 300).floor().clamp(1, 5);
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 300),
                  itemCount: groups.length,
                  itemBuilder: (_, i) {
                    final g = groups[i];
                    return SurfaceCard(
                      padding: EdgeInsets.zero,
                      onTap: () => context.push('/messaging/groups/${g.id}/details'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AppCover(imageUrl: g.photo, height: 120, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(g.sujet ?? 'Groupe', style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (g.isMember) const StatusBadge(label: 'Membre', color: AppColors.success),
                            ]),
                            const SizedBox(height: 4),
                            Text(g.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 8),
                            Row(children: [
                              if (g.owner != null) AppAvatar(name: g.owner!.fullName, imageUrl: g.owner!.avatar, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('Créé par ${g.owner?.fullName ?? '—'} • ${g.memberCount} membre(s)',
                                    style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ]),
                        ),
                      ]),
                    );
                  },
                );
              });
            },
          ),
        ),
      ]),
    );
  }
}
