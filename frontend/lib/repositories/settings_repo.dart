// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import '../core/api_client.dart';

/// Key/value user settings persisted server-side. Values are stored as strings
/// (the backend coerces everything to TEXT), so booleans round-trip as
/// "true"/"false".
class SettingsRepository {
  final ApiClient api;
  SettingsRepository(this.api);

  Future<Map<String, String>> getAll() async {
    final res = await api.dio.get('/users/me/settings');
    final map = (res.data as Map);
    return map.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  /// Upserts the given keys and returns the full settings map.
  Future<Map<String, String>> update(Map<String, String> patch) async {
    final res = await api.dio.put('/users/me/settings', data: patch);
    final map = (res.data as Map);
    return map.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
