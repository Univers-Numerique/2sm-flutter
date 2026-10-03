import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_theme.dart';
import 'auth_provider.dart';

/// L'application se consulte sans compte : actualités, matchs, compétitions,
/// équipes, joueurs, terrains… La connexion n'est demandée qu'au moment
/// d'agir (publier, aimer, commenter, suivre, rejoindre, gérer) ou pour les
/// espaces personnels listés ici.
const _accountRoutes = [
  '/profile',
  '/settings',
  '/messaging',
  '/notifications',
  '/my-team',
  '/career',
  '/card',
  '/propositions',
  '/admin',
  '/news/compose',
  '/matches/create',
  '/matches/friendly',
];

/// Écrans de création ou de gestion, quel que soit l'objet (`/teams/create`,
/// `/matches/12/edit`, `/matches/12/live`, `/teams/3/add-member`…).
final _accountSegments = RegExp(r'/(create|edit|live|add-member|resources)(/|$)');

bool routeNeedsAccount(String location) {
  final path = Uri.parse(location).path;
  for (final r in _accountRoutes) {
    if (path == r || path.startsWith('$r/')) return true;
  }
  return _accountSegments.hasMatch(path);
}

/// Adresse de l'écran de connexion qui ramène ensuite sur [from].
String loginLocation({String? from}) =>
    from == null || from.isEmpty || from == '/' ? '/login' : Uri(path: '/login', queryParameters: {'from': from}).toString();

bool isSignedIn(WidgetRef ref) => ref.read(authNotifierProvider) is AuthAuthenticated;

/// À appeler avant toute action qui exige un compte. Connecté : renvoie true.
/// Visiteur : propose de se connecter ou de créer un compte, puis renvoie false
/// (l'action sera refaite après la connexion, sur la même page).
Future<bool> requireAccount(BuildContext context, WidgetRef ref, {String reason = 'continuer'}) async {
  if (isSignedIn(ref)) return true;
  final from = GoRouterState.of(context).uri.toString();
  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => _AccountSheet(reason: reason),
  );
  if (!context.mounted || choice == null) return false;
  if (choice == 'login') context.push(loginLocation(from: from));
  if (choice == 'register') context.push(Uri(path: '/register', queryParameters: {'from': from}).toString());
  return false;
}

class _AccountSheet extends StatelessWidget {
  final String reason;
  const _AccountSheet({required this.reason});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/branding/2sm-embleme.png', height: 52),
          const SizedBox(height: 16),
          Text('Connectez-vous pour $reason', textAlign: TextAlign.center, style: t.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Tout le monde peut consulter 2SM. Un compte gratuit permet de participer : publier, commenter, suivre, rejoindre une équipe…',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: () => Navigator.pop(context, 'login'), child: const Text('Se connecter')),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: () => Navigator.pop(context, 'register'), child: const Text('Créer un compte')),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard')),
        ]),
      ),
    );
  }
}
