import 'interest.dart';
import 'skill.dart';

class User {
  final int id;
  final String email;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final List<UserSkill> skills;
  final List<Interest> interests;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    this.skills = const [],
    this.interests = const [],
  });

  /// Handles both the auth payload (`{id, email, full_name}`) and the full
  /// profile from `GET /api/users/me` (adds bio, skills, interests).
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        skills: (json['skills'] as List?)
                ?.map((e) => UserSkill.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        interests: (json['interests'] as List?)
                ?.map((e) => Interest.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
