// Register form validation, entirely offline: AuthNotifier.register() is
// only reached after Form.validate() passes, so an invalid submission never
// touches the network.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_2sm/features/auth/presentation/screens/register_screen.dart';

void main() {
  testWidgets('shows validation errors when submitting an empty register form', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(ElevatedButton, 'Créer mon compte');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Prénoms, nom and téléphone all share the "Champ requis" message.
    expect(find.text('Champ requis'), findsNWidgets(3));
    expect(find.text('Email invalide'), findsOneWidget);
    expect(find.text('6 caractères minimum'), findsOneWidget);
  });

  testWidgets('shows a mismatch error when the password confirmation differs', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    // Order matches the fields as laid out in RegisterScreen: prénoms, nom,
    // email, téléphone, mot de passe, confirmation.
    await tester.enterText(fields.at(0), 'Jean');
    await tester.enterText(fields.at(1), 'Dupont');
    await tester.enterText(fields.at(2), 'jean.dupont@example.com');
    await tester.enterText(fields.at(3), '0600000000');
    await tester.enterText(fields.at(4), 'password1');
    await tester.enterText(fields.at(5), 'password2');
    await tester.pumpAndSettle();

    final submitButton = find.widgetWithText(ElevatedButton, 'Créer mon compte');
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Les mots de passe ne correspondent pas'), findsOneWidget);
  });
}
