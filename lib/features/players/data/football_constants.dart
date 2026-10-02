import 'package:flutter/material.dart';

/// Reference lists copied from the legacy `config/fonctions.php`
/// ($categorieEquipe, $postesFootball, $competencesTechniques,
/// $competencesPhysiques) so pickers and skill sheets match the PHP site.
const List<String> kCategories = ['Sous minimes', 'Minime', 'Cadet', 'Junior', 'Senior', 'Élite', 'Major'];

const List<String> kGenres = ['Masculin', 'Féminin'];

const Map<String, List<String>> kPostesFootball = {
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

class SkillDef {
  final String name;
  final String type; // 'Techniques' | 'Physiques'
  final String category; // e.g. 'OFF (Offensive)'
  final IconData icon;
  const SkillDef(this.name, this.type, this.category, this.icon);
}

/// skill type -> category -> skill names (same order as the PHP arrays).
const Map<String, Map<String, List<String>>> kCompetences = {
  'Techniques': {
    'OFF (Offensive)': [
      'Précision de passe courte',
      'Précision de passe longue',
      'Précision de tir',
      'Précision de coup franc',
      'Effet',
      'Finition',
      'Tir de loin',
      'Précision de passe',
    ],
    'DEF (Défensive)': ['Tête', 'Saut', 'Agressivité', 'Gardien de but', 'Contrôle aérien'],
    'TEC (Téchnique)': ['Précision de dribble', 'Contrôle de balle', 'Technique de tir', 'Coordination'],
    'STA (Endurance)': ['Endurance'],
    'POW (Puissance)': ['Puissance de tir', 'Force musculaire', 'Condition physique'],
    'SPD (Vitesse)': [
      'Réactivité',
      'Agilité',
      'Vitesse de dribble',
      'Vitesse de passe courte',
      'Vitesse de passe longue',
    ],
  },
  'Physiques': {
    'STA (Stamina)': ['Condition physique', 'Endurance'],
    'DEF (Defensive)': ['Défense', 'Équilibre du corps'],
    'SPD (Speed)': ['Vitesse maximale', 'Accélération', 'Réactivité', 'Agilité'],
    'TEC (Technique)': ['Coordination', 'Souplesse'],
    'POW (Power)': ['Force musculaire'],
  },
};

IconData skillIcon(String skill) {
  final s = skill.toLowerCase();
  if (s.contains('passe')) return Icons.swap_calls;
  if (s.contains('tir') || s.contains('finition') || s.contains('coup franc') || s.contains('effet')) {
    return Icons.gps_fixed;
  }
  if (s.contains('tête') || s.contains('saut') || s.contains('aérien')) return Icons.height;
  if (s.contains('endurance') || s.contains('condition')) return Icons.favorite_outline;
  if (s.contains('force') || s.contains('puissance')) return Icons.fitness_center;
  if (s.contains('vitesse') || s.contains('accélération') || s.contains('réactivité')) return Icons.speed;
  if (s.contains('agilité')) return Icons.directions_run;
  if (s.contains('défense') || s.contains('équilibre') || s.contains('gardien')) return Icons.shield_outlined;
  if (s.contains('dribble') || s.contains('balle')) return Icons.sports_soccer;
  if (s.contains('souplesse')) return Icons.self_improvement;
  return Icons.bolt;
}

/// Short axis code of a category label: 'OFF (Offensive)' -> 'OFF'.
String categoryCode(String? category) {
  if (category == null || category.isEmpty) return '';
  final i = category.indexOf(' ');
  return i > 0 ? category.substring(0, i) : category;
}

/// Icon for an in-game event type in the player's stats / career.
IconData gameEventIcon(String jeu) {
  switch (jeu) {
    case 'Buts Marqués':
      return Icons.sports_soccer;
    case 'Tirs Cadrés':
    case 'Tirs non Cadrés':
    case 'Tirs au But':
      return Icons.gps_fixed;
    case 'Corners':
      return Icons.flag_outlined;
    case 'Fautes':
      return Icons.front_hand_outlined;
    case 'Cartons Jaunes':
      return Icons.style;
    case 'Cartons Rouges':
      return Icons.style;
    case 'Hors-Jeu':
      return Icons.block;
    case 'Arrêts du Gardien':
      return Icons.pan_tool_outlined;
    case 'Duel Gagné':
      return Icons.sports_mma;
    case 'Passes Réussies':
    case 'Centres Réussis':
      return Icons.swap_calls;
    default:
      return Icons.timer_outlined;
  }
}

Color gameEventColor(String jeu) {
  switch (jeu) {
    case 'Buts Marqués':
      return const Color(0xFF22A559);
    case 'Cartons Jaunes':
      return const Color(0xFFF59E0B);
    case 'Cartons Rouges':
    case 'Tirs non Cadrés':
      return const Color(0xFFE53E4D);
    default:
      return const Color(0xFF2E90FA);
  }
}

/// Age in years from an ISO birth date (`1998-08-12T00:00:00.000000Z`).
int? ageFromBirth(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;
  final now = DateTime.now();
  var age = now.year - d.year;
  if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
  return age < 0 ? null : age;
}

/// "il y a 3 jours" style relative time (port of the PHP tempsEcoule()).
String timeAgo(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inDays >= 365) {
    final y = diff.inDays ~/ 365;
    return '$y an${y > 1 ? 's' : ''}';
  }
  if (diff.inDays >= 30) return '${diff.inDays ~/ 30} mois';
  if (diff.inDays > 1) return '${diff.inDays} jours';
  if (diff.inDays == 1) return 'hier';
  if (diff.inHours >= 2) return 'il y a ${diff.inHours} heures';
  if (diff.inHours == 1) return 'il y a une heure';
  if (diff.inMinutes > 0) return 'il y a ${diff.inMinutes} minutes';
  return "à l'instant";
}

String formatDateFr(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  const months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}
