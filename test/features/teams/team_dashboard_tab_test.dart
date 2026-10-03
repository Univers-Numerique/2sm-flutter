import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:app_2sm/features/teams/application/teams_providers.dart';
import 'package:app_2sm/features/teams/data/models/team.dart';
import 'package:app_2sm/features/teams/data/models/team_dashboard.dart';
import 'package:app_2sm/features/teams/presentation/widgets/team_dashboard_tab.dart';

/// Tableau de bord d'équipe (données de démonstration réelles de l'API) :
/// disposition du site, 5 éléments au plus par bloc, responsables seulement.
Map<String, dynamic> _json(String f) => jsonDecode(File('test/fixtures/$f').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final team = Team.fromJson(_json('team.json'));
  final dashboard = TeamDashboard.fromJson(_json('team_dashboard.json'));

  for (final size in [const Size(1366, 4000), const Size(400, 6000)]) {
    testWidgets('rendu sans erreur en ${size.width.toInt()} px', (tester) async {
      await initializeDateFormatting('fr_FR');
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [teamDashboardProvider(team.id).overrideWith((ref) async => dashboard)],
        child: MaterialApp(home: Scaffold(body: TeamDashboardTab(team: team))),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Liste des responsables'), findsOneWidget);
      expect(find.text("Résumé de l'état"), findsOneWidget);
      // Le bloc ne liste que les postes honorifiques / personnel administratif.
      final staff = team.members.where((m) => {'Postes Honorifiques', 'Personnel Administratif'}.contains(m.type) && m.statut == 1);
      for (final m in team.members.where((m) => !staff.contains(m) && m.type == 'Joueurs')) {
        expect(find.text(m.fullName).evaluate().length <= 1, isTrue, reason: '${m.fullName} ne doit pas être dans les responsables');
      }
    });
  }
}
