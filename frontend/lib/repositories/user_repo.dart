import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/user.dart';

class UserRepository {
  final ApiClient api;
  UserRepository(this.api);

  Future<User> updateProfile({
    String? fullName,
    String? bio,
    String? email,
    String? phone,
    String? location,
    String? school,
    String? department,
    String? studyYear,
    String? github,
    String? linkedin,
    String? twitter,
    String? website,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (bio != null) data['bio'] = bio;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (location != null) data['location'] = location;
    if (school != null) data['school'] = school;
    if (department != null) data['department'] = department;
    if (studyYear != null) data['study_year'] = studyYear;
    if (github != null) data['github'] = github;
    if (linkedin != null) data['linkedin'] = linkedin;
    if (twitter != null) data['twitter'] = twitter;
    if (website != null) data['website'] = website;
    final res = await api.dio.patch('/users/me', data: data);
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword(String current, String next) async {
    await api.dio.put('/users/me/password',
        data: {'current_password': current, 'new_password': next});
  }

  Future<void> deleteAccount() async {
    await api.dio.delete('/users/me');
  }

  /// [skills] is a list of {skill_id, level}.
  Future<User> setSkills(List<Map<String, int>> skills) async {
    final res = await api.dio.put('/users/me/skills', data: skills);
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<User> setInterests(List<int> interestIds) async {
    // NOTE: dio treats a raw List<int> as a byte stream (no JSON content-type),
    // so the server's express.json() never parses it as an array and the route
    // would wipe all interests. Send a pre-encoded JSON string with an explicit
    // JSON content-type so the body arrives as `[1,2,3]`.
    final res = await api.dio.put(
      '/users/me/interests',
      data: jsonEncode(interestIds),
      options: Options(contentType: Headers.jsonContentType),
    );
    return User.fromJson(res.data as Map<String, dynamic>);
  }
}
