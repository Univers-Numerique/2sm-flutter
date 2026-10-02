// Login form validation: submitting with empty fields must surface the
// validator messages and must NOT attempt a network call (validation fails
// before AuthNotifier.login() is ever reached), so this test stays fully
// offline and fast.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_2sm/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('shows required-field errors when submitting an empty login form', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Champ requis'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Se connecter'));
    await tester.pumpAndSettle();

    // Both the identifier and password fields share the same validator
    // message, so it should appear twice — and the screen must not have
    // crashed or hung attempting a real HTTP request.
    expect(find.text('Champ requis'), findsNWidgets(2));
  });
}
