import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../players/data/models/player.dart';

/// Subscription plan as returned by `GET /plans` (active plans only).
class PlanInfo {
  final int id;
  final String nom;
  final double prix;
  final String? description;
  final String? image;
  const PlanInfo({required this.id, required this.nom, required this.prix, this.description, this.image});

  factory PlanInfo.fromJson(Map<String, dynamic> j) => PlanInfo(
        id: asInt(j['id']) ?? 0,
        nom: asStr(j['nom']) ?? '',
        prix: asDouble(j['prix']) ?? 0,
        description: asStr(j['description']),
        image: asStr(j['image']),
      );

  /// "10 000 F CFA" (legacy `number_format($prix, 0, ',', ' ')`).
  String get priceLabel {
    final digits = prix.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return '$buf F CFA';
  }
}

class PlansApi {
  final ApiClient _api;
  PlansApi(this._api);

  Future<List<PlanInfo>> plans() async {
    try {
      final r = await _api.get<List<dynamic>>('/plans');
      return (r.data ?? []).map((e) => PlanInfo.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final plansApiProvider = Provider<PlansApi>((ref) => PlansApi(ref.watch(apiClientProvider)));

final plansProvider = FutureProvider.autoDispose<List<PlanInfo>>((ref) => ref.watch(plansApiProvider).plans());
