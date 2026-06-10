// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

class Application {
  final int id;
  final String status;
  final String? message;
  final DateTime createdAt;
  final int userId;
  final String fullName;
  final String email;

  const Application({
    required this.id,
    required this.status,
    this.message,
    required this.createdAt,
    required this.userId,
    required this.fullName,
    required this.email,
  });

  factory Application.fromJson(Map<String, dynamic> j) => Application(
        id: j['id'] as int,
        status: j['status'] as String? ?? 'pending',
        message: j['message'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        userId: j['user_id'] as int,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
      );
}
