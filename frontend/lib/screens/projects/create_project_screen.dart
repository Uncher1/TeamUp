// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../profile/crop_avatar_screen.dart';
import '../../models/conversation.dart';
import '../../models/interest.dart';
import '../../models/skill.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/projects_provider.dart';
import '../../repositories/chat_repo.dart';
import '../chat/chat_thread_screen.dart';

// ---------------------------------------------------------------------------
// Category options
// ---------------------------------------------------------------------------
// (code stored in DB, labelKey, icon)
const _kCategories = [
  ('mobile', 'category.mobile', Icons.phone_iphone),
  ('web', 'category.web', Icons.language),
  ('ai', 'category.ai', Icons.psychology_outlined),
  ('game', 'category.game', Icons.sports_esports_outlined),
  ('hardware', 'category.hardware', Icons.memory),
  ('data', 'category.data', Icons.bar_chart),
  ('design', 'category.design', Icons.brush_outlined),
  ('other', 'category.other', Icons.category_outlined),
];

// ---------------------------------------------------------------------------
// Timeline options  (code, labelKey, rangeKey)
// ---------------------------------------------------------------------------
const _kTimelines = [
  ('short', 'timeline.short', 'timeline.shortR'),
  ('medium', 'timeline.medium', 'timeline.mediumR'),
  ('long', 'timeline.long', 'timeline.longR'),
];

class CreateProjectScreen extends StatefulWidget {
  /// Called right after a successful creation so the shell can switch the
  /// underlying section to "My Teams" — then the team chat is pushed on top,
  /// so backing out of the chat lands on My Teams (not this form).
  final VoidCallback? onCreated;
  const CreateProjectScreen({super.key, this.onCreated});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  /// skillId -> weight (1..5)
  final Map<int, int> _skills = {};
  final Set<int> _interests = {};

  String? _category;
  int _teamSize = 3;
  String? _timeline;
  String? _avatarDataUrl; // team photo (base64 data URL)

  bool _busy = false;

  // Scrolling + anchors so validation can jump to the first missing field.
  final _scroll = ScrollController();
  final _infoKey = GlobalKey();
  final _categoryKey = GlobalKey();
  final _timelineKey = GlobalKey();
  final _skillsKey = GlobalKey();
  final _themesKey = GlobalKey();

  Future<void> _jumpTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.1);
    }
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (x == null) return;
    final raw = await x.readAsBytes();
    if (!mounted) return;
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropAvatarScreen(imageBytes: raw)),
    );
    if (cropped == null) return;
    setState(() => _avatarDataUrl = 'data:image/png;base64,${base64Encode(cropped)}');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LookupProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final createdMsg = context.tr('proj.created');

    // Every field is required. On the first missing one, scroll to it + explain.
    void warn(GlobalKey key, String key2) {
      messenger.showSnackBar(SnackBar(content: Text(context.tr(key2))));
      _jumpTo(key);
    }
    if (title.isEmpty || description.isEmpty) {
      return warn(_infoKey, 'proj.errInfo');
    }
    if (_category == null) return warn(_categoryKey, 'proj.errCategory');
    if (_timeline == null) return warn(_timelineKey, 'proj.errTimeline');
    if (_skills.isEmpty) return warn(_skillsKey, 'proj.errSkills');
    if (_interests.isEmpty) return warn(_themesKey, 'proj.errThemes');

    final projectsProvider = context.read<ProjectsProvider>();
    final chat = context.read<ChatRepository>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final created = await projectsProvider.create(
            title: title,
            description: description,
            requiredSkills:
                _skills.entries.map((e) => {'skill_id': e.key, 'weight': e.value}).toList(),
            interests: _interests.toList(),
            category: _category,
            teamSize: _teamSize,
            timeline: _timeline,
            avatarUrl: _avatarDataUrl,
          );
      if (!mounted) return;
      _title.clear();
      _description.clear();
      setState(() {
        _skills.clear();
        _interests.clear();
        _category = null;
        _timeline = null;
        _teamSize = 3;
        _avatarDataUrl = null;
        _busy = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(createdMsg)));
      // Switch the shell to My Teams so backing out of the chat lands there.
      widget.onCreated?.call();
      // Land the creator straight in the (persistent) team chat.
      if (created != null) {
        try {
          final convId = await chat.projectConversationId(created.id);
          navigator.push(MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              conversation: Conversation(
                id: convId,
                type: 'project',
                projectId: created.id,
                projectOwnerId: created.ownerId,
                projectTitle: created.title,
              ),
            ),
          ));
        } catch (_) {
          // Stay on the form with the success message if the chat can't open.
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(ApiClient.messageFromError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    final palette = context.palette;

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ── Banner ──────────────────────────────────────────────────────────
        GradientBanner(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.add_circle_outline, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('proj.bannerTitle'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(context.tr('proj.bannerSub'),
                        style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Team photo (optional) ────────────────────────────────────────────
        Center(
          child: GestureDetector(
            onTap: _busy ? null : _pickPhoto,
            child: Column(
              children: [
                Stack(
                  children: [
                    GradientAvatar(
                      name: _title.text.trim().isEmpty ? '?' : _title.text.trim(),
                      size: 84,
                      imageUrl: _avatarDataUrl,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.surface, width: 2),
                        ),
                        child: const Icon(Icons.photo_camera, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(context.tr('proj.photo'),
                    style: TextStyle(fontSize: 12, color: palette.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Informations ────────────────────────────────────────────────────
        KeyedSubtree(key: _infoKey, child: SectionLabel(context.tr('proj.info'))),
        const SizedBox(height: 10),
        TextField(
          controller: _title,
          maxLength: 80,
          // Rebuild so the team avatar shows live initials from the title.
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: context.tr('proj.titleLabel')),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 6,
          maxLength: 600,
          decoration: InputDecoration(
            labelText: context.tr('proj.description'),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),

        // ── Category ─────────────────────────────────────────────────────────
        KeyedSubtree(key: _categoryKey, child: SectionLabel(context.tr('proj.category'))),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final (code, labelKey, icon) in _kCategories)
              _CategoryCard(
                label: context.tr(labelKey),
                icon: icon,
                selected: _category == code,
                onTap: () => setState(() => _category = code),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Taille de l'équipe ───────────────────────────────────────────────
        SectionLabel(context.tr('proj.teamSize')),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.slate200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                icon: Icons.remove,
                onPressed: _teamSize > 2
                    ? () => setState(() => _teamSize = (_teamSize - 1).clamp(2, 10))
                    : null,
                bgColor: palette.slate100,
              ),
              const SizedBox(width: 28),
              Column(
                children: [
                  Text(
                    '$_teamSize',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  Text(
                    context.tr('mt.membersP'),
                    style: TextStyle(fontSize: 12, color: palette.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 28),
              _RoundButton(
                icon: Icons.add,
                onPressed: _teamSize < 10
                    ? () => setState(() => _teamSize = (_teamSize + 1).clamp(2, 10))
                    : null,
                bgColor: palette.slate100,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Durée estimée ────────────────────────────────────────────────────
        KeyedSubtree(key: _timelineKey, child: SectionLabel(context.tr('proj.duration'))),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (final (code, labelKey, rangeKey) in _kTimelines)
              _TimelineCard(
                label: context.tr(labelKey),
                range: context.tr(rangeKey),
                selected: _timeline == code,
                onTap: () => setState(() => _timeline = code),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Compétences requises ─────────────────────────────────────────────
        KeyedSubtree(key: _skillsKey, child: SectionLabel(context.tr('proj.skillsRequired'))),
        const SizedBox(height: 4),
        Text(context.tr('proj.skillsHint'),
            style: TextStyle(fontSize: 12, color: palette.textMuted)),
        const SizedBox(height: 10),
        if (lookup.loading)
          const Center(
              child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        else
          _SkillPicker(
            skills: lookup.skills,
            selected: _skills,
            onAdd: (id) => setState(() => _skills[id] = 3),
            onRemove: (id) => setState(() => _skills.remove(id)),
            onWeight: (id, w) => setState(() => _skills[id] = w),
          ),
        const SizedBox(height: 20),

        // ── Thématiques ──────────────────────────────────────────────────────
        KeyedSubtree(key: _themesKey, child: SectionLabel(context.tr('proj.themes'))),
        const SizedBox(height: 10),
        _InterestPicker(
          interests: lookup.interests,
          selected: _interests,
          onToggle: (id) => setState(() {
            if (!_interests.add(id)) _interests.remove(id);
          }),
        ),
        const SizedBox(height: 24),

        // ── Submit ───────────────────────────────────────────────────────────
        AppButton(
          expand: true,
          onPressed: _busy ? null : _submit,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_circle_outline),
              const SizedBox(width: 8),
              Text(context.tr('proj.create')),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _CategoryCard
// ---------------------------------------------------------------------------
class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final palette = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? palette.itemHoverBg : palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : palette.slate200,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? palette.primaryHover : palette.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? palette.primaryHover : palette.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TimelineCard
// ---------------------------------------------------------------------------
class _TimelineCard extends StatelessWidget {
  final String label;
  final String range;
  final bool selected;
  final VoidCallback onTap;

  const _TimelineCard({
    required this.label,
    required this.range,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final palette = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? palette.itemHoverBg : palette.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary : palette.slate200,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? palette.primaryHover : palette.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              range,
              style: TextStyle(
                fontSize: 11,
                color: selected ? palette.primaryHover : palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RoundButton
// ---------------------------------------------------------------------------
class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color bgColor;

  const _RoundButton({
    required this.icon,
    required this.onPressed,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: onPressed != null
                ? context.palette.textPrimary
                : context.palette.textMuted,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SkillPicker  (unchanged)
// ---------------------------------------------------------------------------
class _SkillPicker extends StatelessWidget {
  final List<Skill> skills;
  final Map<int, int> selected;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int id, int weight) onWeight;
  const _SkillPicker({
    required this.skills,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    required this.onWeight,
  });

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                _WeightStepper(
                  weight: selected[s.id]!,
                  onChanged: (w) => onWeight(s.id, w),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: context.palette.textMuted,
                  onPressed: () => onRemove(s.id),
                ),
              ],
            ),
          ),
        if (available.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: context.palette.slate100, borderRadius: BorderRadius.circular(14)),
            child: CategoryChips(
              items: available
                  .map((s) => (id: s.id, name: s.name, category: s.category))
                  .toList(),
              chipBuilder: (id, name) =>
                  ActionChip(label: Text('+ $name'), onPressed: () => onAdd(id)),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _WeightStepper  (unchanged)
// ---------------------------------------------------------------------------
class _WeightStepper extends StatelessWidget {
  final int weight;
  final ValueChanged<int> onChanged;
  const _WeightStepper({required this.weight, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: context.palette.textMuted,
          onPressed: weight > 1 ? () => onChanged(weight - 1) : null,
        ),
        Text('$weight', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: Theme.of(context).colorScheme.primary,
          onPressed: weight < 5 ? () => onChanged(weight + 1) : null,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _InterestPicker  (unchanged)
// ---------------------------------------------------------------------------
class _InterestPicker extends StatelessWidget {
  final List<Interest> interests;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  const _InterestPicker({required this.interests, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return CategoryChips(
      items: interests
          .map((i) => (id: i.id, name: i.name, category: i.category))
          .toList(),
      chipBuilder: (id, name) => FilterChip(
        label: Text(name),
        selected: selected.contains(id),
        onSelected: (_) => onToggle(id),
      ),
    );
  }
}
