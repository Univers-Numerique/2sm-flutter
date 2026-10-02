import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../matches/data/models/match_game.dart';

/// Statuts de `propositions.statut` : 0 en attente, 1 acceptée, 2 refusée.
class PropositionStatus {
  static const pending = 0;
  static const accepted = 1;
  static const refused = 2;
}

class PropositionUser {
  final int id;
  final String name;
  final String? avatar;
  const PropositionUser({required this.id, required this.name, this.avatar});

  factory PropositionUser.fromJson(Map<String, dynamic>? j) => PropositionUser(
        id: (j?['id'] as num?)?.toInt() ?? 0,
        name: '${j?['prenoms'] ?? ''} ${j?['nom'] ?? ''}'.trim(),
        avatar: j?['avatar'] as String?,
      );
}

/// Une proposition (match amical) : proposeur, proposé et match concerné.
class Proposition {
  final int id;
  final String tables;
  final int entityId;
  final int statut;
  final PropositionUser proposer;
  final PropositionUser proposed;
  final MatchGame? match;
  final String? createdAt;

  const Proposition({
    required this.id,
    required this.tables,
    required this.entityId,
    required this.statut,
    required this.proposer,
    required this.proposed,
    this.match,
    this.createdAt,
  });

  bool get isPending => statut == PropositionStatus.pending;

  factory Proposition.fromJson(Map<String, dynamic> j) => Proposition(
        id: (j['id'] as num).toInt(),
        tables: (j['tables'] as String?) ?? 'matchs',
        entityId: (j['id_entre'] as num?)?.toInt() ?? 0,
        statut: (j['statut'] as num?)?.toInt() ?? 0,
        proposer: PropositionUser.fromJson(j['proposer'] is Map ? Map<String, dynamic>.from(j['proposer'] as Map) : null),
        proposed: PropositionUser.fromJson(j['proposed'] is Map ? Map<String, dynamic>.from(j['proposed'] as Map) : null),
        match: j['match'] is Map ? MatchGame.fromJson(Map<String, dynamic>.from(j['match'] as Map)) : null,
        createdAt: j['created_at'] as String?,
      );
}

/// `GET /propositions` et `PUT /propositions/{id}` (accepter/refuser).
class PropositionsRepository {
  final ApiClient _api;
  PropositionsRepository(this._api);

  Future<List<Proposition>> list() async {
    try {
      final r = await _api.get<Map<String, dynamic>>('/propositions');
      final data = r.data?['data'];
      return (data is List ? data : const [])
          .whereType<Map>()
          .map((e) => Proposition.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> answer(int id, {required bool accept}) async {
    try {
      await _api.put('/propositions/$id', data: {'statut': accept ? PropositionStatus.accepted : PropositionStatus.refused});
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final propositionsRepositoryProvider =
    Provider<PropositionsRepository>((ref) => PropositionsRepository(ref.watch(apiClientProvider)));

final propositionsProvider = FutureProvider.autoDispose<List<Proposition>>((ref) {
  return ref.watch(propositionsRepositoryProvider).list();
});
