import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/storage.dart';
import '../models/user.dart';
import '../repositories/auth_repo.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository repo;
  final TokenStorage storage;

  AuthProvider({required this.repo, required this.storage, ApiClient? api}) {
    api?.onUnauthorized = _onUnauthorized;
  }

  AuthStatus status = AuthStatus.unknown;
  User? user;
  bool busy = false;
  String? error;

  /// First-launch onboarding seen? (device-local). Loaded in [bootstrap].
  bool onboarded = false;

  /// True right after a successful registration, so the shell can route the
  /// new user through profile completion. Cleared on login or once handled.
  bool justRegistered = false;

  /// Called once at launch: restores a session from a stored token.
  Future<void> bootstrap() async {
    onboarded = await storage.readOnboarded();
    final token = await storage.read();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      user = await repo.me();
      status = AuthStatus.authenticated;
    } catch (_) {
      await storage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _run(() => repo.login(email.trim(), password), markRegistered: false);

  Future<bool> register(String fullName, String email, String password) =>
      _run(() => repo.register(fullName.trim(), email.trim(), password), markRegistered: true);

  /// Authenticates with Google using a GIS ID token.
  Future<bool> loginWithGoogle(String idToken) =>
      _run(() => repo.google(idToken), markRegistered: false);

  /// Marks first-launch onboarding as completed (persisted).
  Future<void> setOnboarded() async {
    onboarded = true;
    await storage.setOnboarded();
    notifyListeners();
  }

  /// Called once the post-registration profile-completion step is handled.
  void clearJustRegistered() {
    justRegistered = false;
    notifyListeners();
  }

  Future<bool> _run(Future<AuthResult> Function() action, {required bool markRegistered}) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await action();
      await storage.write(result.token);
      // Pull the full profile so skills/interests are available app-wide.
      try {
        user = await repo.me();
      } catch (_) {
        user = result.user;
      }
      status = AuthStatus.authenticated;
      justRegistered = markRegistered;
      return true;
    } catch (e) {
      error = ApiClient.messageFromError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void setUser(User updated) {
    user = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    await storage.clear();
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _onUnauthorized() {
    user = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
