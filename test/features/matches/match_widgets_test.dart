import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_2sm/features/competitions/data/models/competition_overview.dart';
import 'package:app_2sm/features/matches/data/models/match_game.dart';
import 'package:app_2sm/features/matches/data/models/match_overview.dart';
import 'package:app_2sm/features/matches/presentation/widgets/match_widgets.dart';

void main() {
  const match = MatchGame(
    id: 1,
    ownerId: 1,
    homeTeamId: 1,
    awayTeamId: 2,
    statut: 1,
    dateDebut: '2024-09-15T00:00:00.000000Z',
    heureDebut: '16:00:00',
    categorie: 'Senior',
    homeTeam: MatchTeamRef(id: 1, nom: 'Éléphants FC'),
    awayTeam: MatchTeamRef(id: 2, nom: 'Académie JS'),
    competition: MatchCompetitionRef(id: 1, nom: 'Championnat National Division 1'),
    scores: [MatchScore(id: 1, teamId: 1, buts: 2), MatchScore(id: 2, teamId: 2, buts: 1)],
  );

  testWidgets('scoreboard card renders score, teams and LIVE badge on a phone', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MatchScoreboardCard(match: match)))));
    expect(find.text('2  -  1'), findsOneWidget);
    expect(find.text('EN DIRECT'), findsOneWidget);
    expect(find.text('Éléphants FC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('standings table lists ranks and points', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const rows = [
      StandingRow(teamId: 1, nom: 'Éléphants FC', joues: 2, prevus: 4, victoires: 2, points: 6, butsPour: 5, butsContre: 1, difference: 4, progression: 50),
      StandingRow(teamId: 2, nom: 'Académie JS', joues: 2, prevus: 4, defaites: 2),
    ];
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: StandingsTable(rows: rows)))));
    expect(find.text('Éléphants FC'), findsOneWidget);
    expect(find.text('6'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('MatchOverview parses stats, officials and selection', () {
    final o = MatchOverview.fromJson({
      'match': {'id': 1, 'id_utilisateur': 1, 'id_equipe_domicile': 1, 'id_equipe_exterieur': 2, 'statut': 3},
      'evenements': [
        {'id': 1, 'id_match': 1, 'id_equipe': 1, 'id_utilisateur': 5, 'jeu': 'Buts Marqués', 'temps': '23:00', 'statut': 1}
      ],
      'officiels': {'arbitre_principal': 'Koné Ali'},
      'stats_domicile': {'Corners': 3},
      'stats_exterieur': <String, dynamic>{},
      'possession_domicile': 60.5,
      'possession_exterieur': 39.5,
      'buteurs_domicile': [],
      'buteurs_exterieur': [],
      'classements': [],
      'medias': [],
      'selection_domicile': [
        {'id': 5, 'nom': 'Bamba', 'prenoms': 'Abdoulaye', 'poste': 'Attaquant', 'age': 31, 'statut': 1}
      ],
      'selection_exterieur': [],
    });
    expect(o.events.single.jeu, 'Buts Marqués');
    expect(o.officials.arbitrePrincipal, 'Koné Ali');
    expect(o.homeStats['Corners'], 3);
    expect(o.homePossession, 60.5);
    expect(o.homeSelection.single.statut, 1);
  });
}
