// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../design_system/ds.dart';
import '../../providers/call_provider.dart';

/// App-wide overlay that renders the incoming-call popup or the in-call screen
/// on top of everything, driven by [CallProvider]. Mounted once in the
/// MaterialApp builder so a call can pop up from any screen.
class CallOverlay extends StatelessWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();
    switch (call.phase) {
      case CallPhase.idle:
        return const SizedBox.shrink();
      case CallPhase.incoming:
        return _IncomingCall(call: call);
      case CallPhase.outgoing:
      case CallPhase.connecting:
      case CallPhase.active:
        return _CallScreen(call: call);
    }
  }
}

class _IncomingCall extends StatelessWidget {
  final CallProvider call;
  const _IncomingCall({required this.call});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            Column(
              children: [
                GradientAvatar(name: call.peerName, size: 110, imageUrl: call.peerAvatar),
                const SizedBox(height: 20),
                Text(call.peerName,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(context.tr('call.incoming'),
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundAction(
                    color: const Color(0xFFEF4444),
                    icon: Icons.call_end,
                    label: context.tr('call.decline'),
                    onTap: call.rejectIncoming,
                  ),
                  _RoundAction(
                    color: const Color(0xFF22C55E),
                    icon: Icons.call,
                    label: context.tr('call.accept'),
                    onTap: call.acceptIncoming,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallScreen extends StatelessWidget {
  final CallProvider call;
  const _CallScreen({required this.call});

  String _status(BuildContext context) {
    switch (call.phase) {
      case CallPhase.outgoing:
        return context.tr('call.calling');
      case CallPhase.connecting:
        return context.tr('call.connecting');
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = call.phase == CallPhase.active;
    final showRemoteVideo = active && call.remoteVideoOn;
    final sendingVideo = !call.cameraOff || call.sharingScreen;
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          // Remote video (or avatar fallback for audio / pre-connect).
          if (showRemoteVideo)
            Positioned.fill(
              child: RTCVideoView(call.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            )
          else
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientAvatar(name: call.peerName, size: 120, imageUrl: call.peerAvatar),
                    const SizedBox(height: 20),
                    Text(call.peerName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(active ? call.durationLabel : _status(context),
                        style: const TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              ),
            ),
          // Name + timer at the top while the remote video fills the screen.
          if (showRemoteVideo)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(call.peerName,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(call.durationLabel,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          // Local preview (PiP) while we're sending video (camera or screen).
          if (sendingVideo)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 110,
                  height: 150,
                  child: RTCVideoView(call.localRenderer,
                      mirror: !call.sharingScreen,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                ),
              ),
            ),
          // Controls - exact order: mute · camera · screen share · hang up.
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 22,
                  runSpacing: 16,
                  children: [
                    _CtrlButton(
                      icon: call.muted ? Icons.mic_off : Icons.mic,
                      active: call.muted,
                      onTap: call.toggleMute,
                    ),
                    _CtrlButton(
                      icon: call.cameraOff ? Icons.videocam_off : Icons.videocam,
                      active: !call.cameraOff,
                      onTap: call.toggleCamera,
                    ),
                    _CtrlButton(
                      icon: Icons.screen_share,
                      active: call.sharingScreen,
                      onTap: call.toggleScreenShare,
                    ),
                    _CtrlButton(
                      icon: Icons.call_end,
                      bg: const Color(0xFFEF4444),
                      onTap: call.hangUp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? bg;
  const _CtrlButton({required this.icon, required this.onTap, this.active = false, this.bg});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: bg ?? (active ? Colors.white : Colors.white24),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: bg != null ? Colors.white : (active ? Colors.black : Colors.white), size: 26),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundAction(
      {required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}
