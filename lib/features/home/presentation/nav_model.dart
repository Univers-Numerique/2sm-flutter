import 'package:flutter/material.dart';

import '../../auth/application/auth_guard.dart';

/// One navigation entry, shared by the desktop sidebar, the mobile "Plus"
/// menu and the Ctrl+K palette: a screen is declared here once.
class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool badge;

  const NavItem(this.label, this.icon, this.route, {IconData? selectedIcon, this.badge = false})
      : selectedIcon = selectedIcon ?? icon;
}

class NavGroup {
  final String? title;
  final List<NavItem> items;
  const NavGroup(this.title, this.items);
}

/// Routes shown as the five bottom tabs on phones.
const mobileTabRoutes = ['/', '/matches', '/competitions', '/teams', '/more'];

const mobileTabs = [
  NavItem('Accueil', Icons.home_outlined, '/', selectedIcon: Icons.home),
  NavItem('Matchs', Icons.sports_soccer_outlined, '/matches', selectedIcon: Icons.sports_soccer),
  NavItem('Compét.', Icons.emoji_events_outlined, '/competitions', selectedIcon: Icons.emoji_events),
  NavItem('Équipes', Icons.groups_outlined, '/teams', selectedIcon: Icons.groups),
  NavItem('Plus', Icons.apps_outlined, '/more', selectedIcon: Icons.apps),
];

/// Grouped like the legacy sidebar (Matchs, Compétitions, Équipes,
/// Utilisateurs, Admin).
List<NavGroup> buildNavGroups({required bool isAdmin, bool isGuest = false}) {
  final groups = [
      const NavGroup(null, [
        NavItem('Accueil', Icons.home_outlined, '/', selectedIcon: Icons.home),
      ]),
      const NavGroup('Matchs', [
        NavItem('Matchs', Icons.sports_soccer_outlined, '/matches', selectedIcon: Icons.sports_soccer),
        NavItem('Calendrier', Icons.calendar_month_outlined, '/calendar', selectedIcon: Icons.calendar_month),
        NavItem('Classements', Icons.leaderboard_outlined, '/rankings', selectedIcon: Icons.leaderboard),
        NavItem('Propositions', Icons.handshake_outlined, '/propositions', selectedIcon: Icons.handshake),
      ]),
      const NavGroup('Compétitions', [
        NavItem('Compétitions', Icons.emoji_events_outlined, '/competitions', selectedIcon: Icons.emoji_events),
        NavItem('Terrains', Icons.stadium_outlined, '/fields', selectedIcon: Icons.stadium),
      ]),
      const NavGroup('Équipes', [
        NavItem('Équipes', Icons.groups_outlined, '/teams', selectedIcon: Icons.groups),
        NavItem('Mon équipe', Icons.shield_outlined, '/my-team', selectedIcon: Icons.shield),
        NavItem('Activités', Icons.event_outlined, '/activities', selectedIcon: Icons.event),
        NavItem('Abonnements', Icons.card_membership_outlined, '/plans', selectedIcon: Icons.card_membership),
      ]),
      const NavGroup('Communauté', [
        NavItem('Joueurs & membres', Icons.people_outline, '/users', selectedIcon: Icons.people),
        NavItem('Messagerie', Icons.chat_bubble_outline, '/messaging', selectedIcon: Icons.chat_bubble),
        NavItem('Groupes', Icons.forum_outlined, '/messaging/directory', selectedIcon: Icons.forum),
        NavItem('Notifications', Icons.notifications_outlined, '/notifications', selectedIcon: Icons.notifications, badge: true),
      ]),
      const NavGroup('Mon compte', [
        NavItem('Mon profil', Icons.person_outline, '/profile', selectedIcon: Icons.person),
        NavItem('Mon parcours', Icons.timeline_outlined, '/career'),
        NavItem('Carte de membre', Icons.badge_outlined, '/card', selectedIcon: Icons.badge),
        NavItem('Paramètres', Icons.settings_outlined, '/settings', selectedIcon: Icons.settings),
      ]),
      if (isAdmin)
        const NavGroup('Administration', [
          NavItem('Tableau de bord', Icons.admin_panel_settings_outlined, '/admin', selectedIcon: Icons.admin_panel_settings),
          NavItem('Utilisateurs', Icons.manage_accounts_outlined, '/admin/users', selectedIcon: Icons.manage_accounts),
          NavItem('Équipes', Icons.shield_moon_outlined, '/admin/teams', selectedIcon: Icons.shield_moon),
          NavItem('Compétitions', Icons.military_tech_outlined, '/admin/competitions', selectedIcon: Icons.military_tech),
          NavItem('Terrains', Icons.location_on_outlined, '/admin/fields', selectedIcon: Icons.location_on),
          NavItem("Plans d'abonnement", Icons.card_giftcard_outlined, '/admin/plans', selectedIcon: Icons.card_giftcard),
        ]),
    ];
  if (!isGuest) return groups;
  // Visiteur : on garde tout ce qui se consulte, sans les espaces personnels.
  return [
    for (final g in groups)
      if (g.items.any((i) => !routeNeedsAccount(i.route)))
        NavGroup(g.title, [for (final i in g.items) if (!routeNeedsAccount(i.route)) i]),
  ];
}

/// The nav item whose route best (longest prefix) matches [location].
NavItem? activeNavItem(List<NavGroup> groups, String location) {
  NavItem? best;
  for (final g in groups) {
    for (final i in g.items) {
      final match = i.route == '/' ? location == '/' : (location == i.route || location.startsWith('${i.route}/'));
      if (match && (best == null || i.route.length > best.route.length)) best = i;
    }
  }
  return best;
}
