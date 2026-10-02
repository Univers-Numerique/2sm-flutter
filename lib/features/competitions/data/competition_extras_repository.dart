import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'models/competition.dart';
import 'models/competition_overview.dart';

/// Appels réseau "en ligne" de la compétition (fiche complète, classements
/// globaux, ressources, planification). Volontairement hors outbox : ces
/// écrans ont besoin de la réponse du serveur tout de suite (classements,
/// nombre de matchs créés...).
class CompetitionExtrasRepository {
  final ApiClient _api;
  CompetitionExtrasRepository(this._api);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// Liste filtrée côté serveur (statut, catégorie, genre, nom, "mes compétitions").
  Future<List<Competition>> list({int? statut, String? categorie, String? genre, String? nom, bool mine = false}) =>
      _guard(() async {
        final r = await _api.get<Map<String, dynamic>>('/competitions', queryParameters: {
          if (statut != null) 'statut': statut,
          if (categorie != null && categorie.isNotEmpty) 'categorie': categorie,
          if (genre != null && genre.isNotEmpty) 'genre': genre,
          if (nom != null && nom.isNotEmpty) 'nom': nom,
          if (mine) 'mine': 1,
          'per_page': 100,
        });
        final data = r.data?['data'];
        return (data is List ? data : const [])
            .whereType<Map>()
            .map((e) => Competition.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });

  Future<CompetitionOverview> overview(int id) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>('/competitions/$id/overview');
        return CompetitionOverview.fromJson(r.data ?? const {});
      });

  Future<TeamSelectionInfo> teamSelection(int competitionId, int teamId) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>('/competitions/$competitionId/teams/$teamId/selections');
        return TeamSelectionInfo.fromJson(r.data ?? const {});
      });

  /// Ajoute (selected) ou retire un joueur de la sélection de l'équipe.
  Future<void> setPlayerSelected(int competitionId, int teamId, int userId, bool selected) => _guard(() async {
        final base = '/competitions/$competitionId/teams/$teamId/selection';
        if (selected) {
          await _api.post(base, data: {'id_utilisateur': userId});
        } else {
          await _api.delete('$base/$userId');
        }
      });

  /// `GET /standings` — classements de toutes les compétitions.
  Future<List<CompetitionStandings>> standings() => _guard(() async {
        final r = await _api.get<List<dynamic>>('/standings');
        return (r.data ?? const [])
            .whereType<Map>()
            .map((e) => CompetitionStandings.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });

  /// Ouvrir / fermer la sélection des joueurs (`competitions.selection`).
  Future<void> setSelectionOpen(int id, bool open) =>
      _guard(() => _api.put('/competitions/$id', data: {'selection': open ? 1 : 0}));

  Future<void> register(int competitionId, int teamId) =>
      _guard(() => _api.post('/competitions/$competitionId/register', data: {'id_equipe': teamId}));

  /// "Programmer plusieurs matchs" — renvoie le nombre de matchs créés.
  Future<int> schedule(int id, ScheduleParams params) => _guard(() async {
        final r = await _api.post<Map<String, dynamic>>('/competitions/$id/generate-fixtures', data: params.toJson());
        return (r.data?['created'] as num?)?.toInt() ?? 0;
      });

  /// "Effacer les matchs" — renvoie le nombre de matchs supprimés.
  Future<int> clearMatches(int id) => _guard(() async {
        final r = await _api.delete<Map<String, dynamic>>('/competitions/$id/matches');
        return (r.data?['deleted'] as num?)?.toInt() ?? 0;
      });

  /// `type` : utilisateurs | equipes | terrains.
  Future<List<CompetitionResource>> resources(int id, String type, {String? nom, String? genre, String? poste}) =>
      _guard(() async {
        final r = await _api.get<Map<String, dynamic>>(
          '/competitions/$id/resources/$type',
          queryParameters: {
            if (nom != null && nom.isNotEmpty) 'nom': nom,
            if (genre != null && genre.isNotEmpty) 'genre': genre,
            if (poste != null && poste.isNotEmpty) 'poste': poste,
          },
        );
        final body = r.data ?? const {};
        final linked = body['linked'];
        final linkedIds = <int>{};
        if (linked is Map) {
          linked.forEach((k, v) {
            if ((v is num ? v.toInt() : int.tryParse('$v') ?? 0) == 1) linkedIds.add(int.parse('$k'));
          });
        }
        final items = (body['items'] is Map ? (body['items'] as Map)['data'] : null) as List? ?? const [];
        return items.whereType<Map>().map((raw) {
          final j = Map<String, dynamic>.from(raw);
          final id = (j['id'] as num).toInt();
          switch (type) {
            case 'utilisateurs':
              return CompetitionResource(
                id: id,
                title: '${j['nom'] ?? ''} ${j['prenoms'] ?? ''}'.trim(),
                subtitle: [j['poste'], if (j['age'] != null) '${j['age']} ans'].whereType<Object>().join(' · '),
                image: j['avatar'] as String?,
                linked: linkedIds.contains(id),
              );
            case 'equipes':
              final owner = j['owner'] is Map ? Map<String, dynamic>.from(j['owner'] as Map) : null;
              return CompetitionResource(
                id: id,
                title: '${j['nom'] ?? ''}',
                subtitle: [j['lieu'], if (owner != null) 'Resp. ${owner['prenoms'] ?? ''} ${owner['nom'] ?? ''}'].whereType<Object>().join(' · '),
                image: j['logo'] as String?,
                linked: linkedIds.contains(id),
              );
            default:
              return CompetitionResource(
                id: id,
                title: '${j['nom_terrain'] ?? ''}',
                subtitle: j['lieu'] as String?,
                image: j['photo'] as String?,
                linked: linkedIds.contains(id),
              );
          }
        }).toList();
      });

  Future<bool> toggleResource(int id, String type, int resourceId) => _guard(() async {
        final r = await _api.post<Map<String, dynamic>>('/competitions/$id/resources/$type/$resourceId');
        return r.data?['linked'] == true;
      });

  /// Crée (id == null) ou modifie une compétition ; renvoie l'objet serveur.
  Future<Competition> save({
    int? id,
    required String nom,
    String? description,
    String? categorie,
    String? genre,
    String? dateDebut,
    String? heureDebut,
    String? saison,
  }) =>
      _guard(() async {
        final data = {
          'nom': nom,
          'description': description,
          'categorie': categorie,
          'genre': genre,
          'date_debut': dateDebut,
          'heure_debut': heureDebut,
          'saison': saison,
        };
        final r = id == null
            ? await _api.post<Map<String, dynamic>>('/competitions', data: data)
            : await _api.put<Map<String, dynamic>>('/competitions/$id', data: data);
        return Competition.fromJson(r.data ?? const {});
      });

  Future<void> uploadCover(int id, File file) => _guard(() async {
        final form = FormData.fromMap({'photo': await MultipartFile.fromFile(file.path)});
        await _api.uploadFile('/competitions/$id/photo', formData: form);
      });
}

final competitionExtrasRepositoryProvider =
    Provider<CompetitionExtrasRepository>((ref) => CompetitionExtrasRepository(ref.watch(apiClientProvider)));

final competitionOverviewProvider = FutureProvider.autoDispose.family<CompetitionOverview, int>((ref, id) {
  return ref.watch(competitionExtrasRepositoryProvider).overview(id);
});

final globalStandingsProvider = FutureProvider.autoDispose<List<CompetitionStandings>>((ref) {
  return ref.watch(competitionExtrasRepositoryProvider).standings();
});

final teamSelectionProvider = FutureProvider.autoDispose.family<TeamSelectionInfo, ({int competitionId, int teamId})>((ref, a) {
  return ref.watch(competitionExtrasRepositoryProvider).teamSelection(a.competitionId, a.teamId);
});

final allCompetitionsProvider = FutureProvider.autoDispose<List<Competition>>((ref) {
  return ref.watch(competitionExtrasRepositoryProvider).list();
});
