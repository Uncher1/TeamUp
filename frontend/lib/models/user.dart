// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'interest.dart';
import 'skill.dart';

class User {
  final int id;
  final String email;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final String role; // 'user' | 'moderator' | 'admin'
  final String presenceStatus; // 'online' | 'dnd' | 'offline'
  final bool emailVerified;
  final List<UserSkill> skills;
  final List<Interest> interests;

  // Personal / contact
  final String? phone;
  final String? location;

  // Academic
  final String? school;
  final String? department;
  final String? studyYear;

  // Social / links
  final String? github;
  final String? linkedin;
  final String? twitter;
  final String? website;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    this.role = 'user',
    this.presenceStatus = 'online',
    this.emailVerified = true,
    this.skills = const [],
    this.interests = const [],
    this.phone,
    this.location,
    this.school,
    this.department,
    this.studyYear,
    this.github,
    this.linkedin,
    this.twitter,
    this.website,
  });

  /// Handles both the auth payload (`{id, email, full_name}`) and the full
  /// profile from `GET /api/users/me` (adds bio, skills, interests).
  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'user',
        presenceStatus: json['presence_status'] as String? ?? 'online',
        // Absent (legacy payload) → treat as verified so nobody is locked out.
        emailVerified: json['email_verified'] == null
            ? true
            : (json['email_verified'] == 1 || json['email_verified'] == true),
        skills: (json['skills'] as List?)
                ?.map((e) => UserSkill.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        interests: (json['interests'] as List?)
                ?.map((e) => Interest.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        phone: json['phone'] as String?,
        location: json['location'] as String?,
        school: json['school'] as String?,
        department: json['department'] as String?,
        studyYear: json['study_year'] as String?,
        github: json['github'] as String?,
        linkedin: json['linkedin'] as String?,
        twitter: json['twitter'] as String?,
        website: json['website'] as String?,
      );

  User copyWith({
    int? id,
    String? email,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? role,
    String? presenceStatus,
    bool? emailVerified,
    List<UserSkill>? skills,
    List<Interest>? interests,
    String? phone,
    String? location,
    String? school,
    String? department,
    String? studyYear,
    String? github,
    String? linkedin,
    String? twitter,
    String? website,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      presenceStatus: presenceStatus ?? this.presenceStatus,
      emailVerified: emailVerified ?? this.emailVerified,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      school: school ?? this.school,
      department: department ?? this.department,
      studyYear: studyYear ?? this.studyYear,
      github: github ?? this.github,
      linkedin: linkedin ?? this.linkedin,
      twitter: twitter ?? this.twitter,
      website: website ?? this.website,
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
