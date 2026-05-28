import '../core/api_client.dart';
import '../models/user.dart';

class UserRepository {
  final ApiClient api;
  UserRepository(this.api);

  Future<User> updateProfile({String? fullName, String? bio}) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (bio != null) data['bio'] = bio;
    final res = await api.dio.patch('/users/me', data: data);
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  /// [skills] is a list of {skill_id, level}.
  Future<User> setSkills(List<Map<String, int>> skills) async {
    final res = await api.dio.put('/users/me/skills', data: skills);
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<User> setInterests(List<int> interestIds) async {
    final res = await api.dio.put('/users/me/interests', data: interestIds);
    return User.fromJson(res.data as Map<String, dynamic>);
  }
}
