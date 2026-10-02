// AdaptiveScaffold is the app's single navigation shell: a bottom
// NavigationBar under ~700px of width, a NavigationRail above it. This is a
// pure widget test — no providers, no network — that pumps it directly at
// two window sizes and checks which nav widget renders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_2sm/shared/widgets/adaptive_scaffold.dart';

void main() {
  Widget buildScaffold() {
    return MaterialApp(
      home: AdaptiveScaffold(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          AdaptiveDestination(label: 'Accueil', icon: Icons.home_outlined),
          AdaptiveDestination(label: 'Équipes', icon: Icons.shield_outlined),
        ],
        body: const Center(child: Text('Body')),
      ),
    );
  }

  testWidgets('shows a bottom NavigationBar under the desktop breakpoint', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScaffold());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('shows a NavigationRail at or above the desktop breakpoint', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildScaffold());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
