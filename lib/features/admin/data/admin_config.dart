import 'package:flutter/material.dart';

import '../../../core/constants/app_theme.dart';

/// The four tables the legacy generic editor (`admin/gerer.php`) handles.
/// The `key` is what the legacy URL carried (`?table=utilisateurs`).
enum AdminEntity {
  utilisateurs('utilisateurs', 'Utilisateur'),
  equipes('equipes', 'Équipe'),
  competitions('competitions', 'Compétition'),
  terrains('terrains', 'Terrain');

  final String key;
  final String label;
  const AdminEntity(this.key, this.label);

  static AdminEntity? fromKey(String key) {
    for (final e in AdminEntity.values) {
      if (e.key == key) return e;
    }
    return null;
  }
}

/// One entry of the legacy `$tableaux_statut` config: label, icon and the
/// badge colour (Bootstrap `badge-success` -> success, etc.).
class StatusOption {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  const StatusOption(this.value, this.label, this.icon, this.color);
}

/// Legacy `$tableaux_statut` (config/fonctions.php), index = statut value.
///
/// The label sets are the legacy ones; the value order follows what the
/// Laravel data actually stores (teams and fields are created with statut 1 =
/// active/available, competitions use 0 planned, 1 en cours, 2 annulé,
/// 3 terminé — same as the Laravel Blade filters). For users, 1 is the normal
/// active account (legacy called it "Inactif") and 4 grants site
/// administration in Laravel (`User::isSiteAdmin`), so 4..7 are shown as
/// labels but not offered in the editor — the administrator role has its own
/// switch.
class AdminStatus {
  static const _grey = Color(0xFF64748B);

  static const users = <StatusOption>[
    StatusOption(0, 'Suspendu', Icons.lock_outline, AppColors.error),
    StatusOption(1, 'Actif', Icons.how_to_reg_outlined, AppColors.success),
    StatusOption(2, 'Spécial', Icons.star_outline, AppColors.info),
    StatusOption(3, 'Gestionnaire', Icons.manage_accounts_outlined, AppColors.info),
    StatusOption(4, 'Super gestionnaire', Icons.admin_panel_settings_outlined, AppColors.info),
    StatusOption(5, 'Modérateur', Icons.supervisor_account_outlined, AppColors.primary),
    StatusOption(6, 'Administrateur', Icons.shield_outlined, AppColors.secondary),
    StatusOption(7, 'Super administrateur', Icons.workspace_premium_outlined, _grey),
  ];

  /// Statuses the editor lets an admin choose for a user.
  static const editableUsers = <int>[0, 1, 2, 3];

  static const competitions = <StatusOption>[
    StatusOption(0, 'Planifié', Icons.event_available_outlined, AppColors.primary),
    StatusOption(1, 'En cours', Icons.play_circle_outline, AppColors.info),
    StatusOption(2, 'Annulé', Icons.cancel_outlined, AppColors.error),
    StatusOption(3, 'Terminé', Icons.check_circle_outline, AppColors.success),
  ];

  static const fields = <StatusOption>[
    StatusOption(0, 'Fermé', Icons.block_outlined, AppColors.secondary),
    StatusOption(1, 'Disponible', Icons.check_circle_outline, AppColors.success),
    StatusOption(2, 'Occupé', Icons.do_not_disturb_on_outlined, AppColors.error),
    StatusOption(3, 'En rénovation', Icons.construction_outlined, AppColors.info),
  ];

  static const teams = <StatusOption>[
    StatusOption(0, 'Inactif', Icons.person_off_outlined, AppColors.warning),
    StatusOption(1, 'Actif', Icons.how_to_reg_outlined, AppColors.success),
    StatusOption(2, 'Disqualifié', Icons.cancel_outlined, AppColors.error),
    StatusOption(3, 'Retiré', Icons.person_remove_outlined, AppColors.secondary),
  ];

  static List<StatusOption> forEntity(AdminEntity e) {
    switch (e) {
      case AdminEntity.utilisateurs:
        return users;
      case AdminEntity.competitions:
        return competitions;
      case AdminEntity.terrains:
        return fields;
      case AdminEntity.equipes:
        return teams;
    }
  }

  static StatusOption optionFor(AdminEntity e, int statut) {
    final list = forEntity(e);
    for (final o in list) {
      if (o.value == statut) return o;
    }
    return StatusOption(statut, 'Statut $statut', Icons.help_outline, _grey);
  }
}

/// Legacy `$categorieEquipe` (+ the U-categories the seed data uses).
const adminCategories = <String>[
  'Sous minimes',
  'Minime',
  'Cadet',
  'Junior',
  'Senior',
  'Élite',
  'Major',
  'U17',
  'U20',
];

const adminGenres = <String>['Masculin', 'Féminin'];

/// Legacy `$postesFootball`, grouped by category (optgroups of the poste
/// filter in `admin/utilisateurs.php`).
const adminPostesByCategory = <String, List<String>>{
  'Joueurs': [
    'Gardien de But',
    'Défenseur Central',
    'Défenseur Latéral Droit',
    'Défenseur Latéral Gauche',
    'Milieu Défensif',
    'Milieu Central',
    'Milieu Offensif',
    'Attaquant',
    'Avant-Centre',
    'Remplaçant',
  ],
  'Personnel Technique': [
    'Entraîneur Principal',
    'Entraîneur Adjoint',
    'Entraîneur des Gardiens de But',
    'Préparateur Physique',
    'Analyste Vidéo',
    "Médecin de l'Équipe",
    'Kinésithérapeute',
    'Nutritionniste Sportif',
    'Psychologue Sportif',
    'Recruteur',
    'Responsable Médical',
    "Responsable de l'Équipe",
    'Responsable de la Formation des Jeunes',
  ],
  'Personnel Administratif': [
    'Trésorier',
    'Secrétaire Général',
    'Directeur Général',
    'Directeur Sportif',
    'Directeur Administratif',
    'Responsable des Relations Publiques',
    'Responsable Marketing',
    'Responsable Communication',
    'Responsable des Opérations de Match',
    'Responsable des Installations',
    'Responsable de la Sécurité',
    'Secrétaire du Club',
    "Agent de Voyage de l'Équipe",
    'Responsable des Équipements',
    'Responsable des Médias Sociaux',
    "Photographe de l'Équipe",
  ],
  'Postes Honorifiques': [
    'Président du Club',
    'Vice-Président du Club',
    "Membre d'Honneur",
    'Ambassadeur du Club',
  ],
  'Postes Match': [
    'Arbitre',
    'Commentateur',
    'Chronométreur',
    'Opérateur de Caméra',
    'Coordinateur des Médias',
    'Coordonnateur de la Sécurité',
    'Annonceur Public',
    'Responsable des Installations de Match',
  ],
};
