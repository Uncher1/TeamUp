import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lookup_provider.dart';
import '../../repositories/user_repo.dart';

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

  // Académique
  late final TextEditingController _school;
  late final TextEditingController _department;
  late final TextEditingController _studyYear;

  // Liens
  late final TextEditingController _github;
  late final TextEditingController _linkedin;
  late final TextEditingController _twitter;
  late final TextEditingController _website;

  /// skillId -> level (1..5)
  final Map<int, int> _skills = {};
  final Set<int> _interests = {};
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
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = x.mimeType ?? 'image/jpeg';
    if (!mounted) return;
    setState(() => _avatarDataUrl = 'data:$mime;base64,$b64');
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final repo = context.read<UserRepository>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await repo.updateProfile(
        fullName: _name.text.trim(),
        bio: _val(_bio),
        phone: _val(_phone),
        location: _val(_location),
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
      final updated = await repo.setInterests(_interests.toList());
      auth.setUser(updated);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
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
              title: 'Modifier le profil',
              actions: [
                TextButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Enregistrer'),
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
                          child: const Text('Changer la photo'),
                        ),
                        if (hasPhoto)
                          TextButton(
                            onPressed: () => setState(() => _avatarDataUrl = ''),
                            style: TextButton.styleFrom(
                              foregroundColor: context.palette.textMuted,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('Retirer'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SectionLabel('Informations'),
                  const SizedBox(height: 10),
                  TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet')),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bio,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 20),

                  // ── Coordonnées ──────────────────────────────────────────
                  const SectionLabel('Coordonnées'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _location,
                    decoration: const InputDecoration(
                      labelText: 'Localisation',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Académique ───────────────────────────────────────────
                  const SectionLabel('Académique'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _school,
                    decoration: const InputDecoration(
                      labelText: 'École',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _department,
                    decoration: const InputDecoration(
                      labelText: 'Filière',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _studyYear,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Liens ────────────────────────────────────────────────
                  const SectionLabel('Liens'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _github,
                    decoration: const InputDecoration(
                      labelText: 'GitHub',
                      prefixIcon: Icon(Icons.code),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _linkedin,
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn',
                      prefixIcon: Icon(Icons.business_center_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _twitter,
                    decoration: const InputDecoration(
                      labelText: 'Twitter / X',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _website,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Site web',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Compétences ──────────────────────────────────────────
                  const SectionLabel('Compétences'),
                  const SizedBox(height: 4),
                  Text('Touche pour ajouter ; règle ton niveau (1–5).',
                      style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
                  const SizedBox(height: 10),
                  if (lookup.loading)
                    const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                  else
                    _SkillLevelPicker(
                      skills: lookup.skills,
                      selected: _skills,
                      onAdd: (id) => setState(() => _skills[id] = 3),
                      onRemove: (id) => setState(() => _skills.remove(id)),
                      onLevel: (id, lv) => setState(() => _skills[id] = lv),
                    ),
                  const SizedBox(height: 20),
                  const SectionLabel('Thématiques'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final i in lookup.interests)
                        FilterChip(
                          label: Text(i.name),
                          selected: _interests.contains(i.id),
                          onSelected: (_) => setState(() {
                            if (!_interests.add(i.id)) _interests.remove(i.id);
                          }),
                        ),
                    ],
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in available)
                  ActionChip(label: Text('+ ${s.name}'), onPressed: () => onAdd(s.id)),
              ],
            ),
          ),
      ],
    );
  }
}
