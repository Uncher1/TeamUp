import '../core/api_client.dart';
import '../models/match.dart';

class MatchingRepository {
  final ApiClient api;
  MatchingRepository(this.api);

  Future<List<MatchedProject>> myProjects() async {
    final res = await api.dio.get('/matching/users/me/projects');
    return (res.data as List)
        .map((e) => MatchedProject.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MatchedUser>> usersForProject(int projectId) async {
    final res = await api.dio.get('/matching/projects/$projectId/users');
    return (res.data as List)
        .map((e) => MatchedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
