import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/conversations_repository.dart';
import '../data/messages_repository.dart';
import '../data/models/conversation.dart';
import '../data/models/group_message.dart';
import '../data/models/message.dart';
import '../data/models/message_participant.dart';
import '../data/models/message_thread.dart';

final conversationsListProvider = StreamProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(conversationsRepositoryProvider).watchAll();
});

/// Reads a single conversation back out of the local cache populated by
/// [conversationsListProvider] — there is no `GET /conversations/{id}` to
/// fetch it fresh (see ConversationsRepository.cachedById).
final conversationByIdProvider = FutureProvider.autoDispose.family<Conversation?, int>((ref, id) {
  // Ensure the list (and therefore the cache) has been loaded at least once.
  ref.watch(conversationsListProvider);
  return ref.watch(conversationsRepositoryProvider).cachedById(id);
});

/// All of the current user's private messages (both directions), newest
/// first. The conversations-list screen groups these client-side into
/// per-peer threads; the chat screen filters this same list down to one
/// peer. See MessagesRepository's doc comment for why this isn't
/// local-first cached like the rest of the app.
final privateMessagesProvider = FutureProvider.autoDispose<List<Message>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
  return ref.watch(messagesRepositoryProvider).fetchAll(currentUserId: currentUserId);
});

final chatThreadProvider = FutureProvider.autoDispose.family<List<Message>, int>((ref, otherUserId) async {
  final all = await ref.watch(privateMessagesProvider.future);
  final thread = all.where((m) => m.senderId == otherUserId || m.receiverId == otherUserId).toList();
  thread.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
  return thread;
});

/// Messages for one group conversation, oldest first.
final groupMessagesProvider = FutureProvider.autoDispose.family<List<GroupMessage>, int>((ref, conversationId) async {
  final messages = await ref.watch(messagesRepositoryProvider).fetchGroupMessages(conversationId);
  messages.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
  return messages;
});

/// Private contacts with last message + unread counter.
final messageThreadsProvider = FutureProvider.autoDispose<List<MessageThread>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final currentUserId = authState is AuthAuthenticated ? authState.user.id : null;
  return ref.watch(messagesRepositoryProvider).threads(currentUserId: currentUserId);
});

/// Full private thread with one user, oldest first.
final privateThreadProvider = FutureProvider.autoDispose.family<List<Message>, int>((ref, userId) {
  return ref.watch(messagesRepositoryProvider).thread(userId);
});

/// My groups from the API (fresh: includes unread counters / last message).
final myConversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(conversationsRepositoryProvider).mine();
});

/// `GET /conversations/{id}` - fresh group detail with its member list.
final conversationDetailProvider = FutureProvider.autoDispose.family<Conversation, int>((ref, id) {
  return ref.watch(conversationsRepositoryProvider).fetchDetail(id);
});

class GroupDirectoryQuery {
  final String search;
  final bool descending;
  const GroupDirectoryQuery({this.search = '', this.descending = false});
  GroupDirectoryQuery copyWith({String? search, bool? descending}) =>
      GroupDirectoryQuery(search: search ?? this.search, descending: descending ?? this.descending);
}

final groupDirectoryQueryProvider = StateProvider.autoDispose<GroupDirectoryQuery>((ref) => const GroupDirectoryQuery());

final groupDirectoryProvider = FutureProvider.autoDispose<List<Conversation>>((ref) {
  final q = ref.watch(groupDirectoryQueryProvider);
  return ref.watch(conversationsRepositoryProvider).discover(search: q.search, descending: q.descending);
});

final userSearchProvider = FutureProvider.autoDispose.family<List<MessageParticipant>, String>((ref, query) {
  return ref.watch(messagesRepositoryProvider).searchUsers(query);
});
