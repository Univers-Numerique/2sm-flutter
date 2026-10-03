import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../auth/application/auth_guard.dart';
import '../../../auth/application/auth_provider.dart';
import '../../../notifications/application/notifications_providers.dart';
import '../nav_model.dart';

const double _wideBreakpoint = 700;
const double _expandedBreakpoint = 1000;

/// Authenticated shell wrapped around every signed-in route (go_router
/// ShellRoute): a grouped sidebar on desktop (icon rail when narrow), five
/// bottom tabs on phones. Detail pages keep the sidebar on desktop and
/// replace the tab bar with a back button on phones.
class AppShell extends ConsumerStatefulWidget {
  final String location;
  final Widget child;
  const AppShell({super.key, required this.location, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(syncServiceProvider).syncNow());
  }

  void _go(String route) {
    if (widget.location != route) context.go(route);
  }

  Future<void> _openPalette(List<NavGroup> groups) async {
    final route = await showDialog<String>(context: context, builder: (_) => _CommandPalette(groups: groups));
    if (route != null && mounted) _go(route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final isAdmin = user?.isAdmin ?? false;
    final unread = ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;
    final syncStatus = ref.watch(syncStatusProvider).valueOrNull ?? SyncStatus.idle;
    final groups = buildNavGroups(isAdmin: isAdmin, isGuest: user == null);
    final width = MediaQuery.sizeOf(context).width;
    final content = Column(children: [
      _SyncBanner(status: syncStatus),
      Expanded(child: widget.child),
    ]);

    if (width >= _wideBreakpoint) {
      final active = activeNavItem(groups, widget.location);
      final expanded = width >= _expandedBreakpoint;
      final tabRoutes = <String>[for (final t in mobileTabs.where((t) => t.route != '/more')) t.route];
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () => _openPalette(groups),
          for (var i = 0; i < tabRoutes.length; i++)
            SingleActivator(_digit(i), control: true): () => _go(tabRoutes[i]),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(children: [
              _Sidebar(
                groups: groups,
                active: active,
                expanded: expanded,
                unread: unread,
                onSelect: _go,
                onSearch: () => _openPalette(groups),
              ),
              Expanded(child: content),
            ]),
          ),
        ),
      );
    }

    final tabIndex = mobileTabRoutes.indexOf(widget.location);
    return Scaffold(
      body: content,
      bottomNavigationBar: tabIndex < 0
          ? null
          : NavigationBar(
              selectedIndex: tabIndex,
              onDestinationSelected: (i) => _go(mobileTabRoutes[i]),
              destinations: [
                for (final t in mobileTabs)
                  NavigationDestination(
                    icon: t.route == '/more' && unread > 0
                        ? Badge.count(count: unread, child: Icon(t.icon))
                        : Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: t.label,
                  ),
              ],
            ),
    );
  }

  static LogicalKeyboardKey _digit(int i) => [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
      ][i];
}

class _Sidebar extends ConsumerWidget {
  final List<NavGroup> groups;
  final NavItem? active;
  final bool expanded;
  final int unread;
  final ValueChanged<String> onSelect;
  final VoidCallback onSearch;

  const _Sidebar({
    required this.groups,
    required this.active,
    required this.expanded,
    required this.unread,
    required this.onSelect,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final t = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 264 : 76,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(expanded ? 20 : 0, 18, expanded ? 20 : 0, 8),
            child: Image.asset(
              'assets/branding/2sm-embleme.png',
              height: expanded ? 64 : 34,
              fit: BoxFit.contain,
              alignment: expanded ? Alignment.centerLeft : Alignment.center,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12, vertical: 8),
            child: expanded
                ? InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onSearch,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                      child: Row(children: [
                        const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Rechercher…', style: t.bodyMedium?.copyWith(color: AppColors.textSecondary))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                          child: Text('Ctrl K', style: t.labelSmall?.copyWith(color: AppColors.textSecondary)),
                        ),
                      ]),
                    ),
                  )
                : IconButton(tooltip: 'Rechercher (Ctrl+K)', onPressed: onSearch, icon: const Icon(Icons.search)),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 10, vertical: 4),
              children: [
                for (final g in groups) ...[
                  if (g.title != null)
                    expanded
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(10, 16, 10, 6),
                            child: Text(g.title!.toUpperCase(), style: t.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.1, fontWeight: FontWeight.w700)),
                          )
                        : const Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), child: Divider(height: 1)),
                  for (final i in g.items)
                    _SidebarTile(
                      item: i,
                      selected: identical(i, active) || (active != null && i.route == active!.route),
                      expanded: expanded,
                      badge: i.badge ? unread : 0,
                      onTap: () => onSelect(i.route),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          user == null
              ? _GuestFooter(expanded: expanded)
              : _UserFooter(expanded: expanded, name: user.fullName, email: user.email, avatar: user.avatar, onSelect: onSelect),
        ]),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool expanded;
  final int badge;
  final VoidCallback onTap;
  const _SidebarTile({required this.item, required this.selected, required this.expanded, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    Widget icon = Icon(selected ? item.selectedIcon : item.icon, size: 22, color: color);
    if (badge > 0) icon = Badge.count(count: badge, child: icon);
    final tile = Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.primary.withValues(alpha: 0.06),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 0, vertical: 10),
          child: expanded
              ? Row(children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: selected ? AppColors.primary : AppColors.textPrimary, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                    ),
                  ),
                  if (selected) Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
                ])
              : Center(child: icon),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: expanded ? tile : Tooltip(message: item.label, child: tile),
    );
  }
}

/// Visiteur : l'application se consulte librement, le compte se propose ici.
class _GuestFooter extends StatelessWidget {
  final bool expanded;
  const _GuestFooter({required this.expanded});

  @override
  Widget build(BuildContext context) {
    final from = GoRouterState.of(context).uri.toString();
    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: IconButton.filled(tooltip: 'Se connecter', onPressed: () => context.push(loginLocation(from: from)), icon: const Icon(Icons.login)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FilledButton.icon(onPressed: () => context.push(loginLocation(from: from)), icon: const Icon(Icons.login, size: 18), label: const Text('Se connecter')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => context.push('/register'), child: const Text('Créer un compte')),
      ]),
    );
  }
}

class _UserFooter extends ConsumerWidget {
  final bool expanded;
  final String name;
  final String email;
  final String? avatar;
  final ValueChanged<String> onSelect;
  const _UserFooter({required this.expanded, required this.name, required this.email, required this.avatar, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return PopupMenuButton<String>(
      tooltip: 'Mon compte',
      position: PopupMenuPosition.over,
      onSelected: (v) {
        if (v == 'logout') {
          ref.read(authNotifierProvider.notifier).logout().then((_) {
            if (context.mounted) context.go('/');
          });
        } else {
          onSelect(v);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: '/profile', child: ListTile(leading: Icon(Icons.person_outline), title: Text('Mon profil'), dense: true)),
        PopupMenuItem(value: '/settings', child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Paramètres'), dense: true)),
        PopupMenuDivider(),
        PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: AppColors.error), title: Text('Déconnexion'), dense: true)),
      ],
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: expanded ? 16 : 0, vertical: 12),
        child: expanded
            ? Row(children: [
                AppAvatar(name: name, imageUrl: avatar, size: 38, rounded: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleSmall),
                    Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
                const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
              ])
            : Center(child: AppAvatar(name: name, imageUrl: avatar, size: 38, rounded: true)),
      ),
    );
  }
}

/// Ctrl+K: type to filter every screen the user may open, Enter to jump.
class _CommandPalette extends StatefulWidget {
  final List<NavGroup> groups;
  const _CommandPalette({required this.groups});

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final all = [
      for (final g in widget.groups)
        for (final i in g.items) (group: g.title ?? 'Général', item: i),
    ];
    final q = _q.toLowerCase();
    final results = all.where((e) => q.isEmpty || e.item.label.toLowerCase().contains(q) || e.group.toLowerCase().contains(q)).toList();
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 440),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Aller à… (équipes, matchs, admin)', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
              onSubmitted: (_) {
                if (results.isNotEmpty) Navigator.of(context).pop(results.first.item.route);
              },
            ),
          ),
          Flexible(
            child: ListView(shrinkWrap: true, children: [
              for (final r in results)
                ListTile(
                  dense: true,
                  leading: Icon(r.item.icon, color: AppColors.primary),
                  title: Text(r.item.label),
                  trailing: Text(r.group, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  onTap: () => Navigator.of(context).pop(r.item.route),
                ),
              if (results.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun résultat'))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final SyncStatus status;
  const _SyncBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == SyncStatus.idle) return const SizedBox.shrink();
    final (text, color) = switch (status) {
      SyncStatus.offline => ('Mode hors-ligne : les modifications seront synchronisées plus tard.', AppColors.warning),
      SyncStatus.syncing => ('Synchronisation en cours...', AppColors.info),
      SyncStatus.error => ('Erreur de synchronisation.', AppColors.error),
      SyncStatus.idle => ('', AppColors.info),
    };
    return Container(
      width: double.infinity,
      color: color.withAlpha(30),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
