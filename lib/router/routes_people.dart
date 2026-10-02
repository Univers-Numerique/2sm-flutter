import 'package:go_router/go_router.dart';

import '../features/players/presentation/screens/career_screen.dart';
import '../features/players/presentation/screens/membership_card_screen.dart';
import '../features/players/presentation/screens/player_profile_screen.dart';
import '../features/players/presentation/screens/users_directory_screen.dart';
import '../features/plans/presentation/screens/plans_screen.dart';
import '../features/teams/presentation/screens/my_team_screen.dart';
import '../features/teams/presentation/screens/team_detail_screen.dart';
import '../features/teams/presentation/screens/teams_list_screen.dart';

/// Extra routes for the "people" domain. Kept in their own file so parallel work
/// on different domains never edits the same lines of app_router.dart.
final List<RouteBase> peopleRoutes = <RouteBase>[
  // Teams
  GoRoute(path: '/teams', builder: (context, state) => const TeamsListScreen()),
  GoRoute(path: '/my-team', builder: (context, state) => const MyTeamScreen()),
  GoRoute(
    path: '/teams/:id/members',
    builder: (context, state) => TeamDetailScreen(teamId: int.parse(state.pathParameters['id']!), initialTab: TeamTab.members),
  ),
  GoRoute(
    path: '/teams/:id/add-member',
    builder: (context, state) => TeamDetailScreen(teamId: int.parse(state.pathParameters['id']!), initialTab: TeamTab.add),
  ),
  GoRoute(
    path: '/teams/:id/performances',
    builder: (context, state) => TeamDetailScreen(teamId: int.parse(state.pathParameters['id']!), initialTab: TeamTab.performances),
  ),

  // Users / players
  GoRoute(path: '/users', builder: (context, state) => const UsersDirectoryScreen()),
  GoRoute(
    path: '/users/:id',
    builder: (context, state) => PlayerProfileScreen(userId: int.parse(state.pathParameters['id']!)),
  ),
  GoRoute(
    path: '/users/:id/career',
    builder: (context, state) => CareerScreen(userId: int.parse(state.pathParameters['id']!)),
  ),
  GoRoute(path: '/career', builder: (context, state) => const CareerScreen()),
  GoRoute(path: '/card', builder: (context, state) => const MembershipCardScreen()),

  // Subscription plans (member-facing)
  GoRoute(path: '/plans', builder: (context, state) => const PlansScreen()),
];
