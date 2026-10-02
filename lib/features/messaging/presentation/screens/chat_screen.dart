import 'dart:async';

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
import '../../data/messages_repository.dart';
import '../../data/models/message_participant.dart';

/// Full-screen wrapper around [ChatPane] (phones, or a deep link).
class ChatScreen extends StatelessWidget {
  final int? otherUserId;
  final int? conversationId;
  final MessageParticipant? peer;
  const ChatScreen({super.key, this.otherUserId, this.conversationId, this.peer})
      : assert((otherUserId == null) != (conversationId == null), 'Provide exactly one of otherUserId / conversationId');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: ChatPane(otherUserId: otherUserId, conversationId: conversationId, peer: peer, embedded: false)),
    );
  }
}

class _Bubble {
  final int id;
  final int senderId;
  final String? senderName;
  final String? senderAvatar;
  final String text;
  final DateTime? at;
  final bool read;
  _Bubble(this.id, this.senderId, this.senderName, this.senderAvatar, this.text, this.at, this.read);
}

/// Legacy `messagerie.php` thread panel: header with avatar / name, message
/// bubbles grouped by day, composer. Used embedded in the two-pane layout and
/// full screen on phones.
class ChatPane extends ConsumerStatefulWidget {
  final int? otherUserId;
  final int? conversationId;
  final MessageParticipant? peer;
  final bool embedded;
  const ChatPane({super.key, this.otherUserId, this.conversationId, this.peer, this.embedded = true});

  bool get isGroup => conversationId != null;

  @override
  ConsumerState<ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends ConsumerState<ChatPane> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  bool _sending = false;
  int _lastCount = -1;

  @override
  void initState() {
    super.initState();
    _markRead();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) => _refresh(silent: true));
  }

  @override
  void didUpdateWidget(covariant ChatPane old) {
    super.didUpdateWidget(old);
    if (old.otherUserId != widget.otherUserId || old.conversationId != widget.conversationId) {
      _lastCount = -1;
      _markRead();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _refresh({bool silent = false}) {
    if (widget.isGroup) {
      ref.invalidate(groupMessagesProvider(widget.conversationId!));
    } else {
      ref.invalidate(privateThreadProvider(widget.otherUserId!));
    }
  }

  Future<void> _markRead() async {
    try {
      final repo = ref.read(messagesRepositoryProvider);
      if (widget.isGroup) {
        await repo.markGroupRead(widget.conversationId!);
        ref.invalidate(myConversationsProvider);
      } else {
        await repo.markThreadRead(widget.otherUserId!);
        ref.invalidate(messageThreadsProvider);
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final txt = _input.text.trim();
    if (txt.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final repo = ref.read(messagesRepositoryProvider);
      if (widget.isGroup) {
        await repo.sendGroupMessage(conversationId: widget.conversationId!, message: txt);
      } else {
        await repo.send(receiverId: widget.otherUserId!, message: txt);
      }
      _input.clear();
      _refresh();
      ref.invalidate(messageThreadsProvider);
      ref.invalidate(myConversationsProvider);
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _showDetails(int messageId) async {
    try {
      final m = await ref.read(messagesRepositoryProvider).byId(messageId);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Détails du message', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            InfoRow(icon: Icons.person_outline, label: 'De', value: m.sender?.fullName),
            InfoRow(icon: Icons.person_pin_outlined, label: 'À', value: m.receiver?.fullName),
            InfoRow(icon: Icons.schedule, label: 'Envoyé', value: formatLongDate(m.createdAt)),
            InfoRow(icon: Icons.done_all, label: 'Statut', value: m.isRead ? 'Lu' : 'Non lu'),
          ]),
        ),
      );
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final me = auth is AuthAuthenticated ? auth.user.id : -1;

    late final AsyncValue<List<_Bubble>> bubbles;
    String title = '';
    String? subtitle;
    String? avatar;
    bool round = true;

    if (widget.isGroup) {
      final detail = ref.watch(conversationDetailProvider(widget.conversationId!)).valueOrNull;
      title = detail?.sujet ?? 'Groupe';
      subtitle = detail == null ? null : '${detail.memberCount} participant(s)';
      avatar = detail?.photo;
      round = false;
      bubbles = ref.watch(groupMessagesProvider(widget.conversationId!)).whenData((list) => [
            for (final m in list)
              _Bubble(m.id, m.authorId, m.author?.fullName, m.author?.avatar, m.message, parseApiDate(m.createdAt), true),
          ]);
    } else {
      final thread = ref.watch(privateThreadProvider(widget.otherUserId!));
      MessageParticipant? other = widget.peer;
      for (final m in thread.valueOrNull ?? const []) {
        other = m.senderId == widget.otherUserId ? m.sender : m.receiver;
        if (other != null) break;
      }
      title = other?.fullName.isNotEmpty == true ? other!.fullName : 'Utilisateur #${widget.otherUserId}';
      avatar = other?.avatar;
      subtitle = 'Message privé';
      bubbles = thread.whenData((list) => [
            for (final m in list) _Bubble(m.id, m.senderId, m.sender?.fullName, m.sender?.avatar, m.message, parseApiDate(m.createdAt), m.isRead),
          ]);
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(widget.embedded ? 16 : 4, 8, 8, 8),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            if (!widget.embedded) IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
            AppAvatar(name: title, imageUrl: avatar, size: 42, rounded: !round),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null) Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
            if (widget.isGroup)
              TextButton.icon(
                onPressed: () => context.push('/messaging/groups/${widget.conversationId}/details'),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Infos du groupe'),
              ),
            IconButton(tooltip: 'Actualiser', onPressed: _refresh, icon: const Icon(Icons.refresh)),
          ]),
        ),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: bubbles.when(
              loading: () => const SkeletonList(count: 4, itemHeight: 56),
              error: (e, _) => ErrorState(error: e, onRetry: _refresh),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(icon: Icons.chat_bubble_outline, title: 'Aucun message', message: 'Écrivez votre premier message ci-dessous.');
                }
                if (list.length != _lastCount) {
                  _lastCount = list.length;
                  _scrollToEnd();
                }
                return _MessageList(list: list, me: me, group: widget.isGroup, controller: _scroll, onLongPress: widget.isGroup ? null : _showDetails);
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Écrivez votre message...',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
            ),
          ]),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  final List<_Bubble> list;
  final int me;
  final bool group;
  final ScrollController controller;
  final void Function(int id)? onLongPress;
  const _MessageList({required this.list, required this.me, required this.group, required this.controller, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    DateTime? lastDay;
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      final day = m.at == null ? null : DateTime(m.at!.year, m.at!.month, m.at!.day);
      if (day != null && day != lastDay) {
        lastDay = day;
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(20)),
              child: Text(dayLabel(day), style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ),
        ));
      }
      final mine = m.senderId == me;
      final showAvatar = group && !mine && (i == list.length - 1 || list[i + 1].senderId != m.senderId);
      children.add(_BubbleRow(m: m, mine: mine, group: group, showAvatar: showAvatar, onLongPress: onLongPress));
    }
    return ListView(controller: controller, padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), children: children);
  }
}

class _BubbleRow extends StatelessWidget {
  final _Bubble m;
  final bool mine;
  final bool group;
  final bool showAvatar;
  final void Function(int id)? onLongPress;
  const _BubbleRow({required this.m, required this.mine, required this.group, required this.showAvatar, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width * 0.72;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW.clamp(220, 520)),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      decoration: BoxDecoration(
        gradient: mine ? AppColors.primaryGradient : null,
        color: mine ? null : AppColors.surface,
        border: mine ? null : Border.all(color: AppColors.border),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        if (group && !mine && (m.senderName ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(m.senderName!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        Text(m.text, style: TextStyle(color: mine ? Colors.white : AppColors.textPrimary, fontSize: 15, height: 1.3)),
        const SizedBox(height: 3),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(m.at == null ? '' : formatHour(m.at!), style: TextStyle(fontSize: 10.5, color: mine ? Colors.white70 : AppColors.textTertiary)),
          if (mine && !group) ...[
            const SizedBox(width: 4),
            Icon(m.read ? Icons.done_all : Icons.done, size: 13, color: m.read ? Colors.white : Colors.white70),
          ],
        ]),
      ]),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (group && !mine) SizedBox(width: 34, child: showAvatar ? AppAvatar(name: m.senderName ?? '?', imageUrl: m.senderAvatar, size: 28) : null),
          if (group && !mine) const SizedBox(width: 6),
          GestureDetector(onLongPress: onLongPress == null ? null : () => onLongPress!(m.id), child: bubble),
        ],
      ),
    );
  }
}

/// Provider-free helper so other screens can start a private chat.
Future<void> openPrivateChat(BuildContext context, WidgetRef ref, MessageParticipant user) async {
  ref.invalidate(messageThreadsProvider);
  context.push('/messaging/private/${user.id}', extra: user);
}

/// Convenience so callers don't need to import the repository provider.
ConversationsRepository conversationsRepo(WidgetRef ref) => ref.read(conversationsRepositoryProvider);
