import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/models/app_notification.dart';
import '../data/notifications_repository.dart';

final notificationsListProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchAll();
});

final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  if (ref.watch(authNotifierProvider) is! AuthAuthenticated) return 0; // visiteur
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});

final notificationDetailProvider = FutureProvider.autoDispose.family<AppNotification, int>((ref, id) {
  return ref.watch(notificationsRepositoryProvider).fetchDetail(id);
});
