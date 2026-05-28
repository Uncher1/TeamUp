import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/match.dart';
import '../../providers/matching_provider.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchingProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MatchingProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Matching')),
      body: RefreshIndicator(
        onRefresh: () => context.read<MatchingProvider>().load(),
        child: _body(provider),
      ),
    );
  }

  Widget _body(MatchingProvider provider) {
    if (provider.loading && provider.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.projects.isEmpty) {
      return _ErrorState(
        message: provider.error!,
        onRetry: () => context.read<MatchingProvider>().load(),
      );
    }
    if (provider.projects.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(
          child: Text(
            'Aucun projet correspondant.\nAjoutez des compétences à votre profil.',
            textAlign: TextAlign.center,
          ),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: provider.projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _MatchCard(match: provider.projects[i]),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchedProject match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final pct = (match.score * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(match.title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                _ScoreBadge(pct),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              match.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppTheme.textPrimary.withValues(alpha: 0.75),
                  fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MiniBar('Compétences', match.skillMatch),
                const SizedBox(width: 16),
                _MiniBar('Intérêts', match.interestMatch),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int pct;
  const _ScoreBadge(this.pct);

  Color get _color {
    if (pct >= 70) return AppTheme.primary;
    if (pct >= 40) return Colors.orange;
    return AppTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
            color: _color, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;
  const _MiniBar(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            color: AppTheme.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 2),
          Text('${(value * 100).round()}%',
              style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600)),
        ],
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
    return ListView(children: [
      const SizedBox(height: 100),
      Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.textMuted),
      const SizedBox(height: 12),
      Center(child: Text(message, textAlign: TextAlign.center)),
      const SizedBox(height: 16),
      Center(
        child:
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
      ),
    ]);
  }
}
