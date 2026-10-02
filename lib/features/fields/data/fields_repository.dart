import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/local_first_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../../core/sync/sync_service.dart';
import 'models/field.dart';

class FieldsRepository extends LocalFirstRepository<Field> {
  FieldsRepository(AppDatabase db, ApiClient api)
      : super(
          db: db,
          api: api,
          entityType: 'field',
          fromJson: Field.fromJson,
          toJson: (f) => f.toJson(),
          idOf: (f) => f.id.toString(),
        );

  Future<Field> fetchDetail(int id) => fetchAndCache(ApiConstants.fieldById(id), id);

  /// `GET /fields/nearby?lat=&lng=&radius_km=`, Haversine-sorted server-side.
  Future<List<Field>> nearby({required double lat, required double lng, double radiusKm = 10}) async {
    final response = await api.get<dynamic>(
      ApiConstants.fieldsNearby,
      queryParameters: {'lat': lat, 'lng': lng, 'radius_km': radiusKm},
    );
    final body = response.data;
    final list = body is Map && body['data'] is List
        ? body['data'] as List
        : (body is List ? body : const <dynamic>[]);
    return list.map((e) => Field.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// `GET /fields/default` — the club's default field, if configured.
  Future<Field?> defaultField() async {
    final response = await api.get<Map<String, dynamic>>(ApiConstants.fieldsDefault);
    final body = response.data;
    if (body == null) return null;
    final json = body.length == 1 && body.values.first is Map ? Map<String, dynamic>.from(body.values.first as Map) : body;
    return Field.fromJson(json);
  }

  Future<Field> create({
    required String nomTerrain,
    String? lieu,
    double? latitude,
    double? longitude,
    String? photo,
  }) async {
    final result = await mutate(
      operation: 'create',
      method: 'POST',
      endpoint: ApiConstants.fields,
      payload: {
        'nom_terrain': nomTerrain,
        // ignore: use_null_aware_elements
        if (lieu != null) 'lieu': lieu,
        // ignore: use_null_aware_elements
        if (latitude != null) 'latitude': latitude,
        // ignore: use_null_aware_elements
        if (longitude != null) 'longitude': longitude,
        // ignore: use_null_aware_elements
        if (photo != null) 'photo': photo,
      },
      optimisticJson: () => {
        'id': -DateTime.now().millisecondsSinceEpoch,
        'id_utilisateur': 0,
        'nom_terrain': nomTerrain,
        'lieu': lieu,
        'latitude': latitude,
        'longitude': longitude,
        'photo': photo,
        'statut': 1,
      },
    );
    return result!;
  }

  Future<Field> update(
    int id, {
    String? nomTerrain,
    String? lieu,
    double? latitude,
    double? longitude,
    String? photo,
  }) async {
    final result = await mutate(
      operation: 'update',
      method: 'PUT',
      endpoint: ApiConstants.fieldById(id),
      existingId: id.toString(),
      payload: {
        // ignore: use_null_aware_elements
        if (nomTerrain != null) 'nom_terrain': nomTerrain,
        // ignore: use_null_aware_elements
        if (lieu != null) 'lieu': lieu,
        // ignore: use_null_aware_elements
        if (latitude != null) 'latitude': latitude,
        // ignore: use_null_aware_elements
        if (longitude != null) 'longitude': longitude,
        // ignore: use_null_aware_elements
        if (photo != null) 'photo': photo,
      },
      optimisticJson: () => {
        'id': id,
        'id_utilisateur': 0,
        'nom_terrain': nomTerrain,
        'lieu': lieu,
        'latitude': latitude,
        'longitude': longitude,
        'photo': photo,
        'statut': 1,
      },
    );
    return result!;
  }

  Future<void> delete(int id) async {
    await mutate(
      operation: 'delete',
      method: 'DELETE',
      endpoint: ApiConstants.fieldById(id),
      existingId: id.toString(),
      optimisticJson: () => {},
    );
  }

  /// Uploads a new field photo (owner-or-admin on the API side), mirroring
  /// ProfileRepository.uploadAvatar's multipart pattern.
  Future<Field> uploadPhoto(int fieldId, File file) async {
    try {
      final formData = FormData.fromMap({'photo': await MultipartFile.fromFile(file.path)});
      final response = await api.uploadFile<Map<String, dynamic>>(ApiConstants.fieldPhoto(fieldId), formData: formData);
      final field = Field.fromJson(response.data!);
      await db.upsertEntity(entityType, idOf(field), jsonEncode(response.data!), DateTime.now());
      return field;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final fieldsRepositoryProvider = Provider<FieldsRepository>((ref) {
  final repo = FieldsRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
  ref.watch(syncServiceProvider).registerResource(SyncableResource(
        entityType: 'field',
        endpoint: ApiConstants.fields,
        extractItems: SyncableResource.laravelPage,
      ));
  return repo;
});
