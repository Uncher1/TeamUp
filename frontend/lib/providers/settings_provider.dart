// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../repositories/settings_repo.dart';

/// Central store for user preferences. Drives the app theme (dark mode +
/// accent color) and the Settings screens. Persists every change to the
/// backend optimistically (UI updates first, network follows).
class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo;
  SettingsProvider(this._repo);

  Map<String, String> _raw = {};
  bool loaded = false;

  // ---- Theme-affecting derived state ----
  bool get darkMode => _raw['darkMode'] == 'true';
  ThemeMode get themeMode => darkMode ? ThemeMode.dark : ThemeMode.light;
  String get themeColor => _raw['themeColor'] ?? 'Indigo';
  Color get seedColor => AppTheme.themeColors[themeColor] ?? AppTheme.primary;
  String get language => _raw['language'] ?? 'en';

  /// Toggle value; defaults to ON unless the user explicitly turned it off.
  bool toggle(String key, {bool def = true}) =>
      _raw.containsKey(key) ? _raw[key] == 'true' : def;

  Future<void> load() async {
    try {
      _raw = await _repo.getAll();
      loaded = true;
    } catch (_) {
      // Keep whatever we had; defaults apply.
    }
    notifyListeners();
  }

  void setDarkMode(bool v) => _put('darkMode', v ? 'true' : 'false');
  void setThemeColor(String name) => _put('themeColor', name);
  void setLanguage(String code) => _put('language', code);
  void setToggle(String key, bool v) => _put(key, v ? 'true' : 'false');

  void _put(String key, String value) {
    _raw[key] = value;
    notifyListeners();
    // Fire-and-forget persist; UI already reflects the change.
    _repo.update({key: value}).catchError((_) => <String, String>{});
  }
}
