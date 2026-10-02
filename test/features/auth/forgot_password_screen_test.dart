// ForgotPasswordScreen guards its first step with a plain manual check
// (not Form.validate()) before ever calling the repository, so submitting
// with an empty identifier never reaches the network.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_2sm/features/auth/presentation/screens/forgot_password_screen.dart';

void main() {
  testWidgets('shows an error when requesting a code with an empty identifier', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ForgotPasswordScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Envoyer le code'));
    await tester.pumpAndSettle();

    expect(find.text('Renseignez votre email ou téléphone.'), findsOneWidget);
  });
}
