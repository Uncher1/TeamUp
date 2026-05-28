import '../core/api_client.dart';
import '../models/interest.dart';
import '../models/skill.dart';

class LookupRepository {
  final ApiClient api;
  LookupRepository(this.api);

  Future<List<Skill>> skills() async {
    final res = await api.dio.get('/skills');
    return (res.data as List)
        .map((e) => Skill.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Interest>> interests() async {
    final res = await api.dio.get('/interests');
    return (res.data as List)
        .map((e) => Interest.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
