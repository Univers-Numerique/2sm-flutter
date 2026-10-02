import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../social_common/social_utils.dart';
import '../../application/messaging_providers.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message_participant.dart';
import '../../data/models/message_thread.dart';
import 'chat_screen.dart';

/// Legacy `messagerie.php`: contacts card (search) + thread panel. Two panes
/// from 900px wide (contacts left, conversation right); on phones the list
/// pushes a full-screen chat.
class ConversationsListScreen extends ConsumerStatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  ConsumerState<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends ConsumerState<ConversationsListScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String _query = '';
  int? _selectedUser;
  int? _selectedGroup;
  MessageParticipant? _selectedPeer;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(messageThreadsProvider);
    ref.invalidate(myConversationsProvider);
  }

  void _openUser(MessageParticipant user, bool wide) {
    if (wide) {
      setState(() {
        _selectedUser = user.id;
        _selectedGroup = null;
        _selectedPeer = user;
      });
    } else {
      context.push('/messaging/private/${user.id}', extra: user).then((_) => _refresh());
    }
  }

  void _openGroup(int id, bool wide) {
    if (wide) {
      setState(() {
        _selectedGroup = id;
        _selectedUser = null;
      });
    } else {
      context.push('/messaging/groups/$id').then((_) => _refresh());
    }
  }

  Future<void> _newChat(bool wide) async {
    final user = await showModalBottomSheet<MessageParticipant>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const UserPickerSheet(),
    );
    if (user != null && mounted) _openUser(user, wide);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;
      final list = _ContactsPanel(
        tabs: _tabs,
        query: _query,
        onQuery: (v) => setState(() => _query = v.trim().toLowerCase()),
        selectedUser: _selectedUser,
        selectedGroup: _selectedGroup,
        onUser: (u) => _openUser(u, wide),
        onGroup: (id) => _openGroup(id, wide),
        onRefresh: _refresh,
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messagerie'),
          actions: [
            IconButton(tooltip: 'Groupes de discussion', onPressed: () => context.push('/messaging/directory'), icon: const Icon(Icons.travel_explore_outlined)),
            IconButton(tooltip: 'Créer un groupe', onPressed: () => context.push('/messaging/groups/create'), icon: const Icon(Icons.group_add_outlined)),
            IconButton(tooltip: 'Actualiser', onPressed: _refresh, icon: const Icon(Icons.refresh)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _newChat(wide),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Nouveau message'),
        ),
        body: wide
            ? Row(children: [
                SizedBox(width: 360, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedUser != null
                      ? ChatPane(key: ValueKey('u$_selectedUser'), otherUserId: _selectedUser, peer: _selectedPeer)
                      : _selectedGroup != null
                          ? ChatPane(key: ValueKey('g$_selectedGroup'), conversationId: _selectedGroup)
                          : const EmptyState(
                              icon: Icons.forum_outlined,
                              title: 'Sélectionnez une conversation',
                              message: 'Choisissez un contact ou un groupe dans la liste.',
                            ),
                ),
              ])
            : list,
      );
    });
  }
}

class _ContactsPanel extends ConsumerWidget {
  final TabController tabs;
  final String query;
  final ValueChanged<String> onQuery;
  final int? selectedUser;
  final int? selectedGroup;
  final ValueChanged<MessageParticipant> onUser;
  final ValueChanged<int> onGroup;
  final VoidCallback onRefresh;
  const _ContactsPanel({
    required this.tabs,
    required this.query,
    required this.onQuery,
    required this.selectedUser,
    required this.selectedGroup,
    required this.onUser,
    required this.onGroup,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threads = ref.watch(messageThreadsProvider);
    final groups = ref.watch(myConversationsProvider);
    final unreadPrivate = (threads.valueOrNull ?? const <MessageThread>[]).fold<int>(0, (a, t) => a + t.unreadCount);
    final unreadGroups = (groups.valueOrNull ?? const <Conversation>[]).fold<int>(0, (a, g) => a + g.unreadCount);

    Widget tab(String label, int unread) => Tab(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label),
            if (unread > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
        );

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: TextField(
          onChanged: onQuery,
          decoration: const InputDecoration(hintText: 'Rechercher...', prefixIcon: Icon(Icons.search), isDense: true),
        ),
      ),
      TabBar(controller: tabs, tabs: [tab('Messages privés', unreadPrivate), tab('Groupes', unreadGroups)]),
      Expanded(
        child: TabBarView(controller: tabs, children: [
          threads.when(
            loading: () => const SkeletonList(count: 6, itemHeight: 68),
            error: (e, _) => ErrorState(error: e, onRetry: onRefresh),
            data: (all) {
              final items = all.where((t) => query.isEmpty || t.user.fullName.toLowerCase().contains(query)).toList();
              if (items.isEmpty) {
                return const EmptyState(icon: Icons.mark_chat_unread_outlined, title: 'Aucune conversation', message: 'Démarrez une discussion avec le bouton « Nouveau message ».');
              }
              return RefreshIndicator(
                onRefresh: () async => onRefresh(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _ThreadTile(thread: items[i], selected: selectedUser == items[i].user.id, onTap: () => onUser(items[i].user)),
                ),
              );
            },
          ),
          groups.when(
            loading: () => const SkeletonList(count: 6, itemHeight: 68),
            error: (e, _) => ErrorState(error: e, onRetry: onRefresh),
            data: (all) {
              final items = all.where((g) => query.isEmpty || (g.sujet ?? '').toLowerCase().contains(query)).toList();
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'Aucun groupe',
                  message: 'Rejoignez ou créez un groupe de discussion.',
                  action: OutlinedButton.icon(
                    onPressed: () => context.push('/messaging/directory'),
                    icon: const Icon(Icons.travel_explore_outlined),
                    label: const Text('Parcourir les groupes'),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => onRefresh(),
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _GroupTile(group: items[i], selected: selectedGroup == items[i].id, onTap: () => onGroup(items[i].id)),
                ),
              );
            },
          ),
        ]),
      ),
    ]);
  }
}

class _ThreadTile extends StatelessWidget {
  final MessageThread thread;
  final bool selected;
  final VoidCallback onTap;
  const _ThreadTile({required this.thread, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadCount;
    return _Tile(
      avatar: AppAvatar(name: thread.user.fullName, imageUrl: thread.user.avatar, size: 48),
      title: thread.user.fullName,
      subtitle: thread.lastMessage.message,
      time: timeAgo(thread.lastMessage.createdAt),
      unread: unread,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Conversation group;
  final bool selected;
  final VoidCallback onTap;
  const _GroupTile({required this.group, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final last = group.lastMessage;
    return _Tile(
      avatar: AppAvatar(name: group.sujet ?? 'Groupe', imageUrl: group.photo, size: 48, rounded: true),
      title: group.sujet ?? 'Groupe',
      subtitle: last == null ? '${group.memberCount} participant(s)' : '${last.author?.prenoms ?? ''}: ${last.message}',
      time: last == null ? '' : timeAgo(last.createdAt),
      unread: group.unreadCount,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _Tile extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final bool selected;
  final VoidCallback onTap;
  const _Tile({required this.avatar, required this.title, required this.subtitle, required this.time, required this.unread, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.primary.withAlpha(20) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: text.titleSmall?.copyWith(fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(time, style: text.bodySmall?.copyWith(color: unread > 0 ? AppColors.primary : null, fontSize: 11)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(
                    child: Text(subtitle,
                        style: text.bodySmall?.copyWith(color: unread > 0 ? AppColors.textPrimary : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Bottom sheet to pick a user (`GET /users?search=`) for a new private chat.
class UserPickerSheet extends ConsumerStatefulWidget {
  const UserPickerSheet({super.key});

  @override
  ConsumerState<UserPickerSheet> createState() => UserPickerSheetState();
}

class UserPickerSheetState extends ConsumerState<UserPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final res = ref.watch(userSearchProvider(_q));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Rechercher un utilisateur', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
          ),
          Expanded(
            child: res.when(
              loading: () => const SkeletonList(count: 5, itemHeight: 60),
              error: (e, _) => ErrorState(error: e),
              data: (users) => users.isEmpty
                  ? const EmptyState(icon: Icons.person_search_outlined, title: 'Aucun utilisateur')
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: AppAvatar(name: users[i].fullName, imageUrl: users[i].avatar, size: 44),
                        title: Text(users[i].fullName),
                        onTap: () => Navigator.pop(context, users[i]),
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
