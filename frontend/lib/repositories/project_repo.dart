import '../core/api_client.dart';
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
  }) async {
    final res = await api.dio.post('/projects', data: {
      'title': title,
      'description': description,
      'required_skills': requiredSkills,
      'interests': interests,
    });
    return Project.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> apply(int projectId, {String? message}) async {
    await api.dio.post('/projects/$projectId/apply', data: {
      if (message != null && message.isNotEmpty) 'message': message,
    });
  }
}
