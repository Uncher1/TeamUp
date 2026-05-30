import 'package:dio/dio.dart';
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

  /// HTTP status code of the last failed auth call (e.g. 409 = duplicate).
  int? errorCode;

  /// True when the last Google sign-in created a brand-new account.
  bool isNewAccount = false;

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

  Future<bool> register(String fullName, String email, String password,
          {String language = 'en'}) =>
      _run(() => repo.register(fullName.trim(), email.trim(), password, language: language),
          markRegistered: true);

  /// Authenticates with Google using a GIS ID token. A brand-new Google
  /// account is routed through profile completion (the next step), just like a
  /// classic sign-up; an existing account logs straight in.
  Future<bool> loginWithGoogle(String idToken, {String language = 'en'}) async {
    final ok = await _run(() => repo.google(idToken, language: language), markRegistered: false);
    if (ok && isNewAccount) {
      justRegistered = true;
      notifyListeners();
    }
    return ok;
  }

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
    errorCode = null;
    notifyListeners();
    try {
      final result = await action();
      isNewAccount = result.isNew;
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
      errorCode = e is DioException ? e.response?.statusCode : null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Confirms the e-mail verification code; on success refreshes [user] so the
  /// gate (which keys off [User.emailVerified]) lets the user through.
  Future<bool> verifyEmail(String code) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await repo.verifyEmail(code);
      try {
        user = await repo.me();
      } catch (_) {
        user = user?.copyWith(emailVerified: true);
      }
      return true;
    } catch (e) {
      error = ApiClient.messageFromError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Asks the backend to e-mail a fresh verification code.
  Future<bool> resendCode() async {
    try {
      await repo.resendCode();
      return true;
    } catch (e) {
      error = ApiClient.messageFromError(e);
      notifyListeners();
      return false;
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
