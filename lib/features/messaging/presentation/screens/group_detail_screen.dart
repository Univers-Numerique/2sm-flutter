import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../social_common/social_utils.dart';
import '../../application/messaging_providers.dart';
import '../../data/conversations_repository.dart';
import '../../data/models/conversation.dart';
import 'conversations_list_screen.dart' show UserPickerSheet;

/// Legacy `details-conversation.php`: group card (photo, subject + type,
/// members strip, description, age) with Mettre à jour / Intégrer / Quitter /
/// Messages, and the member list with owner actions (Nommer Admin, Retirer,
/// Ajouter un participant). Data comes from `GET /conversations/{id}`.
class GroupDetailScreen extends ConsumerWidget {
  final int conversationId;
  const GroupDetailScreen({super.key, required this.conversationId});

  void _reload(WidgetRef ref) {
    ref.invalidate(conversationDetailProvider(conversationId));
    ref.invalidate(myConversationsProvider);
    ref.invalidate(groupDirectoryProvider);
  }

  Future<void> _run(BuildContext context, WidgetRef ref, Future<void> Function() action, {String? ok}) async {
    try {
      await action();
      _reload(ref);
      if (ok != null && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    } on Failure catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(conversationDetailProvider(conversationId));
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user.id : -1;
    final repo = ref.read(conversationsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Groupe de discussion'), actions: [
        IconButton(onPressed: () => _reload(ref), icon: const Icon(Icons.refresh)),
      ]),
      body: async.when(
        loading: () => const SkeletonList(count: 3, itemHeight: 160),
        error: (e, _) => ErrorState(error: e, onRetry: () => _reload(ref)),
        data: (g) {
          final isOwner = g.ownerId == me;
          final isAdmin = isOwner || g.isAdminMember;
          final members = (g.users ?? const <ConversationMember>[]).where((m) => m.statut != 0).toList();
          final isMember = g.isMember;
          final text = Theme.of(context).textTheme;

          final card = SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppCover(imageUrl: g.photo, height: 170, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(g.sujet ?? 'Groupe', style: text.titleLarge)),
                    if ((g.type ?? '').isNotEmpty)
                      StatusBadge(label: g.type![0].toUpperCase() + g.type!.substring(1), color: g.isPublic ? AppColors.success : AppColors.warning, icon: g.isPublic ? Icons.public : Icons.lock_outline),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: Row(children: [
                      for (final m in members.take(5))
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: AppAvatar(name: m.fullName, imageUrl: m.avatar, size: 32),
                        ),
                      if (members.length > 5)
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
                          child: Text('+${members.length - 5}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                    ]),
                  ),
                  if ((g.description ?? '').isNotEmpty) ...[const SizedBox(height: 12), Text(g.description!, style: text.bodyLarge)],
                  const SizedBox(height: 6),
                  Text('Créé ${timeAgo(g.createdAt)}${g.owner != null ? ' par ${g.owner!.fullName}' : ''}', style: text.bodySmall),
                  const SizedBox(height: 16),
                  if (isOwner)
                    OutlinedButton.icon(
                      onPressed: () => context.push('/messaging/groups/${g.id}/edit', extra: g).then((_) => _reload(ref)),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Mettre à jour'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    ),
                  if (isMember) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => context.push('/messaging/groups/${g.id}'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Messages'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46), backgroundColor: AppColors.info),
                    ),
                  ],
                  if (!isOwner) ...[
                    const SizedBox(height: 8),
                    isMember
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Quitter ce groupe ?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitter')),
                                  ],
                                ),
                              );
                              if (ok == true && context.mounted) await _run(context, ref, () => repo.leave(g.id), ok: 'Vous avez quitté le groupe');
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Quitter ce groupe'),
                            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), foregroundColor: AppColors.error),
                          )
                        : FilledButton.icon(
                            onPressed: () => _run(context, ref, () => repo.join(g.id), ok: 'Vous avez rejoint le groupe'),
                            icon: const Icon(Icons.login),
                            label: const Text('Intégrer ce groupe'),
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                          ),
                  ],
                ]),
              ),
            ]),
          );

          final membersCard = SurfaceCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Membres (${members.length})', style: text.titleLarge)),
                if (isAdmin)
                  FilledButton.icon(
                    onPressed: () async {
                      final user = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => const UserPickerSheet(),
                      );
                      if (user != null && context.mounted) {
                        await _run(context, ref, () => repo.addUser(g.id, user.id as int), ok: 'Participant ajouté');
                      }
                    },
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Ajouter un participant'),
                  ),
              ]),
              const SizedBox(height: 8),
              if (members.isEmpty)
                const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aucun membre')))
              else
                for (final m in members)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      AppAvatar(name: m.fullName, imageUrl: m.avatar, size: 46, rounded: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.id == g.ownerId ? '${m.fullName} (créateur)' : m.fullName, style: text.titleSmall),
                          Text(m.id == g.ownerId ? 'Administrateur' : m.statutLabel, style: text.bodySmall),
                        ]),
                      ),
                      if (isAdmin && m.id != g.ownerId && m.id != me) ...[
                        if (m.statut != 2)
                          TextButton(
                            onPressed: () => _run(context, ref, () => repo.setMemberStatus(g.id, m.id, 2), ok: '${m.fullName} est administrateur'),
                            child: const Text('Nommer Admin'),
                          ),
                        TextButton(
                          onPressed: () => _run(context, ref, () => repo.setMemberStatus(g.id, m.id, 0), ok: '${m.fullName} a été retiré'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Retirer'),
                        ),
                      ],
                    ]),
                  ),
            ]),
          );

          return LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 900;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 380, child: card),
                    const SizedBox(width: 16),
                    Expanded(child: membersCard),
                  ])
                else ...[card, const SizedBox(height: 16), membersCard],
              ],
            );
          });
        },
      ),
    );
  }
}
