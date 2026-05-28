import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/application.dart';
import '../../models/project.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/project_repo.dart';
import '../../widgets/pills.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  String? _error;
  bool _loading = true;
  bool _applying = false;
  bool _applied = false;
  List<Application> _applications = [];
  bool _loadingApps = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = context.read<ProjectRepository>();
    final myId = context.read<AuthProvider>().user?.id;
    try {
      final p = await repo.detail(widget.projectId);
      setState(() => _project = p);
      if (p.ownerId == myId) _loadApplications();
    } catch (e) {
      setState(() => _error = ApiClient.messageFromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadApplications() async {
    setState(() => _loadingApps = true);
    try {
      final apps = await context.read<ProjectRepository>().applications(widget.projectId);
      if (mounted) setState(() => _applications = apps);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingApps = false);
    }
  }

  Future<void> _decide(Application app, String action) async {
    try {
      await context.read<ProjectRepository>().decideApplication(widget.projectId, app.id, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'accept' ? '${app.fullName} accepté !' : 'Candidature refusée.')),
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    }
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await context.read<ProjectRepository>().apply(widget.projectId);
      if (!mounted) return;
      setState(() => _applied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Candidature envoyée !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.messageFromError(e))),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projet')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    final p = _project!;
    final myId = context.read<AuthProvider>().user?.id;
    final isOwner = myId == p.ownerId;
    final isMember = p.members.any((m) => m.id == myId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(p.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(p.ownerName, style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(width: 12),
            _StatusBadge(status: p.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(p.description, style: const TextStyle(height: 1.5)),
        const SizedBox(height: 24),
        if (p.requiredSkills.isNotEmpty) ...[
          _Label('Compétences recherchées'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in p.requiredSkills)
                Pill('${s.name} · poids ${s.weight}', accent: true),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (p.interests.isNotEmpty) ...[
          _Label('Thématiques'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final i in p.interests) Pill(i.name)],
          ),
          const SizedBox(height: 24),
        ],
        _Label('Équipe (${p.members.length})'),
        const SizedBox(height: 10),
        for (final m in p.members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
              child: Text(
                m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(m.fullName),
            subtitle: Text(m.role),
          ),
        const SizedBox(height: 24),
        if (isOwner) ...[
          const _InfoLine(icon: Icons.verified_user_outlined, text: 'Tu es le porteur de ce projet.'),
          const SizedBox(height: 24),
          _Label('Candidatures'),
          const SizedBox(height: 10),
          if (_loadingApps)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_applications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Aucune candidature pour le moment.',
                  style: TextStyle(color: AppTheme.textMuted)),
            )
          else
            for (final app in _applications)
              _ApplicationTile(app: app, onDecide: _decide),
        ] else if (isMember)
          const _InfoLine(icon: Icons.check_circle_outline, text: 'Tu fais partie de cette équipe.')
        else
          ElevatedButton.icon(
            onPressed: (_applying || _applied || p.status != 'open') ? null : _apply,
            icon: _applying
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_applied ? Icons.check : Icons.send_rounded),
            label: Text(_applied ? 'Candidature envoyée' : 'Postuler'),
          ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final open = status == 'open';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: open ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        open ? 'Ouvert' : status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: open ? const Color(0xFF15803D) : AppTheme.textMuted,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final Application app;
  final Future<void> Function(Application, String) onDecide;
  const _ApplicationTile({required this.app, required this.onDecide});

  @override
  Widget build(BuildContext context) {
    final isPending = app.status == 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    app.fullName.isNotEmpty ? app.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(app.email, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: app.status == 'accepted'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      app.status == 'accepted' ? 'Accepté' : 'Refusé',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: app.status == 'accepted'
                            ? const Color(0xFF15803D)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            if (app.message != null && app.message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(app.message!,
                  style: TextStyle(color: AppTheme.textPrimary.withValues(alpha: 0.8), fontSize: 13)),
            ],
            if (isPending) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => onDecide(app, 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Refuser'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onDecide(app, 'accept'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Accepter'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
