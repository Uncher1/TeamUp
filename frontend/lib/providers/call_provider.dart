// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

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
/// Signaling events (relayed by the server to `user:<id>` rooms):
/// call:invite → call:incoming, call:accept → call:accepted, call:reject →
/// call:rejected, call:cancel → call:cancelled, call:offer/answer/ice, call:end
/// → call:ended. The CALLER creates the offer once the callee accepts.
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
  bool videoCall = true;

  RTCPeerConnection? _pc;
  MediaStream? _localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _renderersReady = false;

  bool muted = false;
  bool cameraOff = false;
  bool sharingScreen = false;
  MediaStreamTrack? _cameraTrack; // kept while screen-sharing so we can restore

  bool _remoteDescSet = false;
  final List<RTCIceCandidate> _pendingCandidates = [];

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
      videoCall = data['callType'] != 'audio';
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
    required bool video,
    int? conversationId,
  }) async {
    if (isBusy || _socket == null) return;
    peerId = userId;
    peerName = name;
    peerAvatar = avatar;
    videoCall = video;
    phase = CallPhase.outgoing;
    notifyListeners();
    await _ensureRenderers();
    await _openMedia();
    await _createPc();
    _socket!.emit('call:invite', {
      'to': userId,
      'callType': video ? 'video' : 'audio',
      'conversationId': conversationId,
    });
  }

  Future<void> acceptIncoming() async {
    if (phase != CallPhase.incoming || _socket == null) return;
    phase = CallPhase.connecting;
    notifyListeners();
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
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': videoCall ? {'facingMode': 'user'} : false,
    });
    localRenderer.srcObject = _localStream;
    if (videoCall) {
      final v = _localStream!.getVideoTracks();
      if (v.isNotEmpty) _cameraTrack = v.first;
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
        phase = CallPhase.active;
        notifyListeners();
      }
    };
    pc.onConnectionState = (RTCPeerConnectionState st) {
      if (st == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
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

  void toggleCamera() {
    cameraOff = !cameraOff;
    for (final t in _localStream?.getVideoTracks() ?? const []) {
      t.enabled = !cameraOff;
    }
    notifyListeners();
  }

  Future<void> switchCamera() async {
    final v = _localStream?.getVideoTracks() ?? const [];
    if (v.isNotEmpty) await Helper.switchCamera(v.first);
  }

  /// Replace the outgoing camera track with the device screen (and back).
  Future<void> toggleScreenShare() async {
    if (_pc == null) return;
    final senders = await _pc!.getSenders();
    RTCRtpSender? videoSender;
    for (final sn in senders) {
      if (sn.track?.kind == 'video') videoSender = sn;
    }
    if (videoSender == null) return;
    if (!sharingScreen) {
      final screen = await navigator.mediaDevices.getDisplayMedia({'video': true, 'audio': false});
      final screenTrack = screen.getVideoTracks().first;
      await videoSender.replaceTrack(screenTrack);
      localRenderer.srcObject = screen;
      sharingScreen = true;
    } else {
      if (_cameraTrack != null) {
        await videoSender.replaceTrack(_cameraTrack);
        localRenderer.srcObject = _localStream;
      }
      sharingScreen = false;
    }
    notifyListeners();
  }

  // ── Teardown ───────────────────────────────────────────────────────────────

  void _cleanupCall({bool notify = true}) {
    try {
      _localStream?.getTracks().forEach((t) => t.stop());
      _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
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
    muted = false;
    cameraOff = false;
    sharingScreen = false;
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
