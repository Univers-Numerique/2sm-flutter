import 'package:go_router/go_router.dart';

import '../features/competitions/presentation/screens/competition_resources_screen.dart';
import '../features/media/presentation/media_gallery.dart';
import '../features/propositions/presentation/propositions_screen.dart';
import '../features/rankings/presentation/rankings_screen.dart';

/// Extra routes for the "competition" domain. Kept in their own file so parallel work
/// on different domains never edits the same lines of app_router.dart.
final List<RouteBase> competitionRoutes = <RouteBase>[
  // Classements de toutes les compétitions (compte/classements.php)
  GoRoute(path: '/rankings', builder: (context, state) => const RankingsScreen()),
  // Propositions de matchs amicaux (liste + accepter/refuser)
  GoRoute(path: '/propositions', builder: (context, state) => const PropositionsScreen()),
  // Galerie / upload de photos d'un match (compte/media.php)
  GoRoute(
    path: '/matches/:id/media',
    builder: (context, state) => MatchMediaScreen(matchId: int.parse(state.pathParameters['id']!)),
  ),
  // Ajouter participants / équipes / stades à une compétition
  GoRoute(
    path: '/competitions/:id/resources/:type',
    builder: (context, state) => CompetitionResourcesScreen(
      competitionId: int.parse(state.pathParameters['id']!),
      type: state.pathParameters['type']!,
    ),
  ),
];
