import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../notifications/application/notifications_providers.dart';
import '../nav_model.dart';
import '../../../../shared/widgets/app_avatar.dart';

/// Cross-module menu mirroring the legacy sidebar groups (Matchs, Compétitions,
/// Équipes, Utilisateurs, Admin): a jump point to every domain that doesn't get
/// its own primary nav slot.
class MoreMenuScreen extends ConsumerWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final unreadCount = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    final tabRoutes = mobileTabs.map((t) => t.route).toSet();
    final groups = <_MenuGroup>[
      for (final g in buildNavGroups(isAdmin: isAdmin))
        if (g.title != null)
          _MenuGroup(g.title!, [
            for (final i in g.items)
              if (!tabRoutes.contains(i.route)) _MenuItem(i.label, i.icon, i.route, badge: i.badge ? unreadCount : 0),
          ]),
    ].where((g) => g.items.isNotEmpty).toList();
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: LayoutBuilder(builder: (context, constraints) {
        final columns = (constraints.maxWidth / 170).floor().clamp(2, 6);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null)
              Card(
                margin: const EdgeInsets.only(bottom: 20),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: AppAvatar(name: user.fullName, imageUrl: user.avatar, size: 48, rounded: true),
                  title: Text(user.fullName, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(user.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile'),
                ),
              ),
            for (final g in groups) ...[
              SectionHeader(title: g.title),
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [for (final i in g.items) _MenuTile(item: i)],
              ),
              const SizedBox(height: 20),
            ],
          ],
        );
      }),
    );
  }
}

class _MenuGroup {
  final String title;
  final List<_MenuItem> items;
  _MenuGroup(this.title, this.items);
}

class _MenuItem {
  final String label;
  final IconData icon;
  final String route;
  final int badge;
  _MenuItem(this.label, this.icon, this.route, {this.badge = 0});
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push(item.route),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: Icon(item.icon, size: 24, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(item.label, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (item.badge > 0)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 10,
                  backgroundColor: AppColors.error,
                  child: Text('${item.badge}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
