import 'package:app_2sm/features/admin/application/admin_providers.dart';
import 'package:app_2sm/features/admin/data/models/admin_models.dart';
import 'package:app_2sm/features/admin/presentation/screens/admin_competitions_screen.dart';
import 'package:app_2sm/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:app_2sm/features/admin/presentation/screens/admin_fields_screen.dart';
import 'package:app_2sm/features/admin/presentation/screens/admin_teams_screen.dart';
import 'package:app_2sm/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _owner = AdminOwnerRef(id: 1, nom: 'Kouadio', prenoms: 'Alain');

PagedResult<T> _page<T>(List<T> rows) => PagedResult<T>(data: rows, currentPage: 1, lastPage: 3, total: 40, perPage: 15);

final _dashboard = AdminDashboard(
  counts: const DashboardCounts(users: 15, teams: 8, fields: 10, competitions: 8, matches: 6, matchesPlayed: 5, activities: 7),
  resultsByMonth: const [
    MonthlyResult(month: '2024-08'),
    MonthlyResult(month: '2024-09', homeWins: 3, draws: 1, awayWins: 0, goals: 9, matches: 4),
  ],
  matchesByWeek: const [WeekCount(week: 1, matches: 2), WeekCount(week: 2, matches: 1)],
  managers: const [DashboardManager(id: 1, nom: 'Konan', prenoms: 'Jean', poste: 'Président du Club', telephone: '+225', depuis: '2026-09-19 02:08:06')],
  recentEvents: const [DashboardEvent(id: 1, home: 'Éléphants FC', away: 'Académie JS', date: '2024-09-15')],
  activities: const DashboardActivities(
    items: [DashboardActivity(id: 1, titre: 'Entraînement', lieu: 'Stade', date: '2026-09-19', heure: '16:00:00')],
    finished: 2,
    inProgress: 1,
  ),
  tasks: const [DashboardTask(id: 1, tache: 'Préparer le matériel', nomDest: 'Fofana', prenomsDest: 'Youssef')],
  subscriptionsByPlan: const [PlanStat(id: 1, nom: 'Pro', prix: 5000, count: 2, montant: 10000)],
  performanceByMonth: const [PerfMonth(month: '2026-08', avg: 60), PerfMonth(month: '2026-09', avg: 72)],
  topPerformers: const [TopPerformer(id: 1, nom: 'Akè', prenoms: 'Brice', moyenne: 88, age: 28)],
);

Future<void> _pump(WidgetTester tester, Widget screen, List<Override> overrides, Size size) async {
  await initializeDateFormatting('fr_FR');
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: overrides, child: MaterialApp(home: screen)));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  final sizes = {'wide': const Size(1300, 900), 'phone': const Size(400, 850)};

  for (final entry in sizes.entries) {
    group('admin screens (${entry.key})', () {
      testWidgets('dashboard renders KPIs and charts', (tester) async {
        await _pump(tester, const AdminDashboardScreen(), [
          adminDashboardProvider.overrideWith((ref) async => _dashboard),
        ], entry.value);
        expect(find.text('Tableau de bord'), findsWidgets);
        expect(find.text('Compétitions'), findsWidgets);
        expect(find.text('Liste des responsables'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('users list shows rows and pagination', (tester) async {
        await _pump(tester, const AdminUsersScreen(), [
          adminUsersProvider.overrideWith((ref) async => _page([
                const AdminUserRow(id: 1, nom: 'Akè', prenoms: 'Brice', genre: 'Masculin', poste: 'Attaquant', categorie: 'Senior', equipe: 'Éléphants FC', age: 28),
              ])),
        ], entry.value);
        expect(find.text('Akè Brice'), findsOneWidget);
        expect(find.text('Gérer'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('teams list', (tester) async {
        await _pump(tester, const AdminTeamsScreen(), [
          adminTeamsProvider.overrideWith((ref) async => _page([
                const AdminTeamRow(id: 1, nom: 'Éléphants FC', lieu: 'Abidjan', membersCount: 5, owner: _owner),
              ])),
        ], entry.value);
        expect(find.text('Éléphants FC'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('competitions list', (tester) async {
        await _pump(tester, const AdminCompetitionsScreen(), [
          adminCompetitionsProvider.overrideWith((ref) async => _page([
                const AdminCompetitionRow(id: 1, nom: 'Championnat D1', categorie: 'Senior', genre: 'Masculin', statut: 1, progression: 75, matchesCount: 4, matchesFinishedCount: 3),
              ])),
        ], entry.value);
        expect(find.textContaining('75%'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('fields list', (tester) async {
        await _pump(tester, const AdminFieldsScreen(), [
          adminFieldsProvider.overrideWith((ref) async => _page([
                const AdminFieldRow(id: 1, nomTerrain: 'Stade de la Paix', lieu: 'Bouaké', owner: _owner),
              ])),
        ], entry.value);
        expect(find.text('Stade de la Paix'), findsOneWidget);
        expect(find.text('Gérer'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
