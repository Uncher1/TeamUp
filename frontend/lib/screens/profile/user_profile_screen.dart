// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/public_profile.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/chat_repo.dart';
import '../../repositories/user_repo.dart';
import '../chat/chat_thread_screen.dart';

/// Read-only profile of another user, with friend / block / report actions and
/// a "send message" button (opens a DM).
class UserProfileScreen extends StatefulWidget {
  final int userId;

  /// Optional, shown immediately in the header while the full profile loads.
  final String? initialName;
  final String? initialAvatar;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialName,
    this.initialAvatar,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  PublicProfile? _profile;
  bool _loading = true;
  bool _busy = false; // an action (friend/block) is in flight
  String? _error;

  UserRepository get _users => context.read<UserRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final p = await _users.getProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.messageFromError(e);
        _loading = false;
      });
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _toggleFriend() async {
    final p = _profile;
    if (p == null || _busy) return;
    final err = context.tr('common.error');
    final unfriendMsg = context.tr('uprof.unfriendConfirm');
    setState(() => _busy = true);
    try {
      switch (p.friendStatus) {
        case 'none':
          final s = await _users.sendFriendRequest(widget.userId);
          _setFriend(s);
          break;
        case 'incoming':
          await _users.acceptFriend(widget.userId);
          _setFriend('friends');
          break;
        case 'outgoing':
          await _users.removeFriend(widget.userId);
          _setFriend('none');
          break;
        case 'friends':
          final ok = await _confirm(unfriendMsg);
          if (!ok) break;
          await _users.removeFriend(widget.userId);
          _setFriend('none');
          break;
      }
    } catch (_) {
      _snack(err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleBlock() async {
    final p = _profile;
    if (p == null || _busy) return;
    final err = context.tr('common.error');
    if (!p.blocked) {
      final ok = await _confirm(context.tr('uprof.blockConfirm'));
      if (!ok) return;
    }
    setState(() => _busy = true);
    try {
      if (p.blocked) {
        await _users.unblockUser(widget.userId);
        setState(() => _profile = p.copyWith(blocked: false));
      } else {
        await _users.blockUser(widget.userId);
        setState(() => _profile = p.copyWith(blocked: true, friendStatus: 'none'));
      }
    } catch (_) {
      _snack(err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _report() async {
    final sent = await showReportDialog(context, widget.userId);
    if (sent == true && mounted) _snack(context.tr('report.sent'));
  }

  Future<void> _message() async {
    final chat = context.read<ChatRepository>();
    final navigator = Navigator.of(context);
    final cantMsg = context.tr('uprof.cantMessage');
    final genericErr = context.tr('common.error');
    setState(() => _busy = true);
    try {
      final conv = await chat.getOrCreateDirect(widget.userId);
      navigator.push(MaterialPageRoute(
          builder: (_) => ChatThreadScreen(conversation: conv)));
    } on DioException catch (e) {
      _snack(e.response?.statusCode == 403 ? cantMsg : genericErr);
    } catch (_) {
      _snack(genericErr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setFriend(String s) =>
      setState(() => _profile = _profile?.copyWith(friendStatus: s));

  Future<bool> _confirm(String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('common.confirm'))),
        ],
      ),
    );
    return ok ?? false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  (IconData, String) _friendIcon(String status) {
    switch (status) {
      case 'outgoing':
        return (Icons.hourglass_top, context.tr('uprof.pending'));
      case 'incoming':
        return (Icons.person_add_alt_1, context.tr('uprof.accept'));
      case 'friends':
        return (Icons.how_to_reg, context.tr('uprof.friends'));
      case 'none':
      default:
        return (Icons.person_add_alt, context.tr('uprof.addFriend'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final headerName = p?.user.fullName ?? widget.initialName ?? '';
    final accent = Theme.of(context).colorScheme.primary;
    final friend = _friendIcon(p?.friendStatus ?? 'none');
    final isSelf = context.read<AuthProvider>().user?.id == widget.userId;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: headerName,
              actions: p == null || p.blockedBy || isSelf
                  ? const []
                  : [
                      IconButton(
                        tooltip: friend.$2,
                        icon: Icon(friend.$1,
                            color: p.friendStatus == 'friends' ? accent : null),
                        onPressed: _busy ? null : _toggleFriend,
                      ),
                      IconButton(
                        tooltip: p.blocked
                            ? context.tr('uprof.unblock')
                            : context.tr('uprof.block'),
                        icon: Icon(p.blocked ? Icons.block : Icons.block_outlined,
                            color: p.blocked ? const Color(0xFFDC2626) : null),
                        onPressed: _busy ? null : _toggleBlock,
                      ),
                      IconButton(
                        tooltip: context.tr('uprof.report'),
                        icon: const Icon(Icons.flag_outlined),
                        onPressed: _busy ? null : _report,
                      ),
                    ],
            ),
            Expanded(child: _body(p)),
          ],
        ),
      ),
    );
  }

  Widget _body(PublicProfile? p) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null || p == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error ?? context.tr('common.error'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.textMuted)),
        ),
      );
    }
    final user = p.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        GradientBanner(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              GradientAvatar(
                  name: user.fullName,
                  size: 64,
                  imageUrl: user.avatarUrl,
                  presenceStatus: user.presenceStatus),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(user.fullName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18),
                            overflow: TextOverflow.ellipsis),
                      ),
                      RoleBadge(role: user.role, size: 18),
                    ]),
                    if (user.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(user.email,
                          style: const TextStyle(
                              color: Color(0xFFC7D2FE), fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (context.read<AuthProvider>().user?.id == widget.userId)
          const SizedBox.shrink()
        else if (p.blockedBy)
          _Note(context.tr('uprof.blockedByThem'))
        else if (p.blocked)
          _Note(context.tr('uprof.blockedByYou'))
        else
          AppButton(
            onPressed: _busy ? null : _message,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(context.tr('uprof.message')),
              ],
            ),
          ),

        if (p.isPrivate) ...[
          const SizedBox(height: 20),
          _Note(context.tr('uprof.private')),
        ] else ...[
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionLabel(context.tr('prof.about')),
            const SizedBox(height: 8),
            Text(user.bio!, style: const TextStyle(height: 1.4)),
          ],
          if (_hasInfo(p)) ...[
            const SizedBox(height: 20),
            SectionLabel(context.tr('prof.info')),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  if (_nonEmpty(user.school))
                    _InfoRow(Icons.school_outlined, user.school!),
                  if (_nonEmpty(user.department))
                    _InfoRow(Icons.account_tree_outlined, user.department!),
                  if (_nonEmpty(user.studyYear))
                    _InfoRow(Icons.calendar_today_outlined, user.studyYear!),
                  if (_nonEmpty(user.location))
                    _InfoRow(Icons.location_on_outlined, user.location!),
                  if (_nonEmpty(user.phone))
                    _InfoRow(Icons.phone_outlined, user.phone!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SectionLabel(context.tr('cp.skills')),
          const SizedBox(height: 8),
          if (user.skills.isEmpty)
            Text(context.tr('prof.noSkills'),
                style: TextStyle(color: context.palette.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in user.skills)
                  StatusPill(
                      label: '${s.name} · ${s.level}',
                      bg: context.palette.itemHoverBg,
                      fg: context.palette.primaryHover),
              ],
            ),
          const SizedBox(height: 20),
          SectionLabel(context.tr('proj.themes')),
          const SizedBox(height: 8),
          if (user.interests.isEmpty)
            Text(context.tr('prof.noThemes'),
                style: TextStyle(color: context.palette.textMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in user.interests)
                  StatusPill(
                      label: i.name,
                      bg: context.palette.slate100,
                      fg: context.palette.textMuted),
              ],
            ),
        ],
      ],
    );
  }

  bool _nonEmpty(String? s) => s != null && s.isNotEmpty;

  bool _hasInfo(PublicProfile p) =>
      _nonEmpty(p.user.school) ||
      _nonEmpty(p.user.department) ||
      _nonEmpty(p.user.studyYear) ||
      _nonEmpty(p.user.location) ||
      _nonEmpty(p.user.phone);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: context.palette.textMuted),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: context.palette.textPrimary))),
      ]),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.slate100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.slate200),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: p.textMuted)),
    );
  }
}

/// Report dialog: pick a reason + optional details, then send. Returns true if
/// the report was sent.
Future<bool?> showReportDialog(BuildContext context, int userId) {
  const reasons = ['spam', 'harassment', 'inappropriate', 'fake', 'other'];
  String reason = reasons.first;
  final details = TextEditingController();
  bool sending = false;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(ctx.tr('report.title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.tr('report.reason'),
                style: TextStyle(fontSize: 12, color: ctx.palette.textMuted)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: reason,
              isExpanded: true,
              onChanged: (v) => setLocal(() => reason = v ?? reason),
              items: [
                for (final r in reasons)
                  DropdownMenuItem(value: r, child: Text(ctx.tr('report.$r'))),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: details,
              maxLines: 3,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: ctx.tr('report.details'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('common.cancel'))),
          FilledButton(
            onPressed: sending
                ? null
                : () async {
                    setLocal(() => sending = true);
                    try {
                      await ctx
                          .read<UserRepository>()
                          .reportUser(userId, reason, details.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } catch (_) {
                      setLocal(() => sending = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(ctx.tr('common.error'))));
                      }
                    }
                  },
            child: Text(ctx.tr('report.submit')),
          ),
        ],
      ),
    ),
  );
}
