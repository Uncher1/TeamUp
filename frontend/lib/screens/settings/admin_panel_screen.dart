// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/admin_repo.dart';

/// Admin/moderator panel: list + search users; admins can promote/demote.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<AdminUser> _users = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await context.read<AdminRepository>().listUsers(q: _query);
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(ApiClient.messageFromError(e))));
    }
  }

  Future<void> _setRole(AdminUser u, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    final okMsg = context.tr('admin.roleChanged');
    try {
      await context.read<AdminRepository>().setRole(u.id, role);
      if (!mounted) return;
      setState(() {
        final i = _users.indexWhere((x) => x.id == u.id);
        if (i != -1) {
          _users[i] = AdminUser(
              id: u.id, fullName: u.fullName, email: u.email, role: role, avatarUrl: u.avatarUrl);
        }
      });
      messenger.showSnackBar(SnackBar(content: Text(okMsg)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(ApiClient.messageFromError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final me = context.watch<AuthProvider>().user;
    final isAdmin = me?.role == 'admin';
    return SettingsScaffold(
      title: context.tr('admin.title'),
      children: [
        TextField(
          onChanged: (v) => _query = v,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            hintText: context.tr('admin.searchHint'),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_users.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(context.tr('admin.empty'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.textMuted)),
          )
        else
          for (final u in _users) _row(context, u, isAdmin, u.id == me?.id),
      ],
    );
  }

  Widget _row(BuildContext context, AdminUser u, bool isAdmin, bool isMe) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.slate200),
        ),
        child: Row(
          children: [
            GradientAvatar(name: u.fullName, size: 40, imageUrl: u.avatarUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(u.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    RoleBadge(role: u.role, size: 14),
                    if (isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(context.tr('admin.you'),
                            style: TextStyle(fontSize: 11, color: p.textMuted)),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(u.email,
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Only admins can change roles; self-row is not editable.
            if (isAdmin && !isMe)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: p.textMuted),
                tooltip: context.tr('admin.changeRole'),
                onSelected: (role) => _setRole(u, role),
                itemBuilder: (_) => [
                  for (final role in const ['user', 'moderator', 'admin'])
                    PopupMenuItem(
                      value: role,
                      child: Row(
                        children: [
                          if (u.role == role)
                            const Icon(Icons.check, size: 16)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(context.tr('role.$role')),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
