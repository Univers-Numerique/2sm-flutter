// Smoke test: the app boots to the login screen when no session is cached.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_2sm/app.dart';

void main() {
  testWidgets('App boots to the login screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
