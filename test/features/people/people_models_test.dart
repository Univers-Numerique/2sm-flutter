import 'package:flutter_test/flutter_test.dart';
import 'package:app_2sm/features/plans/data/plans_api.dart';
import 'package:app_2sm/features/players/data/football_constants.dart';
import 'package:app_2sm/features/players/data/models/player.dart';
import 'package:app_2sm/features/teams/data/models/team.dart';
import 'package:app_2sm/features/teams/data/models/team_dashboard.dart';
import 'package:app_2sm/features/teams/data/models/team_member.dart';

void main() {
  test('TeamMember flattens the user + position payload of /teams/{id}/members', () {
    final m = TeamMember.fromJson({
      'id': 5,
      'nom': 'Bamba',
      'prenoms': 'Abdoulaye',
      'avatar': 'avatars/player_8.jpg',
      'genre': 'Masculin',
      'date_de_naissance': '1995-05-20T00:00:00.000000Z',
      'positions': [
        {'id': 1, 'id_utilisateur': 5, 'id_equipe': 1, 'poste': 'Attaquant', 'categorie': 'Senior', 'type': 'Joueurs', 'statut': 1}
      ],
    }, teamId: 1);
    expect(m.userId, 5);
    expect(m.id, 1);
    expect(m.poste, 'Attaquant');
    expect(m.fullName, 'Abdoulaye Bamba');
    expect(m.age, isNotNull);
  });

  test('Team parses statistics keys returned by the Laravel API', () {
    final t = Team.fromJson({
      'id': 1,
      'id_utilisateur': 2,
      'nom': 'Éléphants FC',
      'statistics': {'wins': 3, 'draws': 1, 'defeats': 2, 'goals_scored': 9, 'goals_conceded': 4, 'points': 10, 'total_matches': 6, 'members_count': 5},
      'owner': {'id': 2, 'nom': 'Konan', 'prenoms': 'Jean-Philippe'},
    });
    expect(t.statistics!.goalDifference, 5);
    expect(t.isManagedBy(2), isTrue);
    expect(Team.fromJson(t.toJson()).statistics!.points, 10);
  });

  test('TeamDashboard and MemberStatsBundle parse their payloads', () {
    final d = TeamDashboard.fromJson({
      'statistics': {'wins': 1, 'matches_played': 1, 'average_goals': 2},
      'results_by_month': [
        {'month': '2026-09', 'wins': 1, 'draws': 0, 'defeats': 0, 'matches': 1, 'goals': 2}
      ],
      'category_matrix': {'Masculin': {'Senior': 4}},
      'activities': {'finished': 1, 'ongoing': 2, 'items': []},
    });
    expect(d.months.single.shortLabel, 'sept');
    expect(d.categoryMatrix['Masculin']!['Senior'], 4);
    expect(d.activitiesOngoing, 2);

    final b = MemberStatsBundle.fromJson({
      'stats': {'5': {'buts': 2, 'passes': 1, 'cartons': 0}},
      'skills': [
        {'id': 1, 'id_utilisateur': 5, 'performance': 'Endurance', 'valeur': 70, 'type': 'Physiques'}
      ],
    });
    expect(b.countersOf(5).buts, 2);
    expect(b.skillOf(5, 'Endurance', type: 'Physiques')!.valeur, 70);
    expect(b.skillOf(5, 'Endurance', type: 'Techniques'), isNull);
  });

  test('UserStats, plans and helpers', () {
    final s = UserStats.fromJson({
      'total_goals': 1,
      'events_by_type': {'Buts Marqués': 1},
      'skills': [
        {'id': 1, 'performance': 'Tête', 'valeur': '55.5', 'categorie': 'DEF (Défensive)', 'type': 'Techniques'}
      ],
    });
    expect(s.skillsOfType('Techniques').single.valeur, 55.5);
    expect(categoryCode('OFF (Offensive)'), 'OFF');
    expect(PlanInfo.fromJson({'id': 3, 'nom': 'Premium', 'prix': '10000.00'}).priceLabel, contains('10'));
    expect(ageFromBirth('1990-01-01T00:00:00.000000Z'), greaterThan(30));
  });
}
