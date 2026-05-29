import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/interest.dart';
import '../../models/skill.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/projects_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  /// skillId -> weight (1..5)
  final Map<int, int> _skills = {};
  final Set<int> _interests = {};
  bool _busy = false;

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
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Titre et description sont requis')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<ProjectsProvider>().create(
            title: title,
            description: description,
            requiredSkills:
                _skills.entries.map((e) => {'skill_id': e.key, 'weight': e.value}).toList(),
            interests: _interests.toList(),
          );
      if (!mounted) return;
      _title.clear();
      _description.clear();
      setState(() {
        _skills.clear();
        _interests.clear();
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projet créé')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nouveau projet',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Construis quelque chose avec ton équipe',
                        style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Informations'),
        const SizedBox(height: 10),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Titre du projet'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _description,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Description',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Compétences requises'),
        const SizedBox(height: 4),
        Text('Touche pour ajouter ; règle le poids (1–5).',
            style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
        const SizedBox(height: 10),
        if (lookup.loading)
          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        else
          _SkillPicker(
            skills: lookup.skills,
            selected: _skills,
            onAdd: (id) => setState(() => _skills[id] = 3),
            onRemove: (id) => setState(() => _skills.remove(id)),
            onWeight: (id, w) => setState(() => _skills[id] = w),
          ),
        const SizedBox(height: 20),
        const SectionLabel('Thématiques'),
        const SizedBox(height: 10),
        _InterestPicker(
          interests: lookup.interests,
          selected: _interests,
          onToggle: (id) => setState(() {
            if (!_interests.add(id)) _interests.remove(id);
          }),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_circle_outline),
          label: const Text('Créer le projet'),
        ),
      ],
    );
  }
}

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
            decoration: BoxDecoration(color: context.palette.slate100, borderRadius: BorderRadius.circular(14)),
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

class _InterestPicker extends StatelessWidget {
  final List<Interest> interests;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  const _InterestPicker({required this.interests, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final i in interests)
          FilterChip(
            label: Text(i.name),
            selected: selected.contains(i.id),
            onSelected: (_) => onToggle(i.id),
          ),
      ],
    );
  }
}
