import 'package:flutter_test/flutter_test.dart';
import 'package:app_2sm/features/auth/application/auth_guard.dart';

void main() {
  test('consultation libre sans compte', () {
    for (final path in [
      '/', '/matches', '/matches/12', '/competitions', '/competitions/3', '/competitions/3/teams/4/selection',
      '/teams', '/teams/5', '/teams/5/members', '/users', '/users/9', '/users/9/career', '/fields',
      '/calendar', '/rankings', '/activities', '/activities/2', '/news/7', '/plans', '/more', '/matches/12/media',
    ]) {
      expect(routeNeedsAccount(path), isFalse, reason: path);
    }
  });

  test('espaces personnels et écrans de gestion : connexion demandée', () {
    for (final path in [
      '/profile', '/settings', '/settings/password', '/messaging', '/messaging/private/4', '/notifications',
      '/my-team', '/career', '/card', '/propositions', '/admin', '/admin/users', '/news/compose',
      '/teams/create', '/competitions/create', '/fields/create', '/matches/create', '/matches/friendly',
      '/matches/12/edit', '/matches/12/live', '/teams/5/add-member', '/competitions/3/resources/teams',
    ]) {
      expect(routeNeedsAccount(path), isTrue, reason: path);
    }
  });

  test('retour après connexion', () {
    expect(loginLocation(from: '/teams/5'), '/login?from=%2Fteams%2F5');
    expect(loginLocation(from: '/'), '/login');
  });
}
