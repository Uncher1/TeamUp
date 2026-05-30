import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';
import '../../models/interest.dart';
import '../../models/skill.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/projects_provider.dart';

// ---------------------------------------------------------------------------
// Category options
// ---------------------------------------------------------------------------
const _kCategories = [
  ('Mobile App', Icons.phone_iphone),
  ('Web App', Icons.language),
  ('IA / ML', Icons.psychology_outlined),
  ('Jeu vidéo', Icons.sports_esports_outlined),
  ('Hardware / IoT', Icons.memory),
  ('Data', Icons.bar_chart),
  ('Design', Icons.brush_outlined),
  ('Autre', Icons.category_outlined),
];

// ---------------------------------------------------------------------------
// Timeline options  (code, label, range)
// ---------------------------------------------------------------------------
const _kTimelines = [
  ('short', 'Court', '1-2 semaines'),
  ('medium', 'Moyen', '1-2 mois'),
  ('long', 'Long', '3+ mois'),
];

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

  String? _category;
  int _teamSize = 3;
  String? _timeline;

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
            category: _category,
            teamSize: _teamSize,
            timeline: _timeline,
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
    final primary = Theme.of(context).colorScheme.primary;
    final palette = context.palette;

    return ListView(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nouveau projet',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
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

        // ── Informations ────────────────────────────────────────────────────
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

        // ── Catégorie ────────────────────────────────────────────────────────
        const SectionLabel('Catégorie'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: [
            for (final (value, icon) in _kCategories)
              _CategoryCard(
                label: value,
                icon: icon,
                selected: _category == value,
                onTap: () => setState(() => _category = value),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Taille de l'équipe ───────────────────────────────────────────────
        const SectionLabel('Taille de l\'équipe'),
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
                    'membres',
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
        const SectionLabel('Durée estimée'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (final (code, label, range) in _kTimelines)
              _TimelineCard(
                label: label,
                range: range,
                selected: _timeline == code,
                onTap: () => setState(() => _timeline = code),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Compétences requises ─────────────────────────────────────────────
        const SectionLabel('Compétences requises'),
        const SizedBox(height: 4),
        Text('Touche pour ajouter ; règle le poids (1–5).',
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
              const Text('Créer le projet'),
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
