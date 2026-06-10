// TeamUp - team-matching social network
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
    double skillWeight = 0.70,
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
      'skill_weight': skillWeight,
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

  // ── Team membership / settings / invites ───────────────────────────────────

  /// {is_owner, is_member, allow_member_invite, can_invite}
  Future<Map<String, dynamic>> teamMembership(int projectId) async {
    final res = await api.dio.get('/projects/$projectId/membership');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> leaveTeam(int projectId) async {
    await api.dio.delete('/projects/$projectId/members/me');
  }

  Future<void> setTeamSettings(int projectId, {required bool allowMemberInvite}) async {
    await api.dio.patch('/projects/$projectId/settings',
        data: {'allow_member_invite': allowMemberInvite});
  }

  /// Owner-only: update any subset of the team's name, description, photo and
  /// member-invite policy. Only non-null fields are sent.
  Future<void> updateTeam(
    int projectId, {
    String? title,
    String? description,
    String? avatarUrl,
    bool? allowMemberInvite,
  }) async {
    await api.dio.patch('/projects/$projectId/settings', data: {
      'title': ?title,
      'description': ?description,
      'avatar_url': ?avatarUrl,
      'allow_member_invite': ?allowMemberInvite,
    });
  }

  Future<void> inviteToTeam(int projectId, int userId) async {
    await api.dio.post('/projects/$projectId/invite', data: {'user_id': userId});
  }

  Future<List<Map<String, dynamic>>> myTeamInvites() async {
    final res = await api.dio.get('/projects/me/invites');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> acceptTeamInvite(int projectId) async {
    await api.dio.post('/projects/$projectId/invite/accept');
  }

  Future<void> declineTeamInvite(int projectId) async {
    await api.dio.post('/projects/$projectId/invite/decline');
  }
}
