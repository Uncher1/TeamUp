import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/project.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/pills.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

class ProjectsFeedScreen extends StatefulWidget {
  const ProjectsFeedScreen({super.key});

  @override
  State<ProjectsFeedScreen> createState() => _ProjectsFeedScreenState();
}

class _ProjectsFeedScreenState extends State<ProjectsFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CreateProjectScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Créer'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProjectsProvider>().load(),
        child: _body(provider),
      ),
    );
  }

  Widget _body(ProjectsProvider provider) {
    if (provider.loading && provider.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.projects.isEmpty) {
      return _ErrorState(
        message: provider.error!,
        onRetry: () => context.read<ProjectsProvider>().load(),
      );
    }
    if (provider.projects.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Aucun projet ouvert pour le moment.')),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: provider.projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ProjectCard(project: provider.projects[i]),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('par ${project.ownerName}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              const SizedBox(height: 10),
              Text(
                project.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textPrimary.withValues(alpha: 0.8)),
              ),
              if (project.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in project.requiredSkills.take(5))
                      Pill(s.name, accent: true),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
        const SizedBox(height: 12),
        Center(child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ),
      ],
    );
  }
}
