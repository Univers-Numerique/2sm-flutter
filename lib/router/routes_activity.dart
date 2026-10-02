import 'package:go_router/go_router.dart';

import '../features/messaging/data/models/conversation.dart';
import '../features/messaging/presentation/screens/create_conversation_screen.dart';
import '../features/messaging/presentation/screens/group_detail_screen.dart';
import '../features/messaging/presentation/screens/group_directory_screen.dart';
import '../features/profile_settings/presentation/screens/change_password_screen.dart';
import '../features/profile_settings/presentation/screens/contact_change_screen.dart';

/// Extra routes for the "activity" domain (activities, news, messaging,
/// notifications, settings). Kept in their own file so parallel work on
/// different domains never edits the same lines of app_router.dart.
final List<RouteBase> activityRoutes = <RouteBase>[
  // Messaging: directory of groups, group detail (members, join/leave, admin
  // actions) and group edit.
  GoRoute(path: '/messaging/directory', builder: (context, state) => const GroupDirectoryScreen()),
  GoRoute(
    path: '/messaging/groups/:id/details',
    builder: (context, state) => GroupDetailScreen(conversationId: int.parse(state.pathParameters['id']!)),
  ),
  GoRoute(
    path: '/messaging/groups/:id/edit',
    builder: (context, state) => CreateConversationScreen(existing: state.extra is Conversation ? state.extra as Conversation : null),
  ),

  // Settings sub-pages.
  GoRoute(path: '/settings/password', builder: (context, state) => const ChangePasswordScreen()),
  GoRoute(
    path: '/settings/contact/:type',
    builder: (context, state) => ContactChangeScreen(type: state.pathParameters['type'] == 'email' ? 'email' : 'telephone'),
  ),
];
