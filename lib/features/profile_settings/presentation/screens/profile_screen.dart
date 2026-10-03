import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../home/presentation/screens/more_menu_screen.dart';
import '../../../players/application/players_providers.dart';
import '../../../players/presentation/screens/player_profile_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';

/// Own profile (`compte/profil.php` + the tabs of `manage/utilisateurs/`):
/// the full player profile (details, skills, stats, team info) plus the
/// shortcuts that legacy exposed as tabs/buttons — Messagerie, Notifications,
/// Paramètres, Parcours, Carte de membre, Abonnements, Annuaire.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: SkeletonList(count: 3, itemHeight: 140));
    }
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), tooltip: 'Paramètres', onPressed: () => context.push('/settings')),
        ],
      ),
      body: PlayerProfileBody(
        userId: user.id,
        leadingActions: [
          FilledButton.tonalIcon(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const EditProfileScreen()));
              ref.invalidate(userDetailProvider(user.id));
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Modifier le profil'),
          ),
        ],
        trailing: [_Shortcuts(isAdmin: user.isAdmin)],
      ),
    );
  }
}

class _Shortcuts extends ConsumerWidget {
  final bool isAdmin;
  const _Shortcuts({required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget tile(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (color ?? AppColors.primary).withAlpha(24), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color ?? AppColors.primary),
          ),
          title: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          tile(Icons.route_outlined, 'Parcours', () => context.push('/career')),
          tile(Icons.badge_outlined, 'Carte de membre', () => context.push('/card')),
          tile(Icons.shield_outlined, 'Mon équipe', () => context.push('/my-team')),
          tile(Icons.groups_2_outlined, 'Annuaire des utilisateurs', () => context.push('/users')),
          tile(Icons.workspace_premium_outlined, 'Abonnements', () => context.push('/plans')),
          const Divider(height: 1),
          tile(Icons.chat_bubble_outline, 'Messagerie', () => context.push('/messaging')),
          tile(Icons.notifications_outlined, 'Notifications', () => context.push('/notifications')),
          tile(Icons.settings_outlined, 'Paramètres', () => context.push('/settings')),
          tile(Icons.lock_outline, 'Changer le mot de passe', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()))),
          tile(Icons.apps_outlined, 'Activités, terrains, calendrier…', () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MoreMenuScreen()))),
          const Divider(height: 1),
          tile(Icons.logout, 'Déconnexion', () async {
            await ref.read(authNotifierProvider.notifier).logout();
            if (context.mounted) context.go('/');
          }, color: AppColors.error),
        ],
      ),
    );
  }
}
