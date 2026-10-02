import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'admin_endpoints.dart';
import 'models/plan.dart';

/// Subscription plans (`PlanController`). `GET /plans` only returns active
/// plans, so the back-office reads `GET /admin/plans` (all plans).
class PlansRepository {
  final ApiClient _api;
  PlansRepository(this._api);

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<List<Plan>> fetchAll() => _guard(() async {
        final response = await _api.get<List<dynamic>>(AdminEndpoints.plansAll);
        return (response.data ?? []).map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<Plan> create({
    required String nom,
    required double prix,
    String? description,
    int statut = 1,
    XFile? image,
  }) =>
      _guard(() async {
        final response = await _api.post<Map<String, dynamic>>(
          AdminEndpoints.plans,
          data: {
            'nom': nom,
            'prix': prix,
            if (description != null && description.isNotEmpty) 'description': description,
            'statut': statut,
          },
        );
        var plan = Plan.fromJson(response.data!);
        if (image != null) plan = await uploadImage(plan.id, image);
        return plan;
      });

  Future<Plan> update(
    int id, {
    String? nom,
    double? prix,
    String? description,
    int? statut,
    XFile? image,
  }) =>
      _guard(() async {
        final response = await _api.put<Map<String, dynamic>>(
          '${AdminEndpoints.plans}/$id',
          data: {
            'nom': ?nom,
            'prix': ?prix,
            'description': ?description,
            'statut': ?statut,
          },
        );
        var plan = Plan.fromJson(response.data!);
        if (image != null) plan = await uploadImage(id, image);
        return plan;
      });

  /// `POST /plans/{id}/image` — the legacy plan form's image field.
  Future<Plan> uploadImage(int id, XFile file) => _guard(() async {
        final form = FormData.fromMap({'image': await MultipartFile.fromFile(file.path, filename: file.name)});
        final response = await _api.uploadFile<Map<String, dynamic>>(AdminEndpoints.planImage(id), formData: form);
        return Plan.fromJson(response.data!);
      });

  Future<void> delete(int id) => _guard(() async {
        await _api.delete('${AdminEndpoints.plans}/$id');
      });
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(apiClientProvider));
});
