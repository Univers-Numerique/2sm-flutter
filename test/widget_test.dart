// Smoke test: sans session, l'application s'ouvre en visiteur sur l'accueil
// (consultable sans compte) et propose de se connecter dans le menu.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_2sm/app.dart';

void main() {
  testWidgets("L'app s'ouvre en visiteur sur l'accueil", (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1366, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: App()));
    // Pas de pumpAndSettle : les squelettes de chargement animent en continu.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.text('Actualités'), findsWidgets);
    expect(find.text('Me connecter'), findsOneWidget);
    expect(find.text("M'inscrire"), findsOneWidget);
  });
}
