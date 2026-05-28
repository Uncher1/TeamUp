import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../providers/lookup_provider.dart';
import '../../providers/projects_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final Map<int, int> _skillWeights = {}; // skillId -> weight (1..5)
  final Set<int> _interestIds = {};
  bool _submitting = false;

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<ProjectsProvider>().create(
            title: _title.text.trim(),
            description: _description.text.trim(),
            requiredSkills: _skillWeights.entries
                .map((e) => {'skill_id': e.key, 'weight': e.value})
                .toList(),
            interests: _interestIds.toList(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Projet créé !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookup = context.watch<LookupProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau projet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Titre'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 24),
            Text('Compétences recherchées',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Sélectionne les compétences, puis ajuste leur poids (1-5).',
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
                      selected: _skillWeights.containsKey(s.id),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _skillWeights[s.id] = 3;
                        } else {
                          _skillWeights.remove(s.id);
                        }
                      }),
                    ),
                ],
              ),
            if (_skillWeights.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final s in lookup.skills.where((s) => _skillWeights.containsKey(s.id)))
                Row(
                  children: [
                    SizedBox(width: 110, child: Text(s.name)),
                    Expanded(
                      child: Slider(
                        value: _skillWeights[s.id]!.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '${_skillWeights[s.id]}',
                        onChanged: (v) =>
                            setState(() => _skillWeights[s.id] = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text('${_skillWeights[s.id]}',
                          textAlign: TextAlign.end),
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 24),
            Text('Thématiques', style: Theme.of(context).textTheme.titleMedium),
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
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer le projet'),
            ),
          ],
        ),
      ),
    );
  }
}
