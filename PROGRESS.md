# 2SM Flutter — Suivi d'avancement

Voir le plan complet dans la session Claude Code (Phases 0-4). Ce fichier remplace les ~20 anciens `TODO*.md`.

## Phase 0 — API Laravel (2sm-laravel) : ✅ terminée
- Bugs corrigés : `is_admin` (→ `isSiteAdmin()` basé sur la table `admins`), `GET /stats` cassé, **double hachage du mot de passe** (register/changePassword/resetPassword — bug critique bloquant toute authentification, corrigé et vérifié par test réel register+login), routes `/fields/nearby`/`/fields/default` interceptées par `/fields/{id}` (ordre des routes corrigé), `GET /notifications` n'exposait jamais le statut lu/non-lu (ajout du champ `statut_lecture`), lien `id_proposition` jamais renseigné entre une proposition de match amical et sa notification, `POST /activities/{id}/join` plantait (colonne pivot inexistante), statut initial d'une activité créée (0 au lieu de 1).
- Nouveaux contrôleurs : Admin, Plan, Media, Follow, Task, Proposition, Selection, Settings.
- Nouveau : backend complet de la messagerie de groupe (`ConversationMessage` + `MessageController::showConversation/conversationMessages/storeConversationMessage`), la table `messages_conversation` existait sans être exposée.
- Nouvelles migrations : `plan_abonnements`, `parametres`, lat/lng sur `terrains`, contact en attente sur `utilisateurs`.
- `updated_since` ajouté aux endpoints `index` pour le pull incrémental.
- Serveur de dev : `php artisan serve --port=8001` (le port 8000 est pris par un autre projet, PNVB).

## Phase 1 — Fondations Flutter : ✅ terminée
- `lib/` reconstruit : `core/` (constants, network avec intercepteur 401, database drift générique CachedEntities/PendingOperations/SyncMeta, sync service avec connectivity_plus), `router/app_router.dart` (go_router, toutes les routes de la Phase 2 câblées), `shared/widgets/adaptive_scaffold.dart` (nav bar mobile / nav rail desktop).
- Feature `auth` complète (login, register, forgot-password 2 étapes, session persistée offline).
- Shell principal (`home_shell_screen.dart`) : 5 onglets — Accueil (actualités), Équipes, Compétitions, Matchs, Profil — plus un écran "Plus" (`more_menu_screen.dart`) pour Activités/Messagerie/Notifications/Terrains/Calendrier/Paramètres/Admin, accessible depuis l'onglet Profil (évite de surcharger la barre de nav mobile, à l'image du menu flottant de l'app PHP).
- Vérifié visuellement : build Windows fonctionnel (capture d'écran), `flutter analyze` et `flutter test` propres sur tout le projet.

## Phase 2 — Domaines métier : ✅ tous les domaines cœur construits

- ✅ **Équipes** — patron de référence (`LocalFirstRepository<T>` extrait dans `lib/core/database/local_first_repository.dart`, réutilisé par tous les domaines suivants).
- ✅ **Profil/Paramètres** — profil (vue/édition/avatar), changement mot de passe, paramètres.
- ✅ **Compétitions** — liste, détail à onglets (description/classement/équipes/matchs), création/édition, génération/suppression de calendrier de matchs, sélection d'équipe.
- ✅ **Terrains** — liste, recherche, création, lien Maps.
- ✅ **Matchs** — liste, détail à onglets (stats/évènements/compositions), programmation, **console d'arbitrage live** (frappe d'évènements en direct, appels réseau directs sans passer par la file hors-ligne).
- ✅ **Activités** — liste, détail à onglets (activité/tâches/présences), création, workflow tâches.
- ✅ **Actualités** — fil, détail avec commentaires/likes, rédaction (texte simple).
- ✅ **Messagerie** — conversations privées + groupes (backend de groupe ajouté en Phase 0), création de groupe.
- ✅ **Notifications** — liste avec statut lu/non-lu fiable, tout marquer lu, actions accepter/refuser une proposition de match.
- ✅ **Calendrier** — vue mensuelle (grille + agenda du jour sélectionné) fusionnant matchs et activités, sans dépendance externe.

`flutter analyze` : 0 erreur/warning sur tout le projet (uniquement des infos de style). `flutter test` : passant. Intégration centrale (routeur + shell) terminée pour tous les domaines ci-dessus.

## Phase 3 — Admin : ✅ terminée
- Bug corrigé au passage : `is_admin` n'était renvoyé par aucun endpoint d'authentification (`login`/`register`/`user`), seulement par la liste admin des utilisateurs — un compte admin ne se voyait donc jamais proposer le module Admin côté Flutter. Corrigé et vérifié (`admin@2sm.com` / `password123`).
- Tableau de bord (stats globales), gestion utilisateurs (recherche/filtre/statut/blocage/promotion admin), modération équipes/compétitions/terrains (éditeur de statut générique, équivalent `admin/gerer.php`), gestion des plans d'abonnement (CRUD).
- Routes : `/admin`, `/admin/users`, `/admin/moderation`, `/admin/plans`, accessibles depuis l'onglet Profil → Plus, visibles seulement si `AppUser.isAdmin`.

`flutter analyze` : 0 erreur/warning sur tout le projet. `flutter test` : passant.

## Phase 4 — Polish transverse : ✅ terminée
- **Notifications locales** (pas de vrai push : pas de projet Firebase pour ce projet — décision utilisateur) : `flutter_local_notifications`, déclenchées sur nouvelle notification serveur non lue et nouveau message privé reçu, via un hook générique `SyncableResource.onItemsPulled` ajouté à `SyncService` (le service de sync générique reste agnostique du concept "notification locale").
- **Upload de fichiers réel** : logo d'équipe, photo de compétition, photo de terrain — nouveaux endpoints Laravel (`POST /teams/{id}/logo`, `/competitions/{id}/photo`, `/fields/{id}/photo`), mêmes patrons que l'avatar utilisateur.
- **Layouts desktop** : grilles responsives sur Matchs/Activités/Terrains (comme Équipes/Compétitions), colonne centrée max-width sur Actualités/Messagerie/Notifications (lisibilité en grande largeur), menu "Plus" en grille adaptative.
- **Tests widgets** : validation formulaires login/register/mot de passe oublié, comportement adaptatif de `AdaptiveScaffold` selon la largeur.
- Bug corrigé : `is_admin` absent des réponses `login`/`register`/`user` (uniquement présent dans la liste admin) — un compte admin ne voyait jamais le module Admin apparaître côté app.
- **Blocage d'environnement rencontré et résolu** : `flutter_local_notifications` cassait le build Windows (composant Visual Studio "C++ ATL" manquant) — composant installé (élévation UAC approuvée), build Windows vérifié fonctionnel (`flutter build windows` réussi).

`flutter analyze` et `flutter test` (7 tests) propres sur tout le projet. Build Windows vérifié.

## Données de démonstration (2sm-laravel/database/seeders/EnrichmentSeeder.php)
Ajouté après coup car plusieurs tables issues de la Phase 0 étaient restées vides : `admins` (1), rosters d'équipe complétés (`postes` 8→32), **liaison équipes↔compétitions** (`equipes_liaison_competition`, 0→22 — sans ça, aucune compétition n'avait d'équipe liée : onglet "Équipes", classements et génération de calendrier étaient tous vides), sélections d'équipe (`selections_competitions`, 91), tâches d'activités (`taches`, 14), plans d'abonnement (`plan_abonnements`, 3), abonnements/follows (`etre_notifie`, 11), médias + likes (`medias`/`likes_media`, 4/12). Idempotent (rejouable sans doublons), enregistré dans `DatabaseSeeder`.

## Typographie & design (retour utilisateur : "manque de modernité")
Direction validée avec l'utilisateur : sport-tech dynamique. Refonte du thème (`lib/core/constants/app_theme.dart`) : typographie à deux polices (Manrope en gras pour titres/headlines avec tracking négatif, Inter pour le corps de texte — remplace le Poppins uniforme), cartes plus arrondies (rayon 20) avec ombre teintée plutôt que noire, boutons/inputs/chips/FAB/nav redessinés (rayons, feedback tactile, focus). AppBar désormais alignée à gauche (plus moderne que centré). Écran de connexion refondu avec bandeau dégradé marine + logo détouré (`logo_emblem_transparent.png`, fond blanc retiré par seuillage) + carte flottante avec ombre portée. Écran d'inscription : champs prénom/nom en ligne, icônes de préfixe.
Bug trouvé et corrigé en cours de route : le contenu HTML des actualités (titres `<h1>`) héritait de la mauvaise couleur de texte (gris secondaire au lieu de la couleur de titre), rendant les titres du fil d'actualité peu lisibles — un style HTML dédié (`news_html_style.dart`) corrige ça.
Vérifié visuellement sur Windows (avant/après) et tests (7/7 passants, un test ajusté car le formulaire d'inscription, plus haut, nécessite un scroll avant le tap dans le viewport de test).

## Identité visuelle
Logo fourni (`assets/branding/logo.png`) intégré au projet : icônes d'application générées pour toutes les plateformes (Android, iOS, Windows, macOS, web) via `flutter_launcher_icons`, palette de couleurs (`AppColors`) remplacée — vert `#16A34A` (au lieu de l'orange) et marine `#0B2540` (au lieu du noir), extraits directement du logo. Logo intégré dans la barre de navigation desktop et l'écran de connexion (`assets/branding/logo_emblem.png`, version recadrée sans le texte pour les petits espaces). Vérifié visuellement sur Windows et Android.

## Notes pour la suite
- Le générateur de code (`dart run build_runner build`) doit être relancé après toute modification de modèle `@JsonSerializable` ou des tables Drift.
- Base Laravel de dev sur le port **8001** (pas 8000, occupé par un autre projet sur cette machine).
- Compte de test : `test.authfix.10767@example.com` / `secret123`.

## Refonte design + intégration complète de l'API (session du 2026-09-19)
Retour utilisateur : « app très basique en design, toutes les fonctionnalités de l'API n'ont pas été intégrées ». Réponse : kit de design partagé (`shared/widgets/app_ui.dart`, `app_avatar.dart`, `media_url.dart` — corrige les images cassées, chemins relatifs non résolus) puis reconstruction par domaine, en relisant chaque page PHP legacy : joueurs/annuaire/parcours/carte de membre/plans, suivi (follow), médias de match, propositions de match, classements, calendrier, groupes de conversation, changement mot de passe/e-mail/téléphone, inscription OTP, mot de passe oublié, module Admin complet (utilisateurs, équipes, compétitions, terrains, éditeur de statut, plans).
Navigation : nouvel onglet « Plus » dans le shell, menu groupé (Matchs & compétitions / Équipes & activités / Communauté / Mon compte / Administration) mirroir de la barre latérale legacy.
Données démo : stades et participants de compétition (`terrains_liaison_competition`, `utilisateurs_liaison_competition`), arbitres sur les matchs (EnrichmentSeeder).
État : `flutter analyze` 0 erreur/0 warning (48 infos), `flutter test` 30/30.
Écarts connus : pièces jointes de messages, présence « vu il y a », pas de vrai paiement, pas de QR code, « Créer un membre » à champs limités, géolocalisation par coordonnées saisies, file hors-ligne non utilisée par les nouvelles vues, match #16 de test resté en base.
