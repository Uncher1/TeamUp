// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../core/api_client.dart';
import '../core/config.dart' show Config;
import '../core/storage.dart';
import '../core/webrtc_config.dart';

enum CallPhase { idle, outgoing, incoming, connecting, active }

/// Drives 1:1 WebRTC calls over a persistent Socket.IO connection.
///
/// Calls always start as AUDIO (one phone button). Audio+video media is opened
/// up front but the camera track starts DISABLED, so the camera/screen-share
/// can be turned on mid-call instantly (no renegotiation). Each side announces
/// its outgoing video state with `call:media` so the other can show the avatar
/// vs. the live video.
///
/// Signaling events (relayed by the server to `user:<id>` rooms):
/// call:invite → call:incoming, call:accept → call:accepted, call:reject →
/// call:rejected, call:cancel → call:cancelled, call:offer/answer/ice,
/// call:media (video on/off), call:end → call:ended. The CALLER creates the
/// offer once the callee accepts.
class CallProvider extends ChangeNotifier {
  final TokenStorage _storage;
  final ApiClient _api;
  CallProvider(this._storage, this._api);

  sio.Socket? _socket;

  /// ICE servers (STUN + minted TURN) fetched from the backend; falls back to
  /// the compile-time config when the fetch fails.
  Map<String, dynamic>? _iceConfig;

  CallPhase phase = CallPhase.idle;
  bool get isBusy => phase != CallPhase.idle;

  // Peer being called / calling us.
  int? peerId;
  String peerName = '';
  String? peerAvatar;
  int? conversationId;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  MediaStream? _screenStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _renderersReady = false;

  bool muted = false;
  bool cameraOff = true; // calls start as audio → camera disabled
  bool sharingScreen = false;
  bool remoteVideoOn = false; // peer announced their camera/screen is on
  MediaStreamTrack? _cameraTrack; // our camera track (kept while screen-sharing)

  bool _remoteDescSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

  // ── Anti-spam ──────────────────────────────────────────────────────────────
  // Earliest time we're allowed to ring a given user again. `isBusy` already
  // blocks while ringing/in a call; this adds a cooldown afterwards.
  final Map<int, DateTime> _cooldownUntil = {};
  static const _cooldown = Duration(seconds: 15);

  // ── Call timer ───────────────────────────────────────────────────────────
  DateTime? _callStart;
  Timer? _ticker;
  int callSeconds = 0;
  String get durationLabel {
    final m = (callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (callSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Connection lifecycle ───────────────────────────────────────────────────

  Future<void> connect() async {
    if (_socket != null) return;
    final token = await _storage.read();
    if (token == null) return;
    await _ensureRenderers();
    _socket = sio.io(
      Config.socketUrl,
      sio.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    _bind();
    _socket!.connect();
    _fetchIce();
  }

  /// Pull STUN+TURN servers from the backend (Cloudflare-minted TURN). Cached
  /// for the session; safe to fail (we fall back to compile-time STUN/TURN).
  Future<void> _fetchIce() async {
    try {
      final res = await _api.dio.get('/calls/turn');
      final servers = (res.data as Map)['iceServers'];
      if (servers is List && servers.isNotEmpty) {
        _iceConfig = {'iceServers': servers, 'sdpSemantics': 'unified-plan'};
      }
    } catch (_) {/* keep fallback */}
  }

  void disconnect() {
    _cleanupCall(notify: false);
    _socket?.dispose();
    _socket = null;
  }

  Future<void> _ensureRenderers() async {
    if (_renderersReady) return;
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersReady = true;
  }

  void _bind() {
    final s = _socket!;
    s.on('call:incoming', (d) {
      final data = Map<String, dynamic>.from(d as Map);
      // Already in a call → auto-decline so the caller isn't left ringing.
      if (isBusy) {
        s.emit('call:reject', {'to': data['from']});
        return;
      }
      peerId = (data['from'] as num?)?.toInt();
      peerName = data['fromName'] as String? ?? '';
      peerAvatar = data['fromAvatar'] as String?;
      conversationId = (data['conversationId'] as num?)?.toInt();
      phase = CallPhase.incoming;
      notifyListeners();
    });

    s.on('call:accepted', (_) async {
      if (phase != CallPhase.outgoing) return;
      phase = CallPhase.connecting;
      notifyListeners();
      // Caller creates the offer now that the callee picked up.
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);
      s.emit('call:offer', {'to': peerId, 'sdp': offer.sdp, 'sdpType': offer.type});
    });

    s.on('call:rejected', (_) => _cleanupCall());
    s.on('call:cancelled', (_) => _cleanupCall());
    s.on('call:ended', (_) => _cleanupCall());

    s.on('call:offer', (d) async {
      final data = Map<String, dynamic>.from(d as Map);
      if (_pc == null) return;
      await _pc!.setRemoteDescription(
          RTCSessionDescription(data['sdp'] as String, data['sdpType'] as String? ?? 'offer'));
      _remoteDescSet = true;
      await _flushCandidates();
      final answer = await _pc!.createAnswer();
      await _pc!.setLocalDescription(answer);
      s.emit('call:answer', {'to': peerId, 'sdp': answer.sdp, 'sdpType': answer.type});
    });

    s.on('call:answer', (d) async {
      final data = Map<String, dynamic>.from(d as Map);
      if (_pc == null) return;
      await _pc!.setRemoteDescription(
          RTCSessionDescription(data['sdp'] as String, data['sdpType'] as String? ?? 'answer'));
      _remoteDescSet = true;
      await _flushCandidates();
    });

    s.on('call:ice', (d) async {
      final data = Map<String, dynamic>.from(d as Map);
      final c = data['candidate'];
      if (c == null) return;
      final cand = RTCIceCandidate(
          c['candidate'] as String?, c['sdpMid'] as String?, (c['sdpMLineIndex'] as num?)?.toInt());
      if (_remoteDescSet && _pc != null) {
        await _pc!.addCandidate(cand);
      } else {
        _pendingCandidates.add(cand);
      }
    });

    // Peer toggled their camera / screen share.
    s.on('call:media', (d) {
      final data = Map<String, dynamic>.from(d as Map);
      remoteVideoOn = data['video'] == true;
      notifyListeners();
    });
  }

  Future<void> _flushCandidates() async {
    if (_pc == null) return;
    for (final c in _pendingCandidates) {
      await _pc!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  // ── Outgoing / incoming ────────────────────────────────────────────────────

  Future<void> startCall({
    required int userId,
    required String name,
    String? avatar,
    int? conversationId,
  }) async {
    if (isBusy || _socket == null) return;
    // Anti-spam: respect the per-user cooldown after a recent call.
    final until = _cooldownUntil[userId];
    if (until != null && until.isAfter(DateTime.now())) return;
    peerId = userId;
    peerName = name;
    peerAvatar = avatar;
    this.conversationId = conversationId;
    phase = CallPhase.outgoing;
    notifyListeners();
    await _ensureRenderers();
    await _openMedia();
    await _createPc();
    _socket!.emit('call:invite', {
      'to': userId,
      'callType': 'audio',
      'conversationId': conversationId,
    });
  }

  Future<void> acceptIncoming() async {
    if (phase != CallPhase.incoming || _socket == null) return;
    phase = CallPhase.connecting;
    notifyListeners();
    await _ensureRenderers();
    await _openMedia();
    await _createPc();
    _socket!.emit('call:accept', {'to': peerId});
    // The caller will now send call:offer.
  }

  void rejectIncoming() {
    if (phase != CallPhase.incoming) return;
    _socket?.emit('call:reject', {'to': peerId});
    _cleanupCall();
  }

  /// Hang up an active/connecting call or cancel an outgoing ring.
  void hangUp() {
    if (_socket != null && peerId != null) {
      _socket!.emit(phase == CallPhase.outgoing ? 'call:cancel' : 'call:end', {'to': peerId});
    }
    _cleanupCall();
  }

  // ── Media + peer connection ────────────────────────────────────────────────

  Future<void> _openMedia() async {
    // Open audio + camera up front; camera starts DISABLED (audio call) so it
    // can be toggled on later without renegotiating. If the camera is missing
    // or its permission is denied, fall back to AUDIO-ONLY: a call must never
    // fail (and never block `call:accept`) just because there's no camera.
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {'facingMode': 'user'},
      });
    } catch (_) {
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
    }
    localRenderer.srcObject = _localStream;
    final v = _localStream!.getVideoTracks();
    if (v.isNotEmpty) {
      _cameraTrack = v.first;
      _cameraTrack!.enabled = false;
    }
    notifyListeners();
  }

  Future<void> _createPc() async {
    final pc = await createPeerConnection(_iceConfig ?? WebRtcConfig.iceServers());
    _pc = pc;
    for (final track in _localStream!.getTracks()) {
      await pc.addTrack(track, _localStream!);
    }
    pc.onIceCandidate = (RTCIceCandidate c) {
      if (c.candidate == null) return;
      _socket?.emit('call:ice', {
        'to': peerId,
        'candidate': {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        },
      });
    };
    pc.onTrack = (RTCTrackEvent e) {
      if (e.streams.isNotEmpty) {
        remoteRenderer.srcObject = e.streams.first;
        notifyListeners();
      }
    };
    pc.onConnectionState = (RTCPeerConnectionState st) {
      if (st == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        if (phase != CallPhase.active) {
          phase = CallPhase.active;
          _startTimer();
          notifyListeners();
        }
      } else if (st == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          st == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          st == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _cleanupCall();
      }
    };
  }

  // ── In-call controls ───────────────────────────────────────────────────────

  void toggleMute() {
    muted = !muted;
    for (final t in _localStream?.getAudioTracks() ?? const []) {
      t.enabled = !muted;
    }
    notifyListeners();
  }

  /// Turn our camera on/off (instant - the track is already in the connection).
  void toggleCamera() {
    // Only act once connected, and only if a camera is actually available.
    if (phase != CallPhase.active || sharingScreen || _cameraTrack == null) return;
    cameraOff = !cameraOff;
    _cameraTrack?.enabled = !cameraOff;
    if (!cameraOff) localRenderer.srcObject = _localStream;
    _socket?.emit('call:media', {'to': peerId, 'video': !cameraOff});
    notifyListeners();
  }

  /// Replace the outgoing camera track with the device screen (and back).
  ///
  /// NOTE: on Android 14+ screen capture needs a media-projection foreground
  /// service (not shipped by flutter_webrtc) - that requires native code and is
  /// tracked as a separate task. We fail gracefully here so a capture error
  /// never crashes the call.
  Future<void> toggleScreenShare() async {
    if (phase != CallPhase.active || _pc == null) return;
    final senders = await _pc!.getSenders();
    RTCRtpSender? videoSender;
    for (final sn in senders) {
      if (sn.track?.kind == 'video') videoSender = sn;
    }
    if (videoSender == null) return;
    if (!sharingScreen) {
      try {
        final screen = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': false});
        final screenTrack = screen.getVideoTracks().first;
        await videoSender.replaceTrack(screenTrack);
        localRenderer.srcObject = screen;
        _screenStream = screen;
        sharingScreen = true;
        cameraOff = true; // camera unused while sharing
        _socket?.emit('call:media', {'to': peerId, 'video': true});
      } catch (_) {
        sharingScreen = false; // capture refused / unsupported → no-op
      }
    } else {
      await videoSender.replaceTrack(_cameraTrack);
      _screenStream?.getTracks().forEach((t) => t.stop());
      _screenStream?.dispose();
      _screenStream = null;
      localRenderer.srcObject = _localStream;
      sharingScreen = false;
      _cameraTrack?.enabled = !cameraOff; // camera stays off after sharing
      _socket?.emit('call:media', {'to': peerId, 'video': !cameraOff});
    }
    notifyListeners();
  }

  // ── Timer ────────────────────────────────────────────────────────────────

  void _startTimer() {
    _callStart = DateTime.now();
    callSeconds = 0;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      callSeconds = DateTime.now().difference(_callStart!).inSeconds;
      notifyListeners();
    });
  }

  // ── Teardown ───────────────────────────────────────────────────────────────

  void _cleanupCall({bool notify = true}) {
    // Anti-spam: start the cooldown for the person we just called/were calling.
    if (peerId != null) _cooldownUntil[peerId!] = DateTime.now().add(_cooldown);
    _ticker?.cancel();
    _ticker = null;
    _callStart = null;
    callSeconds = 0;
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      _screenStream?.getTracks().forEach((t) => t.stop());
      _screenStream?.dispose();
    } catch (_) {}
    _screenStream = null;
    _cameraTrack = null;
    _pc?.close();
    _pc = null;
    if (_renderersReady) {
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
    }
    _remoteDescSet = false;
    _pendingCandidates.clear();
    phase = CallPhase.idle;
    peerId = null;
    peerName = '';
    peerAvatar = null;
    conversationId = null;
    muted = false;
    cameraOff = true;
    sharingScreen = false;
    remoteVideoOn = false;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _cleanupCall(notify: false);
    _socket?.dispose();
    if (_renderersReady) {
      localRenderer.dispose();
      remoteRenderer.dispose();
    }
    super.dispose();
  }
}
