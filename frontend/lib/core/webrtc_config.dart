// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

/// ICE configuration for 1:1 WebRTC calls.
///
/// STUN (Google) is free and effectively unlimited - most calls connect
/// peer-to-peer through it and use ZERO relay bandwidth. TURN is only a
/// fallback for networks where direct P2P fails (symmetric NAT, some 4G).
/// The TURN endpoint/credentials are overridable at build time
/// (`--dart-define=TURN_URL=... TURN_USER=... TURN_PASS=...`) so you can point
/// at a self-hosted coturn later for guaranteed-unlimited relay without
/// touching the app code.
class WebRtcConfig {
  // Empty by default → STUN-only (no dead public TURN). Provide real TURN
  // credentials at build time to cover ALL networks (self-hosted coturn or a
  // TURN provider): --dart-define=TURN_URL=turn:host:3478 TURN_USER=.. TURN_PASS=..
  static const _turnUrl = String.fromEnvironment('TURN_URL', defaultValue: '');
  static const _turnUser = String.fromEnvironment('TURN_USER', defaultValue: '');
  static const _turnPass = String.fromEnvironment('TURN_PASS', defaultValue: '');

  static Map<String, dynamic> iceServers() => {
        'iceServers': [
          {
            'urls': [
              'stun:stun.l.google.com:19302',
              'stun:stun1.l.google.com:19302',
            ],
          },
          if (_turnUrl.isNotEmpty)
            {'urls': _turnUrl, 'username': _turnUser, 'credential': _turnPass},
        ],
        'sdpSemantics': 'unified-plan',
      };
}
