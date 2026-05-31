// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import '../core/api_client.dart';

/// A user row in the admin panel.
class AdminUser {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;

  AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as int,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'user',
        avatarUrl: j['avatar_url'] as String?,
      );
}

class AdminRepository {
  final ApiClient api;
  AdminRepository(this.api);

  /// Admin-only: list users, optionally filtered by name/email.
  Future<List<AdminUser>> listUsers({String q = ''}) async {
    final res = await api.dio
        .get('/admin/users', queryParameters: q.isEmpty ? null : {'q': q});
    return (res.data as List)
        .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin-only: set a user's role ('user' | 'moderator' | 'admin').
  Future<void> setRole(int userId, String role) async {
    await api.dio.patch('/admin/users/$userId/role', data: {'role': role});
  }
}
