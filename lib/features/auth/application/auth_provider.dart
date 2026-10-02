import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../data/models/app_user.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthAuthenticated extends AuthState {
  final AppUser user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthUnknown()) {
    _restore();
  }

  Future<void> _restore() async {
    final user = await _repository.restoreSession();
    state = user != null ? AuthAuthenticated(user) : const AuthUnauthenticated();
  }

  Future<void> login(String emailOrPhone, String password) async {
    final user = await _repository.login(emailOrPhone, password);
    state = AuthAuthenticated(user);
  }

  Future<void> register({
    required String nom,
    required String prenoms,
    required String email,
    required String telephone,
    required String password,
  }) async {
    final user = await _repository.register(
      nom: nom,
      prenoms: prenoms,
      email: email,
      telephone: telephone,
      password: password,
    );
    state = AuthAuthenticated(user);
  }

  /// Second step of registration: the OTP was verified, open the session.
  Future<void> completeRegistration(AppUser user, String token) async {
    final persisted = await _repository.completeSession(user, token);
    state = AuthAuthenticated(persisted);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Called by the API client's 401 interceptor from anywhere in the app.
  void forceLogout() {
    state = const AuthUnauthenticated();
  }

  /// Reflects a profile/avatar change already applied via the API (the
  /// caller passes back the fresh [AppUser] from that response) without an
  /// extra round-trip.
  Future<void> updateUser(AppUser user) async {
    state = AuthAuthenticated(user);
    await _repository.updateCachedUser(user);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.watch(authRepositoryProvider));
  final api = ref.watch(apiClientProvider);
  void onUnauthorized() => notifier.forceLogout();
  api.unauthorized.addListener(onUnauthorized);
  ref.onDispose(() => api.unauthorized.removeListener(onUnauthorized));
  return notifier;
});
