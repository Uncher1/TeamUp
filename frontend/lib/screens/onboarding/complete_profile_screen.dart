import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../repositories/user_repo.dart';

class CompleteProfileScreen extends StatefulWidget {
  final VoidCallback onDone;
  const CompleteProfileScreen({super.key, required this.onDone});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final TextEditingController _bio;
  late final TextEditingController _school;

  final Map<int, int> _skills = {};
  final Set<int> _interests = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _bio = TextEditingController(text: user?.bio ?? '');
    _school = TextEditingController(text: user?.school ?? '');
    for (final s in user?.skills ?? const []) {
      _skills[s.id] = s.level;
    }
    for (final i in user?.interests ?? const []) {
      _interests.add(i.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LookupProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _bio.dispose();
    _school.dispose();
    super.dispose();
  }

  String? _val(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    final repo = context.read<UserRepository>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.updateProfile(
        bio: _val(_bio),
        school: _val(_school),
      );
      await repo.setSkills(
        _skills.entries
            .map((e) => {'skill_id': e.key, 'level': e.value})
            .toList(),
      );
      final updated = await repo.setInterests(_interests.toList());
      auth.setUser(updated);
      if (!mounted) return;
      widget.onDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Language switch (pre-app pages let the user pick) ──────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: const LanguageToggle(),
              ),
            ),
            // ── Header banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GradientBanner(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('cp.title'),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('cp.subtitle'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onDone,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: Text(context.tr('common.skip')),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  // Bio
                  TextField(
                    controller: _bio,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: context.tr('cp.bio'),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // School
                  TextField(
                    controller: _school,
                    decoration: InputDecoration(
                      labelText: context.tr('cp.school'),
                      prefixIcon: const Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Skills ───────────────────────────────────────────
                  SectionLabel(context.tr('cp.skills')),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('cp.skillsHint'),
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
                  const SizedBox(height: 10),
                  if (lookup.loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    _SkillLevelPicker(
                      skills: lookup.skills,
                      selected: _skills,
                      onAdd: (id) => setState(() => _skills[id] = 3),
                      onRemove: (id) => setState(() => _skills.remove(id)),
                      onLevel: (id, lv) => setState(() => _skills[id] = lv),
                    ),
                  const SizedBox(height: 24),

                  // ── Centres d'intérêt ────────────────────────────────
                  SectionLabel(context.tr('cp.interests')),
                  const SizedBox(height: 10),
                  if (lookup.loading)
                    const SizedBox.shrink()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final i in lookup.interests)
                          FilterChip(
                            label: Text(i.name),
                            selected: _interests.contains(i.id),
                            onSelected: (_) => setState(() {
                              if (!_interests.add(i.id)) {
                                _interests.remove(i.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  const SizedBox(height: 32),

                  // ── CTA ──────────────────────────────────────────────
                  AppButton(
                    onPressed: _busy ? null : _finish,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(context.tr('cp.finish')),
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

// ---------------------------------------------------------------------------
// Local skill-level picker (same pattern as edit_profile_screen.dart)
// ---------------------------------------------------------------------------

class _SkillLevelPicker extends StatelessWidget {
  final List<Skill> skills;
  final Map<int, int> selected;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int id, int level) onLevel;

  const _SkillLevelPicker({
    required this.skills,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    required this.onLevel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    final chosen = skills.where((s) => selected.containsKey(s.id)).toList();
    final available = skills.where((s) => !selected.containsKey(s.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in chosen)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: p.textMuted,
                  onPressed: selected[s.id]! > 1
                      ? () => onLevel(s.id, selected[s.id]! - 1)
                      : null,
                ),
                Text(
                  '${selected[s.id]}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: primary,
                  onPressed: selected[s.id]! < 5
                      ? () => onLevel(s.id, selected[s.id]! + 1)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: p.textMuted,
                  onPressed: () => onRemove(s.id),
                ),
              ],
            ),
          ),
        if (available.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.slate100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in available)
                  ActionChip(
                    label: Text('+ ${s.name}'),
                    onPressed: () => onAdd(s.id),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
