// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

/// Base URLs for the TeamUp backend.
///
/// Defaults to the public production API (Render) so the shipped APK works for
/// anyone, anywhere, with no configuration. For local development against your
/// own backend, override the base URL at build/run time, e.g.:
///   flutter run --dart-define=API_BASE=http://10.0.2.2:3000
class Config {
  /// Public production backend (Render + Aiven MySQL).
  static const String _prodBase = 'https://teamup-api-hi2d.onrender.com';

  /// Optional compile-time override for local development.
  static const String _override = String.fromEnvironment('API_BASE');

  static String get _base => _override.isNotEmpty ? _override : _prodBase;

  static String get apiBaseUrl => '$_base/api';
  static String get socketUrl => _base;
}
