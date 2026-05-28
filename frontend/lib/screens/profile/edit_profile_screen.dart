import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
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
  final Map<int, int> _skillLevels = {}; // skillId -> level (1..5)
  final Set<int> _interestIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _bio = TextEditingController(text: user?.bio ?? '');
    for (final s in user?.skills ?? []) {
      _skillLevels[s.id] = s.level;
    }
    for (final i in user?.interests ?? []) {
      _interestIds.add(i.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LookupProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = context.read<UserRepository>();
    final auth = context.read<AuthProvider>();
    try {
      await repo.updateProfile(fullName: _name.text.trim(), bio: _bio.text.trim());
      await repo.setSkills(_skillLevels.entries
          .map((e) => {'skill_id': e.key, 'level': e.value})
          .toList());
      final updated = await repo.setInterests(_interestIds.toList());
      auth.setUser(updated);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bio,
            decoration: const InputDecoration(
                labelText: 'Bio', alignLabelWithHint: true),
            minLines: 2,
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          Text('Compétences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Sélectionne tes compétences, puis indique ton niveau (1-5).',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 10),
          if (lookup.loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in lookup.skills)
                  FilterChip(
                    label: Text(s.name),
                    selected: _skillLevels.containsKey(s.id),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _skillLevels[s.id] = 3;
                      } else {
                        _skillLevels.remove(s.id);
                      }
                    }),
                  ),
              ],
            ),
          if (_skillLevels.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final s in lookup.skills.where((s) => _skillLevels.containsKey(s.id)))
              Row(
                children: [
                  SizedBox(width: 110, child: Text(s.name)),
                  Expanded(
                    child: Slider(
                      value: _skillLevels[s.id]!.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '${_skillLevels[s.id]}',
                      onChanged: (v) =>
                          setState(() => _skillLevels[s.id] = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text('${_skillLevels[s.id]}', textAlign: TextAlign.end),
                  ),
                ],
              ),
          ],
          const SizedBox(height: 24),
          Text('Centres d\'intérêt',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in lookup.interests)
                FilterChip(
                  label: Text(i.name),
                  selected: _interestIds.contains(i.id),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _interestIds.add(i.id);
                    } else {
                      _interestIds.remove(i.id);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
