import 'package:app_2sm/features/activities/data/models/activity.dart';
import 'package:app_2sm/features/calendar/application/calendar_providers.dart';
import 'package:app_2sm/features/calendar/data/calendar_repository.dart';
import 'package:app_2sm/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:app_2sm/features/competitions/application/competitions_providers.dart';
import 'package:app_2sm/features/matches/data/models/match_game.dart';
import 'package:app_2sm/features/teams/application/teams_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  for (final entry in {'wide': const Size(1300, 900), 'phone': const Size(400, 850)}.entries) {
    testWidgets('calendar shows month events (${entry.key})', (tester) async {
      await initializeDateFormatting('fr_FR');
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final data = CalendarData(
        matches: [
          MatchGame(
            id: 1,
            ownerId: 1,
            homeTeamId: 1,
            awayTeamId: 2,
            dateDebut: '${today}T00:00:00.000000Z',
            heureDebut: '16:00:00',
            categorie: 'Senior',
            genre: 'Masculin',
            homeTeam: const MatchTeamRef(id: 1, nom: 'Éléphants FC'),
            awayTeam: const MatchTeamRef(id: 2, nom: 'Académie JS'),
          ),
        ],
        activities: [
          Activity(id: 3, ownerId: 1, titre: 'Entraînement physique', contenu: 'Séance de préparation', date: today, heure: '09:00:00'),
        ],
      );

      await tester.pumpWidget(ProviderScope(
        overrides: [
          calendarDataProvider.overrideWith((ref) async => data),
          teamsListProvider.overrideWith((ref) => Stream.value([])),
          competitionsListProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: CalendarScreen()),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Calendrier'), findsOneWidget);
      expect(find.text('Éléphants FC - Académie JS'), findsWidgets);
      expect(find.text('Entraînement physique'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
