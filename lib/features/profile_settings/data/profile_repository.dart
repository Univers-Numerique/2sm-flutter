import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import '../../auth/data/models/app_user.dart';
import 'models/account_settings.dart';

/// Profile and settings are singletons per user rather than a list, so this
/// doesn't extend [LocalFirstRepository] — but it follows the same rule: the
/// UI reads the cached copy, mutations go straight to the API (profile edits
/// are rare enough that queuing them offline isn't worth the complexity a
/// first pass — surfaced as a normal [Failure] if there's no connection).
class ProfileRepository {
  final AppDatabase _db;
  final ApiClient _api;
  static const _entityType = 'profile';
  static const _settingsType = 'settings';

  ProfileRepository(this._db, this._api);

  Future<AppUser> updateProfile(int userId, Map<String, dynamic> fields) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(ApiConstants.userById(userId), data: fields);
      final user = AppUser.fromJson(response.data!);
      await _db.upsertEntity(_entityType, userId.toString(), jsonEncode(user.toJson()), DateTime.now());
      return user;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<AppUser> uploadAvatar(int userId, File file) async {
    try {
      final formData = FormData.fromMap({'avatar': await MultipartFile.fromFile(file.path)});
      final response = await _api.uploadFile<Map<String, dynamic>>(ApiConstants.userAvatar(userId), formData: formData);
      final user = AppUser.fromJson(response.data!);
      await _db.upsertEntity(_entityType, userId.toString(), jsonEncode(user.toJson()), DateTime.now());
      return user;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<void> changePassword(int userId, {required String currentPassword, required String newPassword}) async {
    try {
      await _api.post(ApiConstants.userChangePassword(userId), data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }

  Future<AccountSettings> fetchSettings() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(ApiConstants.settings);
      final settings = AccountSettings.fromJson(response.data!);
      await _db.upsertEntity(_settingsType, 'me', jsonEncode(settings.toJson()), DateTime.now());
      return settings;
    } on DioException catch (e) {
      final cached = await _db.findOne(_settingsType, 'me');
      if (cached != null) return AccountSettings.fromJson(jsonDecode(cached.data) as Map<String, dynamic>);
      throw Failure.fromDioException(e);
    }
  }

  Future<AccountSettings> updateSettings(AccountSettings settings) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(ApiConstants.settings, data: settings.toJson());
      final updated = AccountSettings.fromJson(response.data!);
      await _db.upsertEntity(_settingsType, 'me', jsonEncode(updated.toJson()), DateTime.now());
      return updated;
    } on DioException catch (e) {
      throw Failure.fromDioException(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});
