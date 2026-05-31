// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'user.dart';

/// Another user's profile as seen by the current viewer: the (possibly
/// redacted) profile plus the viewer's relationship to them.
class PublicProfile {
  final User user;
  final bool isPrivate;
  final String friendStatus; // none | outgoing | incoming | friends
  final bool blocked; // I blocked them
  final bool blockedBy; // they blocked me

  const PublicProfile({
    required this.user,
    this.isPrivate = false,
    this.friendStatus = 'none',
    this.blocked = false,
    this.blockedBy = false,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        user: User.fromJson(j),
        isPrivate: j['is_private'] == true,
        friendStatus: j['friend_status'] as String? ?? 'none',
        blocked: j['blocked'] == true,
        blockedBy: j['blocked_by'] == true,
      );

  PublicProfile copyWith({String? friendStatus, bool? blocked}) => PublicProfile(
        user: user,
        isPrivate: isPrivate,
        friendStatus: friendStatus ?? this.friendStatus,
        blocked: blocked ?? this.blocked,
        blockedBy: blockedBy,
      );
}
