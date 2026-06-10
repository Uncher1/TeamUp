// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

/// Lightweight input validators shared across forms.
class Validators {
  static final RegExp _email =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// True for a syntactically valid e-mail address.
  static bool isEmail(String s) => _email.hasMatch(s.trim());

  /// True when [value] (already non-empty) looks like a URL pointing at [host]
  /// (e.g. host = 'github.com'). Accepts with or without the https:// prefix.
  static bool isUrlForHost(String value, String host) {
    final v = value.trim().toLowerCase();
    final stripped = v.replaceFirst(RegExp(r'^https?://'), '').replaceFirst('www.', '');
    return stripped.startsWith('$host/') || stripped.startsWith(host);
  }

  /// True for a generic http(s) URL (used for the personal website field).
  static bool isHttpUrl(String value) {
    final v = value.trim();
    return RegExp(r'^https?://[^\s.]+\.[^\s]+$').hasMatch(v);
  }
}
