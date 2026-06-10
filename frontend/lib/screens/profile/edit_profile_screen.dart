// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/app_strings.dart';
import '../../core/validators.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../repositories/user_repo.dart';
import 'crop_avatar_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;

  // Coordonnées
  late final TextEditingController _phone;
  late final TextEditingController _location;

  // Académique (affichée seulement si l'utilisateur se déclare étudiant)
  bool _isStudent = false;
  late final TextEditingController _school;
  late final TextEditingController _department;
  late final TextEditingController _studyYear;

  // Liens
  late final TextEditingController _github;
  late final TextEditingController _linkedin;
  late final TextEditingController _twitter;
  late final TextEditingController _website;

  static const _maxSkills = 20;
  static const _maxInterests = 15;

  /// skillId -> level (1..5)
  final Map<int, int> _skills = {};
  final Set<int> _interests = {};

  void _limitSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
  bool _busy = false;

  /// null = unchanged, '' = remove, 'data:...' = new image
  String? _avatarDataUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _location = TextEditingController(text: user?.location ?? '');
    _isStudent = user?.isStudent ?? false;
    _school = TextEditingController(text: user?.school ?? '');
    _department = TextEditingController(text: user?.department ?? '');
    _studyYear = TextEditingController(text: user?.studyYear ?? '');
    _github = TextEditingController(text: user?.github ?? '');
    _linkedin = TextEditingController(text: user?.linkedin ?? '');
    _twitter = TextEditingController(text: user?.twitter ?? '');
    _website = TextEditingController(text: user?.website ?? '');
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
    _name.dispose();
    _bio.dispose();
    _phone.dispose();
    _location.dispose();
    _school.dispose();
    _department.dispose();
    _studyYear.dispose();
    _github.dispose();
    _linkedin.dispose();
    _twitter.dispose();
    _website.dispose();
    super.dispose();
  }

  String? _val(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (x == null) return;
    final raw = await x.readAsBytes();
    if (!mounted) return;
    // Let the user crop (square/circle) before saving.
    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(builder: (_) => CropAvatarScreen(imageBytes: raw)),
    );
    if (cropped == null) return;
    final b64 = base64Encode(cropped);
    setState(() => _avatarDataUrl = 'data:image/png;base64,$b64');
  }

  /// Validates the social/website link fields. Returns an error message (or
  /// null if all good). A field is only checked when it's non-empty.
  String? _validateLinks() {
    String? check(TextEditingController c, bool Function(String) ok, String site, String example) {
      final v = c.text.trim();
      if (v.isEmpty || ok(v)) return null;
      return context.tr('ep.invalidUrl', {'site': site, 'example': example});
    }
    return check(_github, (v) => Validators.isUrlForHost(v, 'github.com'),
            'GitHub', 'https://github.com/pseudo') ??
        check(_linkedin, (v) => Validators.isUrlForHost(v, 'linkedin.com'),
            'LinkedIn', 'https://linkedin.com/in/pseudo') ??
        check(_twitter,
            (v) => Validators.isUrlForHost(v, 'twitter.com') || Validators.isUrlForHost(v, 'x.com'),
            'Twitter / X', 'https://x.com/pseudo') ??
        check(_website, Validators.isHttpUrl, 'site web', 'https://exemple.com');
  }

  Future<void> _save() async {
    final linkError = _validateLinks();
    if (linkError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(linkError)));
      return;
    }
    setState(() => _busy = true);
    final repo = context.read<UserRepository>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final savedMsg = context.tr('ep.saved');
    try {
      await repo.updateProfile(
        fullName: _name.text.trim(),
        bio: _val(_bio),
        phone: _val(_phone),
        location: _val(_location),
        isStudent: _isStudent,
        school: _val(_school),
        department: _val(_department),
        studyYear: _val(_studyYear),
        github: _val(_github),
        linkedin: _val(_linkedin),
        twitter: _val(_twitter),
        website: _val(_website),
        // Only send avatarUrl when it was explicitly changed (null = untouched)
        avatarUrl: _avatarDataUrl,
      );
      await repo.setSkills(
        _skills.entries.map((e) => {'skill_id': e.key, 'level': e.value}).toList(),
      );
      await repo.setInterests(_interests.toList());
      // Re-fetch the full profile so the name/avatar refresh everywhere.
      await auth.refreshUser();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(savedMsg)));
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(ApiClient.messageFromError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    final user = context.read<AuthProvider>().user;
    // Effective avatar: new pick > current saved
    final effectiveAvatar = _avatarDataUrl ?? user?.avatarUrl;
    final hasPhoto = effectiveAvatar != null && effectiveAvatar.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(
              title: context.tr('ep.title'),
              actions: [
                TextButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.tr('common.save')),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // ── Avatar picker ─────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: GradientAvatar(
                            name: _name.text.trim().isEmpty ? (user?.fullName ?? '') : _name.text.trim(),
                            size: 96,
                            imageUrl: effectiveAvatar,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _pickAvatar,
                          child: Text(context.tr('ep.changePhoto')),
                        ),
                        if (hasPhoto)
                          TextButton(
                            onPressed: () => setState(() => _avatarDataUrl = ''),
                            style: TextButton.styleFrom(
                              foregroundColor: context.palette.textMuted,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: Text(context.tr('ep.remove')),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  SectionLabel(context.tr('prof.info')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _name,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    decoration: InputDecoration(labelText: context.tr('register.fullName')),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bio,
                    minLines: 3,
                    maxLines: 6,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    decoration: InputDecoration(labelText: context.tr('cp.bio'), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 20),

                  // ── Contact ──────────────────────────────────────────────
                  SectionLabel(context.tr('ep.contact')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s().\-]')),
                      LengthLimitingTextInputFormatter(40),
                    ],
                    decoration: InputDecoration(
                      labelText: context.tr('ep.phone'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _location,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    decoration: InputDecoration(
                      labelText: context.tr('ep.location'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Academic (only for users who mark themselves students) ─
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isStudent,
                    onChanged: (v) => setState(() => _isStudent = v),
                    title: Text(context.tr('ep.isStudent'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(context.tr('ep.isStudentHint'),
                        style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                  ),
                  if (_isStudent) ...[
                    const SizedBox(height: 6),
                    SectionLabel(context.tr('ep.academic')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _school,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      decoration: InputDecoration(
                        labelText: context.tr('cp.school'),
                        prefixIcon: const Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _department,
                      inputFormatters: [LengthLimitingTextInputFormatter(120)],
                      decoration: InputDecoration(
                        labelText: context.tr('ep.department'),
                        prefixIcon: const Icon(Icons.account_tree_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _studyYear,
                      inputFormatters: [LengthLimitingTextInputFormatter(40)],
                      decoration: InputDecoration(
                        labelText: context.tr('ep.year'),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Links ─────────────────────────────────────────────────
                  SectionLabel(context.tr('prof.links')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _github,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    decoration: const InputDecoration(
                      labelText: 'GitHub',
                      prefixIcon: Icon(Icons.code),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _linkedin,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn',
                      prefixIcon: Icon(Icons.business_center_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _twitter,
                    inputFormatters: [LengthLimitingTextInputFormatter(120)],
                    decoration: const InputDecoration(
                      labelText: 'Twitter / X',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _website,
                    keyboardType: TextInputType.url,
                    inputFormatters: [LengthLimitingTextInputFormatter(200)],
                    decoration: InputDecoration(
                      labelText: context.tr('help.website'),
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Compétences ──────────────────────────────────────────
                  SectionLabel(context.tr('cp.skills')),
                  const SizedBox(height: 4),
                  Text(context.tr('cp.skillsHint'),
                      style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                  const SizedBox(height: 10),
                  if (lookup.loading)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  else
                    _SkillLevelPicker(
                      skills: lookup.skills,
                      selected: _skills,
                      onAdd: (id) {
                        if (_skills.length >= _maxSkills) {
                          _limitSnack(context.tr('cp.maxSkills', {'n': '$_maxSkills'}));
                          return;
                        }
                        setState(() => _skills[id] = 3);
                      },
                      onRemove: (id) => setState(() => _skills.remove(id)),
                      onLevel: (id, lv) => setState(() => _skills[id] = lv),
                    ),
                  const SizedBox(height: 20),
                  SectionLabel(context.tr('proj.themes')),
                  const SizedBox(height: 10),
                  CategoryChips(
                    items: lookup.interests
                        .map((i) => (id: i.id, name: i.name, category: i.category))
                        .toList(),
                    chipBuilder: (id, name) => FilterChip(
                      label: Text(name),
                      selected: _interests.contains(id),
                      onSelected: (_) {
                        if (_interests.contains(id)) {
                          setState(() => _interests.remove(id));
                          return;
                        }
                        if (_interests.length >= _maxInterests) {
                          _limitSnack(context.tr('cp.maxInterests', {'n': '$_maxInterests'}));
                          return;
                        }
                        setState(() => _interests.add(id));
                      },
                    ),
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
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: context.palette.textMuted,
                  onPressed: selected[s.id]! > 1 ? () => onLevel(s.id, selected[s.id]! - 1) : null,
                ),
                Text('${selected[s.id]}', style: const TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: selected[s.id]! < 5 ? () => onLevel(s.id, selected[s.id]! + 1) : null,
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
            decoration: BoxDecoration(color: context.palette.slate100, borderRadius: BorderRadius.circular(14)),
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
