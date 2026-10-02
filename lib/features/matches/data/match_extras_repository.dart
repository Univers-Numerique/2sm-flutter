import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'models/match_game.dart';
import 'models/match_overview.dart';

/// Formulaire complet "Programmer un match" / "Proposer un match amical".
class MatchDraft {
  final int? id;
  final int homeTeamId;
  final int awayTeamId;
  final String dateDebut;
  final String heureDebut;
  final int competitionId;
  final String? categorie;
  final String? genre;
  final int? lieu;
  final int arbitrePrincipal;
  final int arbitreTouche1;
  final int arbitreTouche2;
  final int commentateur1;
  final int commentateur2;
  final int chronometreur;
  final int annonciateur;

  const MatchDraft({
    this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.dateDebut,
    required this.heureDebut,
    this.competitionId = 0,
    this.categorie,
    this.genre,
    this.lieu,
    this.arbitrePrincipal = 0,
    this.arbitreTouche1 = 0,
    this.arbitreTouche2 = 0,
    this.commentateur1 = 0,
    this.commentateur2 = 0,
    this.chronometreur = 0,
    this.annonciateur = 0,
  });

  Map<String, dynamic> toJson() => {
        'id_equipe_domicile': homeTeamId,
        'id_equipe_exterieur': awayTeamId,
        'date_debut': dateDebut,
        'heure_debut': heureDebut,
        'id_competition': competitionId == 0 ? null : competitionId,
        'categorie': categorie,
        'genre': genre,
        'lieu': lieu,
        'id_arbitre_principal': arbitrePrincipal,
        'id_arbitre_de_touche_1': arbitreTouche1,
        'id_arbitre_de_touche_2': arbitreTouche2,
        'id_commentateur_1': commentateur1,
        'id_commentateur_2': commentateur2,
        'id_chronometreur': chronometreur,
        'id_annonciateur_public': annonciateur,
      }..removeWhere((k, v) => v == null);
}

/// Appels "en ligne" liés au match : fiche complète, pause/reprise,
/// convocations, création/modification avec officiels.
class MatchExtrasRepository {
  final ApiClient _api;
  MatchExtrasRepository(this._api);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  /// Utilisateurs occupant un poste d'officiel ("Arbitre", "Commentateur"...).
  Future<List<({int id, String name})>> usersByPoste(String poste) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>('/users', queryParameters: {'poste': poste, 'per_page': 100});
        final data = r.data?['data'];
        return (data is List ? data : const [])
            .whereType<Map>()
            .map((e) => (id: (e['id'] as num).toInt(), name: '${e['nom'] ?? ''} ${e['prenoms'] ?? ''}'.trim()))
            .toList();
      });

  Future<MatchOverview> overview(int id) => _guard(() async {
        final r = await _api.get<Map<String, dynamic>>('/matches/$id/overview');
        return MatchOverview.fromJson(r.data ?? const {});
      });

  /// Liste paginée côté serveur avec tous les filtres du legacy.
  Future<List<MatchGame>> list({
    int? statut,
    int? competitionId,
    String? categorie,
    String? genre,
    String? nom,
    bool mine = false,
  }) =>
      _guard(() async {
        final r = await _api.get<Map<String, dynamic>>('/matches', queryParameters: {
          if (statut != null) 'status': statut,
          if (competitionId != null) 'competition_id': competitionId,
          if (categorie != null && categorie.isNotEmpty) 'categorie': categorie,
          if (genre != null && genre.isNotEmpty) 'genre': genre,
          if (nom != null && nom.isNotEmpty) 'nom': nom,
          if (mine) 'mine': 1,
          'per_page': 100,
        });
        final data = r.data?['data'];
        return (data is List ? data : const [])
            .whereType<Map>()
            .map((e) => MatchGame.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });

  Future<MatchGame> save(MatchDraft draft) => _guard(() async {
        final r = draft.id == null
            ? await _api.post<Map<String, dynamic>>('/matches', data: draft.toJson())
            : await _api.put<Map<String, dynamic>>('/matches/${draft.id}', data: draft.toJson());
        return MatchGame.fromJson(r.data ?? const {});
      });

  Future<void> pause(int id) => _guard(() => _api.post('/matches/$id/pause'));
  Future<void> resume(int id) => _guard(() => _api.post('/matches/$id/resume'));

  /// Convoque / retire un joueur pour ce match (responsable de l'équipe).
  Future<int> toggleSelection(int matchId, int teamId, int userId) => _guard(() async {
        final r = await _api.post<Map<String, dynamic>>('/matches/$matchId/teams/$teamId/selection/$userId');
        return (r.data?['statut'] as num?)?.toInt() ?? 0;
      });
}

final matchExtrasRepositoryProvider =
    Provider<MatchExtrasRepository>((ref) => MatchExtrasRepository(ref.watch(apiClientProvider)));

final matchOverviewProvider = FutureProvider.autoDispose.family<MatchOverview, int>((ref, id) {
  return ref.watch(matchExtrasRepositoryProvider).overview(id);
});

final officialsProvider = FutureProvider.autoDispose.family<List<({int id, String name})>, String>((ref, poste) {
  return ref.watch(matchExtrasRepositoryProvider).usersByPoste(poste);
});
