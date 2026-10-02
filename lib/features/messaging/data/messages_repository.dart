import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../../core/notifications/local_notifications_service.dart';
import 'models/group_message.dart';
import 'models/message.dart';
import 'models/message_participant.dart';
import 'models/message_thread.dart';

/// Private 1:1 messages are much more transient than the rest of the app's
/// cached entities — an open chat thread behaves like a live/paginated
/// view, not a flat list worth mirroring in the offline cache/outbox. This
/// repository therefore does NOT extend [LocalFirstRepository]: it wraps
/// plain API calls with the app's standard [Failure] handling instead. A
/// later pass could add local caching for the last-seen page per peer if
/// offline support becomes a requirement here.
class MessagesRepository {
  final ApiClient _api;
  MessagesRepository(this._api);

  /// All private messages sent or received by the current user (paginated
  /// server-side; only the first page is fetched here for simplicity).
  ///
  /// When [currentUserId] is given, also fires a local notification for any
  /// message addressed to that user which wasn't already seen on a previous
  /// call — this repository isn't local-first cached (see the class doc
  /// comment), so "new" is tracked via a [SharedPreferences] watermark (the
  /// highest message id already notified) rather than by diffing against a
  /// cache, mirroring `NotificationsRepository._notifyNewItems`.
  Future<List<Message>> fetchAll({int page = 1, int? currentUserId}) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.messages,
        queryParameters: {'page': page},
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      final messages = data.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
      if (currentUserId != null) {
        await _notifyNewIncoming(messages, currentUserId);
      }
      return messages;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  static const _lastNotifiedMessageIdKey = 'messages_last_notified_id';

  Future<void> _notifyNewIncoming(List<Message> messages, int currentUserId) async {
    final incoming = messages.where((m) => m.receiverId == currentUserId).toList();
    if (incoming.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastNotifiedId = prefs.getInt(_lastNotifiedMessageIdKey);
    incoming.sort((a, b) => a.id.compareTo(b.id));
    final maxId = incoming.last.id;

    if (lastNotifiedId == null) {
      // First run: don't spam the user with their entire message history.
      await prefs.setInt(_lastNotifiedMessageIdKey, maxId);
      return;
    }

    for (final message in incoming) {
      if (message.id <= lastNotifiedId || message.isRead) continue;
      final senderName = message.sender?.fullName;
      await LocalNotificationsService.instance.show(
        id: 100000 + message.id, // offset so ids never collide with notification ids
        title: (senderName != null && senderName.isNotEmpty) ? senderName : 'Nouveau message',
        body: message.message.length <= 140 ? message.message : '${message.message.substring(0, 140)}…',
      );
    }

    await prefs.setInt(_lastNotifiedMessageIdKey, maxId);
  }

  /// One entry per private contact: other user, last message, unread count
  /// (`GET /messages/threads`).
  Future<List<MessageThread>> threads({int? currentUserId}) async {
    try {
      final response = await _api.get<List<dynamic>>('${ApiConstants.messages}/threads');
      final list = (response.data ?? const []).map((e) => MessageThread.fromJson(e as Map<String, dynamic>)).toList();
      if (currentUserId != null) {
        await _notifyNewIncoming(list.map((t) => t.lastMessage).toList(), currentUserId);
      }
      return list;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// Full private conversation with [userId], oldest first.
  Future<List<Message>> thread(int userId) async {
    try {
      final response = await _api.get<List<dynamic>>('${ApiConstants.messages}/with/$userId');
      return (response.data ?? const []).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> markThreadRead(int userId) async {
    try {
      await _api.put('${ApiConstants.messages}/with/$userId/read');
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// `GET /messages/{id}` - a single message with sender/receiver.
  Future<Message> byId(int id) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(ApiConstants.messageById(id));
      return Message.fromJson(response.data!);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> markGroupRead(int conversationId) async {
    try {
      await _api.put('${ApiConstants.conversationById(conversationId)}/read');
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// Minimal user search for starting a private chat (`GET /users?search=`).
  Future<List<MessageParticipant>> searchUsers(String query) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(ApiConstants.users, queryParameters: {'search': query});
      final data = response.data?['data'] as List<dynamic>? ?? const [];
      return data.map((e) => MessageParticipant.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<Message> send({required int receiverId, required String message}) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.messages,
        data: {'id_destinataire': receiverId, 'message': message},
      );
      return Message.fromJson(response.data!);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> markRead(int messageId) async {
    try {
      await _api.put(ApiConstants.messageRead(messageId));
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// Group-chat messages for one conversation (`messages_conversation`,
  /// exposed once the Phase-0 backend gap was closed).
  Future<List<GroupMessage>> fetchGroupMessages(int conversationId) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(ApiConstants.conversationMessages(conversationId));
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data.map((e) => GroupMessage.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<GroupMessage> sendGroupMessage({required int conversationId, required String message}) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.conversationMessages(conversationId),
        data: {'message': message},
      );
      return GroupMessage.fromJson(response.data!);
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(ref.watch(apiClientProvider));
});
