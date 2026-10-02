import '../../../players/data/models/player.dart';

/// A member of a team: the user plus their `postes` row for that team (role,
/// category, jersey number...). The API returns users with their positions
/// filtered on the team (`GET /teams/{id}/members`, `members` in
/// `GET /teams/{id}`); this class flattens that.
class TeamMember {
  final PlayerUser user;
  final PlayerPosition? position;
  final int teamId;

  const TeamMember({required this.user, required this.position, required this.teamId});

  /// `postes.id` (falls back to the user id when absent).
  int get id => position?.id ?? user.id;
  int get userId => user.id;
  String? get poste => position?.poste;
  String? get categorie => position?.categorie;
  String? get type => position?.type;
  int get statut => position?.statut ?? 1;
  String? get nom => user.nom;
  String? get prenoms => user.prenoms;
  String? get avatar => user.avatar;
  String get fullName => [user.prenoms, user.nom].where((s) => s != null && s.isNotEmpty).join(' ');
  int? get age => user.age;
  String? get genre => user.genre;

  bool get isManagerRole => const ['Responsable', 'Manager', 'Entraineur', 'Coach'].contains(poste);

  factory TeamMember.fromJson(Map<String, dynamic> json, {int? teamId}) {
    final user = PlayerUser.fromJson(json);
    PlayerPosition? pos;
    if (user.positions.isNotEmpty) {
      pos = user.positions.firstWhere((p) => teamId == null || p.teamId == teamId, orElse: () => user.positions.first);
    }
    return TeamMember(user: user, position: pos, teamId: teamId ?? pos?.teamId ?? 0);
  }
}

/// Per-member counters from `GET /teams/{id}/member-stats`.
class MemberCounters {
  final int buts;
  final int passes;
  final int cartons;
  const MemberCounters({this.buts = 0, this.passes = 0, this.cartons = 0});

  factory MemberCounters.fromJson(Map<String, dynamic> j) =>
      MemberCounters(buts: asInt(j['buts']) ?? 0, passes: asInt(j['passes']) ?? 0, cartons: asInt(j['cartons']) ?? 0);
}

class MemberStatsBundle {
  final Map<int, MemberCounters> counters;
  final List<Skill> skills;
  const MemberStatsBundle({this.counters = const {}, this.skills = const []});

  MemberCounters countersOf(int userId) => counters[userId] ?? const MemberCounters();

  /// Latest value of [skill] for [userId] (null when never evaluated).
  Skill? skillOf(int userId, String skill, {String? type}) {
    for (final s in skills) {
      if (s.userId == userId && s.performance == skill && (type == null || s.type == type)) return s;
    }
    return null;
  }

  factory MemberStatsBundle.fromJson(Map<String, dynamic> j) {
    final raw = j['stats'];
    final map = <int, MemberCounters>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final id = int.tryParse('$k');
        if (id != null && v is Map) map[id] = MemberCounters.fromJson(Map<String, dynamic>.from(v));
      });
    }
    return MemberStatsBundle(
      counters: map,
      skills: ((j['skills'] as List?) ?? const [])
          .map((e) => Skill.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
