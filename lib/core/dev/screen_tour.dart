import 'dart:async';

import 'package:go_router/go_router.dart';

/// Outil de développement : parcourt une liste d'écrans pour les comparer au
/// site en captures, sans souris. Inactif sauf compilation avec
///   --dart-define=SCREEN_TOUR=/,/matches,/teams/1 [--dart-define=SCREEN_TOUR_DELAY=6]
/// (constantes de compilation : rien n'en reste dans les versions publiées).
class ScreenTour {
  static const _routes = String.fromEnvironment('SCREEN_TOUR');
  static const _delay = int.fromEnvironment('SCREEN_TOUR_DELAY', defaultValue: 6);
  static bool _started = false;

  static void start(GoRouter router) {
    if (_routes.isEmpty || _started) return;
    _started = true;
    final routes = _routes.split(',').where((r) => r.isNotEmpty).toList();
    var i = 0;
    Timer.periodic(const Duration(seconds: _delay), (t) {
      if (i >= routes.length) {
        t.cancel();
        return;
      }
      router.go(routes[i++]);
    });
  }
}
