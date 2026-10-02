import '../../core/constants/api_constants.dart';

/// Resolves a path returned by the API (`avatars/admin.jpg`,
/// `/storage/logos/x.png` or an absolute URL) into a loadable URL.
/// Returns null for empty input so callers can fall back to initials.
String? mediaUrl(String? path) {
  if (path == null) return null;
  final p = path.trim();
  if (p.isEmpty) return null;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  final clean = p.startsWith('/') ? p.substring(1) : p;
  final relative = clean.startsWith('storage/') ? clean : 'storage/$clean';
  return '${ApiConstants.mediaBaseUrl}/$relative';
}

/// "Alain Kouadio" -> "AK", "Éléphants FC" -> "ÉF".
String initialsOf(String? name, {int max = 2}) {
  if (name == null) return '?';
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(max).map((s) => s[0].toUpperCase()).join();
}
