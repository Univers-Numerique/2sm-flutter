import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/activities/presentation/screens/activities_list_screen.dart';
import '../features/activities/presentation/screens/activity_detail_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/data/admin_config.dart';
import '../features/admin/data/models/plan.dart';
import '../features/admin/presentation/screens/admin_competitions_screen.dart';
import '../features/admin/presentation/screens/admin_fields_screen.dart';
import '../features/admin/presentation/screens/admin_manage_screen.dart';
import '../features/admin/presentation/screens/admin_plan_form_screen.dart';
import '../features/admin/presentation/screens/admin_plans_screen.dart';
import '../features/admin/presentation/screens/admin_teams_screen.dart';
import '../features/admin/presentation/screens/admin_users_screen.dart';
import '../features/auth/application/auth_provider.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/competitions/data/models/competition.dart';
import '../features/competitions/presentation/screens/competition_detail_screen.dart';
import '../features/competitions/presentation/screens/competition_selection_screen.dart';
import '../features/competitions/presentation/screens/create_competition_screen.dart';
import '../features/fields/data/models/field.dart';
import '../features/fields/presentation/screens/create_field_screen.dart';
import '../features/fields/presentation/screens/fields_list_screen.dart';
import '../features/home/presentation/screens/app_shell.dart';
import '../features/home/presentation/screens/more_menu_screen.dart';
import '../features/news/presentation/screens/news_feed_screen.dart';
import '../features/competitions/presentation/screens/competitions_list_screen.dart';
import '../features/matches/presentation/screens/matches_list_screen.dart';
import '../features/profile_settings/presentation/screens/profile_screen.dart';
import '../features/matches/data/models/match_game.dart';
import '../features/matches/presentation/screens/match_detail_screen.dart';
import '../features/matches/presentation/screens/match_live_console_screen.dart';
import '../features/matches/presentation/screens/schedule_match_screen.dart';
import '../features/messaging/data/models/message_participant.dart';
import '../features/messaging/presentation/screens/chat_screen.dart';
import '../features/messaging/presentation/screens/conversations_list_screen.dart';
import '../features/messaging/presentation/screens/create_conversation_screen.dart';
import '../features/news/data/models/news.dart';
import '../features/news/presentation/screens/compose_news_screen.dart';
import '../features/news/presentation/screens/news_detail_screen.dart';
import '../features/notifications/presentation/screens/notifications_list_screen.dart';
import '../features/profile_settings/presentation/screens/settings_screen.dart';
import '../features/teams/presentation/screens/create_team_screen.dart';
import '../features/teams/presentation/screens/team_detail_screen.dart';
import 'routes_activity.dart';
import 'routes_competition.dart';
import 'routes_people.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerRefreshProvider = Provider<GoRouterRefreshStream>((ref) {
  final stream = ref.watch(authNotifierProvider.notifier).stream;
  return GoRouterRefreshStream(stream);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (authState is AuthUnknown)
        return null; // splash while we restore session
      final authenticated = authState is AuthAuthenticated;

      if (!authenticated && !loggingIn) return '/login';
      if (authenticated && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const NewsFeedScreen(),
          ),
          GoRoute(
            path: '/competitions',
            builder: (context, state) => const CompetitionsListScreen(),
          ),
          GoRoute(
            path: '/matches',
            builder: (context, state) => const MatchesListScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreMenuScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // Teams
          GoRoute(
            path: '/teams/create',
            builder: (context, state) => const CreateTeamScreen(),
          ),
          GoRoute(
            path: '/teams/:id',
            builder: (context, state) => TeamDetailScreen(
              teamId: int.parse(state.pathParameters['id']!),
            ),
          ),

          // Competitions
          GoRoute(
            path: '/competitions/create',
            builder: (context, state) => CreateCompetitionScreen(
              competition: state.extra as Competition?,
            ),
          ),
          GoRoute(
            path: '/competitions/:id',
            builder: (context, state) => CompetitionDetailScreen(
              competitionId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/competitions/:id/teams/:teamId/selection',
            builder: (context, state) => CompetitionSelectionScreen(
              competitionId: int.parse(state.pathParameters['id']!),
              teamId: int.parse(state.pathParameters['teamId']!),
            ),
          ),

          // Fields
          GoRoute(
            path: '/fields',
            builder: (context, state) => const FieldsListScreen(),
          ),
          GoRoute(
            path: '/fields/create',
            builder: (context, state) =>
                CreateFieldScreen(field: state.extra as Field?),
          ),

          // Matches
          GoRoute(
            path: '/matches/create',
            builder: (context, state) => ScheduleMatchScreen(
              competitionId: state.extra is int ? state.extra as int : null,
            ),
          ),
          GoRoute(
            path: '/matches/friendly',
            builder: (context, state) =>
                const ScheduleMatchScreen(friendly: true),
          ),
          GoRoute(
            path: '/matches/:id',
            builder: (context, state) => MatchDetailScreen(
              matchId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/matches/:id/edit',
            builder: (context, state) =>
                ScheduleMatchScreen(existing: state.extra as MatchGame?),
          ),
          GoRoute(
            path: '/matches/:id/live',
            builder: (context, state) => MatchLiveConsoleScreen(
              matchId: int.parse(state.pathParameters['id']!),
            ),
          ),

          // Activities
          GoRoute(
            path: '/activities',
            builder: (context, state) => const ActivitiesListScreen(),
          ),
          GoRoute(
            path: '/activities/:id',
            builder: (context, state) => ActivityDetailScreen(
              activityId: int.parse(state.pathParameters['id']!),
            ),
          ),

          // News
          GoRoute(
            path: '/news/compose',
            builder: (context, state) =>
                ComposeNewsScreen(editing: state.extra as News?),
          ),
          GoRoute(
            path: '/news/:id',
            builder: (context, state) => NewsDetailScreen(
              newsId: int.parse(state.pathParameters['id']!),
            ),
          ),

          // Messaging
          GoRoute(
            path: '/messaging',
            builder: (context, state) => const ConversationsListScreen(),
          ),
          GoRoute(
            path: '/messaging/private/:userId',
            builder: (context, state) => ChatScreen(
              otherUserId: int.parse(state.pathParameters['userId']!),
              peer: state.extra is MessageParticipant
                  ? state.extra as MessageParticipant
                  : null,
            ),
          ),
          GoRoute(
            path: '/messaging/groups/create',
            builder: (context, state) => const CreateConversationScreen(),
          ),
          GoRoute(
            path: '/messaging/groups/:id',
            builder: (context, state) => ChatScreen(
              conversationId: int.parse(state.pathParameters['id']!),
            ),
          ),

          // Notifications
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsListScreen(),
          ),

          // Settings / Calendar / Admin
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/teams',
            builder: (context, state) => const AdminTeamsScreen(),
          ),
          GoRoute(
            path: '/admin/competitions',
            builder: (context, state) => const AdminCompetitionsScreen(),
          ),
          GoRoute(
            path: '/admin/fields',
            builder: (context, state) => const AdminFieldsScreen(),
          ),
          // Former "modération" screen: statuses are now edited per entity on /admin/manage/...
          GoRoute(
            path: '/admin/moderation',
            redirect: (context, state) => '/admin/teams',
          ),
          GoRoute(
            path: '/admin/plans',
            builder: (context, state) => const AdminPlansScreen(),
          ),
          GoRoute(
            path: '/admin/plans/new',
            builder: (context, state) => const AdminPlanFormScreen(),
          ),
          GoRoute(
            path: '/admin/plans/:id/edit',
            builder: (context, state) => AdminPlanFormScreen(
              planId: int.parse(state.pathParameters['id']!),
              plan: state.extra as Plan?,
            ),
          ),
          GoRoute(
            path: '/admin/manage/:table/:id',
            redirect: (context, state) =>
                AdminEntity.fromKey(state.pathParameters['table'] ?? '') == null
                ? '/admin'
                : null,
            builder: (context, state) => AdminManageScreen(
              entity: AdminEntity.fromKey(state.pathParameters['table']!)!,
              id: int.parse(state.pathParameters['id']!),
            ),
          ),

          // Per-domain route files (see routes_*.dart)
          ...peopleRoutes,
          ...competitionRoutes,
          ...activityRoutes,
        ],
      ),
    ],
  );
});

/// Bridges a Riverpod StateNotifier's stream into a [Listenable] so go_router
/// can re-evaluate `redirect` whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final Stream<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream();
    _subscription.listen((_) => notifyListeners());
  }
}
