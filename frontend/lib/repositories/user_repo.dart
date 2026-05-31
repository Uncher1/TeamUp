// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/public_profile.dart';
import '../models/user.dart';

class UserRepository {
  final ApiClient api;
  UserRepository(this.api);

  // ── Public profiles + social graph ─────────────────────────────────────────

  /// Another user's profile (with the viewer's relationship to them).
  Future<PublicProfile> getProfile(int userId) async {
    final res = await api.dio.get('/users/$userId');
    return PublicProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Sends a friend request (auto-accepts if they already requested me).
  /// Returns the new friend_status.
  Future<String> sendFriendRequest(int userId) async {
    final res = await api.dio.post('/friends/$userId');
    return (res.data as Map)['friend_status'] as String? ?? 'outgoing';
  }

  Future<void> acceptFriend(int userId) async {
    await api.dio.post('/friends/$userId/accept');
  }

  /// Cancels a request, declines an incoming one, or unfriends.
  Future<void> removeFriend(int userId) async {
    await api.dio.delete('/friends/$userId');
  }

  Future<void> blockUser(int userId) async {
    await api.dio.post('/users/$userId/block');
  }

  Future<void> unblockUser(int userId) async {
    await api.dio.delete('/users/$userId/block');
  }

  Future<void> reportUser(int userId, String reason, String details) async {
    await api.dio.post('/users/$userId/report',
        data: {'reason': reason, 'details': details});
  }

  Future<List<Map<String, dynamic>>> friends() async {
    final res = await api.dio.get('/friends');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> friendRequests() async {
    final res = await api.dio.get('/friends/requests');
    return (res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

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
    String? avatarUrl,
    String? presenceStatus,
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
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;
    if (presenceStatus != null) data['presence_status'] = presenceStatus;
    final res = await api.dio.patch('/users/me', data: data);
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  /// Step 1 — request a password change: validates current/new and e-mails a
  /// confirmation code. The password changes only after [confirmChange].
  Future<void> requestPasswordChange(String current, String next) async {
    await api.dio.put('/users/me/password',
        data: {'current_password': current, 'new_password': next});
  }

  /// Step 1 — request an e-mail change: stores it as pending and e-mails a
  /// code to the CURRENT address. The e-mail changes only after [confirmChange].
  Future<void> requestEmailChange(String newEmail) async {
    await api.dio.post('/users/me/email/request', data: {'email': newEmail});
  }

  /// Step 2 — confirm the pending e-mail/password change with the code.
  /// Returns the refreshed profile (e-mail updated for an e-mail change).
  Future<User> confirmChange(String code) async {
    final res =
        await api.dio.post('/users/me/change/confirm', data: {'code': code});
    return User.fromJson(
        (res.data as Map<String, dynamic>)['user'] as Map<String, dynamic>);
  }

  /// Re-issues a fresh confirmation code for the pending change.
  Future<void> resendChange() async {
    await api.dio.post('/users/me/change/resend');
  }

  Future<void> deleteAccount() async {
    await api.dio.delete('/users/me');
  }

  /// GDPR data export: everything we hold about the user, as JSON.
  Future<Map<String, dynamic>> exportData() async {
    final res = await api.dio.get('/users/me/export');
    return Map<String, dynamic>.from(res.data as Map);
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
