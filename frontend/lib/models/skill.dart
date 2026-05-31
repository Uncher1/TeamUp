// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

/// A skill from the catalog (`GET /api/skills`).
class Skill {
  final int id;
  final String name;
  final String? category;

  const Skill({required this.id, required this.name, this.category});

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Skill && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A user's skill with a self-declared proficiency level (1..5).
class UserSkill {
  final int id;
  final String name;
  final String? category;
  final int level;

  const UserSkill({
    required this.id,
    required this.name,
    this.category,
    required this.level,
  });

  factory UserSkill.fromJson(Map<String, dynamic> json) => UserSkill(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String?,
        level: (json['level'] as num).toInt(),
      );
}
