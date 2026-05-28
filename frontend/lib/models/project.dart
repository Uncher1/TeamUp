import 'interest.dart';

class RequiredSkill {
  final int id;
  final String name;
  final int weight;
  const RequiredSkill({required this.id, required this.name, required this.weight});

  factory RequiredSkill.fromJson(Map<String, dynamic> json) => RequiredSkill(
        id: json['id'] as int,
        name: json['name'] as String,
        weight: (json['weight'] as num).toInt(),
      );
}

class ProjectMember {
  final int id;
  final String fullName;
  final String role;
  const ProjectMember({required this.id, required this.fullName, required this.role});

  factory ProjectMember.fromJson(Map<String, dynamic> json) => ProjectMember(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        role: json['role'] as String? ?? 'member',
      );
}

class Project {
  final int id;
  final String title;
  final String description;
  final String status;
  final int ownerId;
  final String ownerName;
  final List<RequiredSkill> requiredSkills;
  final List<Interest> interests;
  final List<ProjectMember> members;

  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    this.requiredSkills = const [],
    this.interests = const [],
    this.members = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        ownerId: json['owner_id'] as int,
        ownerName: json['owner_name'] as String? ?? '',
        requiredSkills: (json['required_skills'] as List?)
                ?.map((e) => RequiredSkill.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        interests: (json['interests'] as List?)
                ?.map((e) => Interest.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        members: (json['members'] as List?)
                ?.map((e) => ProjectMember.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
