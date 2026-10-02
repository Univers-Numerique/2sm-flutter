import 'package:flutter_test/flutter_test.dart';

import 'package:app_2sm/features/activities/data/models/activity.dart';
import 'package:app_2sm/features/messaging/data/models/conversation.dart';
import 'package:app_2sm/features/news/data/models/news.dart';
import 'package:app_2sm/features/notifications/data/models/app_notification.dart';
import 'package:app_2sm/features/social_common/social_utils.dart';

void main() {
  test('Activity exposes invited / present / absent counters from participants', () {
    final a = Activity.fromJson({
      'id': 1,
      'id_utilisateur': 2,
      'titre': 'Entraînement',
      'lieu': 'Stade',
      'statut': 1,
      'participants': [
        {'id': 3, 'nom': 'A', 'prenoms': 'B', 'pivot': {'id_activite': 1, 'id_utilisateur': 3, 'statut': 1}},
        {'id': 4, 'nom': 'C', 'prenoms': 'D', 'pivot': {'id_activite': 1, 'id_utilisateur': 4, 'statut': 0}},
      ],
    });
    expect(a.invitedCount, 2);
    expect(a.presentCount, 1);
    expect(a.absentCount, 1);
    expect(a.lieu, 'Stade');
    expect(Activity.statusLabel(a.statut), 'Activité en cours');
  });

  test('Conversation parses members, unread counter and my status', () {
    final c = Conversation.fromJson({
      'id': 9,
      'id_utilisateur': 1,
      'sujet': 'Groupe',
      'type': 'public',
      'statut': '1',
      'users_count': 2,
      'unread_count': 3,
      'my_statut': 2,
      'users': [
        {'id': 1, 'nom': 'K', 'prenoms': 'A', 'pivot': {'statut': 2}},
      ],
    });
    expect(c.isPublic, isTrue);
    expect(c.isAdminMember, isTrue);
    expect(c.unreadCount, 3);
    expect(c.users!.first.statutLabel, 'Administrateur');
  });

  test('News parses views and liked flags; notification embeds the proposition', () {
    final n = News.fromJson({'id': 1, 'id_utilisateur': 1, 'contenu': '<p>x</p>', 'views_count': 5, 'liked': true});
    expect(n.viewsCount, 5);
    expect(n.isLiked, isTrue);

    final notif = AppNotification.fromJson({
      'id': 1,
      'titre': 'Match',
      'id_proposition': 7,
      'proposition': {'id': 7, 'id_proposeur': 1, 'id_proposee': 2, 'statut': 0},
    });
    expect(notif.proposition!.proposedId, 2);
  });

  test('legacy password rule and HTML helpers', () {
    expect(legacyPasswordRule.hasMatch('Abcdef1!'), isTrue);
    expect(legacyPasswordRule.hasMatch('abcdef12'), isFalse);
    expect(firstImageFromHtml('<p>a</p><img src="x/y.png">'), 'x/y.png');
    expect(stripHtml('<h1>Titre</h1><p>Corps</p>'), 'Titre Corps');
  });
}
