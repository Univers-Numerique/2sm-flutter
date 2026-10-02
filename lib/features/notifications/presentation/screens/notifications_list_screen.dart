import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../social_common/social_utils.dart';
import '../../application/notifications_providers.dart';
import '../../data/models/app_notification.dart';
import '../../data/notifications_repository.dart';

/// Legacy `notifications.php`: "Tout marquer comme lu", unread first, each
/// notification expandable (photo, title, truncated content, time) and, for a
/// match proposition, Accepter / Refuser with the current proposition status.
class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  ConsumerState<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends ConsumerState<NotificationsListScreen> {
  int? _expanded;
  bool _unreadOnly = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _markAll() async {
    try {
      await ref.read(notificationsRepositoryProvider).markAllRead();
      ref.invalidate(unreadNotificationsCountProvider);
      _toast('Toutes vos notifications ont été marquées comme lues');
    } on Failure catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _toggle(AppNotification n) async {
    setState(() => _expanded = _expanded == n.id ? null : n.id);
    if (_expanded == n.id && !n.isRead) {
      try {
        await ref.read(notificationsRepositoryProvider).markRead(n.id);
        ref.invalidate(unreadNotificationsCountProvider);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: _unreadOnly ? 'Toutes' : 'Non lues',
            onPressed: () => setState(() => _unreadOnly = !_unreadOnly),
            icon: Icon(_unreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
          ),
          IconButton(tooltip: 'Tout marquer comme lu', onPressed: _markAll, icon: const Icon(Icons.done_all)),
        ],
      ),
      body: async.when(
        loading: () => const SkeletonList(count: 6, itemHeight: 84),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(notificationsListProvider)),
        data: (all) {
          final items = all.where((n) => !_unreadOnly || !n.isRead).toList()
            ..sort((a, b) {
              if (a.isRead != b.isRead) return a.isRead ? 1 : -1;
              return b.id.compareTo(a.id);
            });
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_off_outlined,
              title: _unreadOnly ? 'Aucune notification non lue' : 'Aucune notification',
              message: 'Vous êtes à jour.',
            );
          }
          final unread = all.where((n) => !n.isRead).length;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(unread == 0 ? 'Toutes vos notifications sont lues' : '$unread notification(s) non lue(s)')),
                      if (unread > 0) TextButton(onPressed: _markAll, child: const Text('Tout marquer comme lu')),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  for (final n in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _NotificationCard(notification: n, expanded: _expanded == n.id, onTap: () => _toggle(n)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

IconData _iconFor(AppNotification n) {
  if (n.idProposition != null) return Icons.sports_soccer;
  switch ((n.categorie ?? n.tables ?? '').toLowerCase()) {
    case 'match':
    case 'matchs':
      return Icons.sports_soccer;
    case 'actualites':
    case 'news':
      return Icons.newspaper_outlined;
    case 'message':
    case 'messages':
      return Icons.chat_bubble_outline;
    case 'activites':
    case 'activite':
      return Icons.event_outlined;
    default:
      return Icons.notifications_outlined;
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notification;
  final bool expanded;
  final VoidCallback onTap;
  const _NotificationCard({required this.notification, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    final text = Theme.of(context).textTheme;
    final body = stripHtml(n.contenu ?? n.contenuPublication ?? '');
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: n.isRead ? null : AppColors.primary.withAlpha(10),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (n.photo != null && n.photo!.isNotEmpty)
              AppAvatar(name: n.titre, imageUrl: n.photo, size: 42, rounded: true)
            else
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: AppColors.primary.withAlpha(24), borderRadius: BorderRadius.circular(12)),
                child: Icon(_iconFor(n), color: AppColors.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(n.titre, style: text.titleSmall?.copyWith(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (!n.isRead) Container(width: 9, height: 9, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                ]),
                const SizedBox(height: 2),
                Text(expanded ? body : truncateWords(body, 10), style: text.bodyMedium),
                const SizedBox(height: 4),
                Text(timeAgo(n.createdAt), style: text.bodySmall),
              ]),
            ),
            Icon(expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.textTertiary),
          ]),
          if (expanded) _ExpandedBody(notification: n),
        ]),
      ),
    );
  }
}

class _ExpandedBody extends ConsumerWidget {
  final AppNotification notification;
  const _ExpandedBody({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fresh copy from `GET /notifications/{id}` (embeds the proposition).
    final fresh = ref.watch(notificationDetailProvider(notification.id));
    final n = fresh.valueOrNull ?? notification;
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user.id : -1;
    final p = n.proposition;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Divider(height: 1),
        const SizedBox(height: 12),
        if (p != null) _PropositionBlock(proposition: p, me: me, onDone: () => ref.invalidate(notificationDetailProvider(n.id))),
        if (n.lien != null && n.lien!.isNotEmpty && p == null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                final route = _routeFor(n.lien!);
                if (route != null) context.push(route);
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Voir'),
            ),
          ),
      ]),
    );
  }

  String? _routeFor(String lien) {
    final m = RegExp(r'/(matchs?|actualites?|competitions?|activites?)/(\d+)').firstMatch(lien);
    if (m == null) return null;
    final id = m.group(2);
    switch (m.group(1)) {
      case 'match':
      case 'matchs':
        return '/matches/$id';
      case 'actualite':
      case 'actualites':
        return '/news/$id';
      case 'competition':
      case 'competitions':
        return '/competitions/$id';
      case 'activite':
      case 'activites':
        return '/activities/$id';
    }
    return null;
  }
}

class _PropositionBlock extends ConsumerStatefulWidget {
  final NotificationProposition proposition;
  final int me;
  final VoidCallback onDone;
  const _PropositionBlock({required this.proposition, required this.me, required this.onDone});

  @override
  ConsumerState<_PropositionBlock> createState() => _PropositionBlockState();
}

class _PropositionBlockState extends ConsumerState<_PropositionBlock> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref.read(notificationsRepositoryProvider).respondToProposition(widget.proposition.id, accept: accept);
      widget.onDone();
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action impossible.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _alert(String label, Color color) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(12)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.proposition;
    const statutLabel = ['est en attente', 'a été acceptée', 'a été refusée'];
    const colors = [AppColors.info, AppColors.success, AppColors.error];
    final s = p.statut.clamp(0, 2);
    final children = <Widget>[];

    if (p.proposerId == widget.me) {
      children.add(_alert('Votre proposition ${statutLabel[s]}.', colors[s]));
    }
    if (p.proposedId == widget.me) {
      if (p.statut == 1) children.add(_alert('Vous avez accepté ce match.', AppColors.success));
      if (p.statut == 2) children.add(_alert('Vous avez refusé ce match.', AppColors.error));
      children.add(const SizedBox(height: 10));
      children.add(const Text('Veuillez cliquer sur Accepter pour confirmer votre participation.'));
      children.add(const SizedBox(height: 10));
      children.add(Row(children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy || p.statut == 1 ? null : () => _answer(true),
            icon: const Icon(Icons.check),
            label: const Text('Accepter'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy || p.statut == 2 ? null : () => _answer(false),
            icon: const Icon(Icons.close),
            label: const Text('Refuser'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          ),
        ),
      ]));
    }
    if (children.isEmpty) children.add(_alert('Cette proposition ${statutLabel[s]}.', colors[s]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
