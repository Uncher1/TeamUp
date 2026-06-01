// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import '../core/api_client.dart';
import '../models/application.dart';
import '../models/project.dart';

class ProjectRepository {
  final ApiClient api;
  ProjectRepository(this.api);

  Future<List<Project>> list() async {
    final res = await api.dio.get('/projects');
    return (res.data as List)
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Project>> myProjects() async {
    final res = await api.dio.get('/projects/mine');
    return (res.data as List)
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Project> detail(int id) async {
    final res = await api.dio.get('/projects/$id');
    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  /// [requiredSkills] is a list of {skill_id, weight}; [interests] a list of ids.
  Future<Project> create({
    required String title,
    required String description,
    List<Map<String, int>> requiredSkills = const [],
    List<int> interests = const [],
    String? category,
    int? teamSize,
    String? timeline,
    String? avatarUrl,
  }) async {
    final res = await api.dio.post('/projects', data: {
      'title': title,
      'description': description,
      'required_skills': requiredSkills,
      'interests': interests,
      'category': category,
      'team_size': teamSize,
      'timeline': timeline,
      'avatar_url': ?avatarUrl,
    });
    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  /// Deletes a project (its owner, or any project for a moderator/admin).
  Future<void> deleteProject(int projectId) async {
    await api.dio.delete('/projects/$projectId');
  }

  Future<void> apply(int projectId, {String? message}) async {
    await api.dio.post('/projects/$projectId/apply', data: {
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }

  Future<List<Application>> applications(int projectId) async {
    final res = await api.dio.get('/projects/$projectId/applications');
    return (res.data as List)
        .map((e) => Application.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> decideApplication(int projectId, int appId, String action) async {
    await api.dio.post('/projects/$projectId/applications/$appId', data: {'action': action});
  }
}
