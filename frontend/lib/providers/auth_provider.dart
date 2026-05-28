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

  /// Called once at launch: restores a session from a stored token.
  Future<void> bootstrap() async {
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
      _run(() => repo.login(email.trim(), password));

  Future<bool> register(String fullName, String email, String password) =>
      _run(() => repo.register(fullName.trim(), email.trim(), password));

  Future<bool> _run(Future<AuthResult> Function() action) async {
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
