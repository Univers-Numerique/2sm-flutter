import 'package:intl/intl.dart';

/// Parses an API timestamp (ISO-8601, UTC) or a plain `yyyy-MM-dd` date.
DateTime? parseApiDate(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

/// Relative French time, like the legacy `tempsEcoule()` helper
/// ("il y a 3 heures", "à l'instant", "il y a 2 jours"...).
String timeAgo(String? value) {
  final d = parseApiDate(value);
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 45) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  if (diff.inDays < 30) return 'il y a ${diff.inDays ~/ 7} sem.';
  if (diff.inDays < 365) return 'il y a ${diff.inDays ~/ 30} mois';
  return 'il y a ${diff.inDays ~/ 365} an(s)';
}

String formatDayMonth(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);

/// "samedi 14 septembre 2024" — used for detail pages.
String formatLongDate(String? value) {
  final d = parseApiDate(value);
  if (d == null) return '';
  try {
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(d);
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(d);
  }
}

String formatHour(DateTime d) => DateFormat('HH:mm').format(d);

/// Separator label between chat days: "Aujourd'hui", "Hier" or a date.
String dayLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff == 1) return 'Hier';
  try {
    return DateFormat('EEEE d MMMM', 'fr_FR').format(d);
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(d);
  }
}

/// First `<img src>` found in an HTML fragment (legacy `extrairePremiereImage`).
String? firstImageFromHtml(String html) {
  final m = RegExp("<img[^>]+src=[\"']([^\"']+)[\"']", caseSensitive: false).firstMatch(html);
  return m?.group(1);
}

/// Plain text preview of an HTML fragment.
String stripHtml(String html) {
  final withBreaks = html.replaceAll(RegExp(r'</(p|h[1-6]|div|li)>', caseSensitive: false), ' ');
  return withBreaks
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String truncateWords(String text, int maxWords) {
  final words = text.split(' ');
  if (words.length <= maxWords) return text;
  return '${words.take(maxWords).join(' ')}…';
}

/// Legacy password strength rule (parametres.php): 8+ chars, one uppercase
/// letter, one digit and one special character.
final RegExp legacyPasswordRule =
    RegExp(r'''^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$%^&*()_+~`|{}\[\]:;'<>?,./]).{8,}$''');

const listeActivites = <String>[
  'Entraînements physiques et techniques',
  'Analyse vidéo et tactique',
  "Réunions d'équipe et briefings tactiques",
  'Séances d\'étirements et de récupération',
  'Sessions de travail mental et de motivation',
  'Scouting et recrutement',
  'Gestion de la logistique et des équipements',
  'Relations publiques et communication',
];

const categoriesEquipe = <String>['Sous minimes', 'Minime', 'Cadet', 'Junior', 'Senior', 'Élite', 'Major'];
