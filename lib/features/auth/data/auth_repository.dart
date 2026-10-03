import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/failure.dart';
import 'models/app_user.dart';

/// Auth is intentionally kept outside the generic sync/outbox machinery:
/// login/register/logout must work immediately against the network (you
/// cannot authenticate against a local cache), but the *result* — token and
/// profile — is persisted so the app can still open to a known session and
/// show cached data while offline.
class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<AppUser> login(String emailOrPhone, String password) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiConstants.login, data: {
        'EmailOuTelephone': emailOrPhone,
        'pass': password,
      });
      return await _persistSession(response.data!);
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  Future<AppUser> register({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiConstants.register, data: {
        'nom': nom,
        'prenoms': prenoms,
        'email': email,
        'telephone': telephone,
        'pass': password,
      });
      return await _persistSession(response.data!);
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  /// Registration first step of the two-step flow: creates the account and
  /// returns the user + token WITHOUT persisting a session, so the app can
  /// ask for the phone OTP before letting the user in (see
  /// [completeSession]).
  Future<({AppUser user, String token})> registerPending({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String password,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiConstants.register, data: {
        'nom': nom,
        'prenoms': prenoms,
        'email': email,
        'telephone': telephone,
        'pass': password,
      });
      final body = response.data!;
      return (user: AppUser.fromJson(body['user'] as Map<String, dynamic>), token: body['token'] as String);
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  Future<AppUser> completeSession(AppUser user, String token) async {
    return _persistSession({'user': user.toJson(), 'token': token});
  }

  /// `POST /auth/resend-otp` - returns the OTP in dev (no SMS gateway).
  Future<String?> resendOtp(String telephone) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiConstants.resendOtp, data: {'telephone': telephone});
      return response.data?['otp']?.toString();
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  /// `POST /auth/verify-phone`.
  Future<void> verifyPhone(String telephone, String otp) async {
    try {
      await _api.post(ApiConstants.verifyPhone, data: {'telephone': telephone, 'otp': otp});
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  /// `POST /auth/change-password` (current user, no id needed).
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      await _api.post(ApiConstants.changePassword, data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  /// `POST /auth/request-contact-change` - returns the OTP in dev.
  Future<String?> requestContactChange({required String type, required String newValue}) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiConstants.requestContactChange, data: {
        'type': type,
        'new_value': newValue,
      });
      return response.data?['otp']?.toString();
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  /// `POST /auth/confirm-contact-change` - returns the refreshed user.
  Future<AppUser> confirmContactChange(String otp) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiConstants.confirmContactChange, data: {'otp': otp});
      final user = AppUser.fromJson(response.data!['user'] as Map<String, dynamic>);
      await updateCachedUser(user);
      return user;
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  /// `DELETE /users/{id}` - the API soft-deactivates the account.
  Future<void> deleteAccount(int userId) async {
    try {
      await _api.delete(ApiConstants.userById(userId));
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.logout);
    } catch (_) {
      // Best-effort: even if the server call fails (offline), clear locally.
    }
    await _clearSession();
  }

  /// Session refusée par le serveur (jeton expiré ou révoqué) : on l'oublie
  /// pour ne pas la reproposer à chaque lancement ; l'app reste consultable.
  Future<void> forgetSession() => _clearSession();

  /// Returns the OTP echoed by the API in dev (no SMS/e-mail gateway).
  Future<String?> forgotPassword(String emailOrPhone) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(ApiConstants.forgotPassword, data: {'email_ou_telephone': emailOrPhone});
      return response.data?['otp']?.toString();
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  Future<void> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _api.post(ApiConstants.resetPassword, data: {
        'email_ou_telephone': emailOrPhone,
        'otp': otp,
        'new_password': newPassword,
      });
    } on Object catch (e) {
      throw _toFailure(e);
    }
  }

  /// Restores the last known session from local storage — works offline —
  /// then, if a token exists, best-effort refreshes it from the server.
  Future<AppUser?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.accessToken);
    final userJson = prefs.getString(StorageKeys.currentUserJson);
    if (token == null || userJson == null) return null;

    _api.setAuthToken(token);
    final cachedUser = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);

    try {
      final response = await _api.get<Map<String, dynamic>>(ApiConstants.currentUser);
      return await _persistSession({'user': response.data, 'token': token});
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _clearSession(); // jeton refusé : on continue en visiteur
        return null;
      }
      return cachedUser; // hors ligne ou serveur indisponible : profil en cache
    } catch (_) {
      // Offline or server error: keep going with the cached profile.
      return cachedUser;
    }
  }

  Future<AppUser> _persistSession(Map<String, dynamic> body) async {
    final userJson = body['user'] as Map<String, dynamic>? ?? body;
    final token = body['token'] as String?;
    final user = AppUser.fromJson(userJson);

    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(StorageKeys.accessToken, token);
      _api.setAuthToken(token);
    }
    await prefs.setString(StorageKeys.currentUserJson, jsonEncode(user.toJson()));
    return user;
  }

  /// Persists a locally-updated profile (e.g. after an edit-profile or
  /// avatar-upload call already hit the API) without another network call.
  Future<void> updateCachedUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.currentUserJson, jsonEncode(user.toJson()));
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.accessToken);
    await prefs.remove(StorageKeys.currentUserJson);
    _api.clearAuthToken();
  }

  Failure _toFailure(Object e) {
    if (e is Failure) return e;
    if (e is DioException) return Failure.fromDioException(e);
    return const Failure('Une erreur est survenue.');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
