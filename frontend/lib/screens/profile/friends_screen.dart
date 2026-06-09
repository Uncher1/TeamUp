// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../repositories/user_repo.dart';
import 'user_profile_screen.dart';

class FriendsScreen extends StatefulWidget {
  /// 0 = Friends tab, 1 = Requests tab.
  final int initialTab;
  const FriendsScreen({super.key, this.initialTab = 0});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>>? _friends;
  List<Map<String, dynamic>>? _requests;
  bool _loading = true;

  UserRepository get _users => context.read<UserRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final f = await _users.friends();
      final r = await _users.friendRequests();
      if (!mounted) return;
      setState(() {
        _friends = f;
        _requests = r;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _accept(int id) async {
    try {
      await _users.acceptFriend(id);
    } catch (_) {}
    await _load();
  }

  Future<void> _decline(int id) async {
    try {
      await _users.removeFriend(id);
    } catch (_) {}
    await _load();
  }

  void _open(Map<String, dynamic> u) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => UserProfileScreen(
        userId: u['id'] as int,
        initialName: u['full_name'] as String?,
        initialAvatar: u['avatar_url'] as String?,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final reqCount = _requests?.length ?? 0;
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: context.tr('friends.title')),
              TabBar(
                tabs: [
                  Tab(text: context.tr('friends.tabFriends')),
                  Tab(
                      text: reqCount > 0
                          ? '${context.tr('friends.tabRequests')} ($reqCount)'
                          : context.tr('friends.tabRequests')),
                ],
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _list(_friends ?? [], context.tr('friends.none'), false),
                          _list(_requests ?? [], context.tr('friends.noRequests'), true),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<Map<String, dynamic>> items, String emptyText, bool isRequest) {
    if (items.isEmpty) {
      return Center(
        child: Text(emptyText, style: TextStyle(color: context.palette.textMuted)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final u = items[i];
        final id = u['id'] as int;
        return AppCard(
          child: Row(
            children: [
              GradientAvatar(
                name: u['full_name'] as String? ?? '?',
                size: 44,
                imageUrl: u['avatar_url'] as String?,
                presenceStatus: u['presence_status'] as String?,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _open(u),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(u['full_name'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      RoleBadge(role: u['role'] as String? ?? 'user', size: 14),
                    ],
                  ),
                ),
              ),
              if (isRequest) ...[
                IconButton(
                  icon: Icon(Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary),
                  tooltip: context.tr('uprof.accept'),
                  onPressed: () => _accept(id),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: context.tr('friends.decline'),
                  onPressed: () => _decline(id),
                ),
              ] else
                Icon(Icons.chevron_right, color: context.palette.textMuted),
            ],
          ),
        );
      },
    );
  }
}
