import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../design_system/ds.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  // (questionKey, answerKey) — resolved via context.tr at build time.
  static const _faqKeys = [
    ('help.q1', 'help.a1'),
    ('help.q2', 'help.a2'),
    ('help.q3', 'help.a3'),
    ('help.q4', 'help.a4'),
    ('help.q5', 'help.a5'),
    ('help.q6', 'help.a6'),
    ('help.q7', 'help.a7'),
    ('help.q8', 'help.a8'),
    ('help.q9', 'help.a9'),
    ('help.q10', 'help.a10'),
    ('help.q11', 'help.a11'),
    ('help.q12', 'help.a12'),
  ];

  // Quick action cards: (labelKey, icon, bg, fg).
  static const _actions = [
    ('help.contact', Icons.chat_bubble_outline, Color(0xFFE0E7FF), Color(0xFF4F46E5)),
    ('help.guide', Icons.description_outlined, Color(0xFFD1FAE5), Color(0xFF059669)),
    ('help.rate', Icons.star_outline, Color(0xFFFEF3C7), Color(0xFFD97706)),
    ('help.website', Icons.open_in_new, Color(0xFFFFE4E6), Color(0xFFE11D48)),
  ];

  String _query = '';
  int? _openFaq;

  // ── Quick action handlers ──────────────────────────────────────────────────

  Future<void> _openContact() async {
    final messenger = ScaffoldMessenger.of(context);
    final errMsg = context.tr('help.mailErr');
    final uri = Uri.parse(
        'mailto:teamup.team28@gmail.com?subject=Support%20TeamUp');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  Future<void> _openWebsite() async {
    final messenger = ScaffoldMessenger.of(context);
    final errMsg = context.tr('help.webErr');
    final uri = Uri.parse('https://github.com/Uncher1/TeamUp');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  Future<void> _showRatingDialog() async {
    int selected = 0;
    final messenger = ScaffoldMessenger.of(context);
    final thanksSnack = context.tr('help.rateThanksSnack');
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(context.tr('help.rate')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr('help.rateBody')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setLocal(() => selected = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < selected ? Icons.star : Icons.star_border,
                        size: 36,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('common.cancel')),
            ),
            FilledButton(
              onPressed: selected == 0
                  ? null
                  : () {
                      Navigator.pop(ctx);
                    },
              child: Text(context.tr('help.rateThanks')),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (selected > 0) {
      messenger.showSnackBar(SnackBar(content: Text(thanksSnack)));
    }
  }

  void _showGuide() {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final steps = [
          ('1.', context.tr('help.step1')),
          ('2.', context.tr('help.step2')),
          ('3.', context.tr('help.step3')),
          ('4.', context.tr('help.step4')),
          ('5.', context.tr('help.step5')),
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('help.guideTitle'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary)),
              const SizedBox(height: 4),
              Text(context.tr('help.guideSub'),
                  style: TextStyle(fontSize: 13, color: p.textMuted)),
              const SizedBox(height: 20),
              for (final (num, text) in steps) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(num,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(ctx).colorScheme.primary)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(text,
                          style:
                              TextStyle(fontSize: 14, color: p.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final q = _query.trim().toLowerCase();
    // Resolve every FAQ to the active language, keeping the original index.
    final all = [
      for (var i = 0; i < _faqKeys.length; i++)
        (i, context.tr(_faqKeys[i].$1), context.tr(_faqKeys[i].$2)),
    ];
    final faqWithIndex = q.isEmpty
        ? all
        : all
            .where((e) =>
                e.$2.toLowerCase().contains(q) || e.$3.toLowerCase().contains(q))
            .toList();

    return SettingsScaffold(
      title: context.tr('set.help'),
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: context.tr('help.search'),
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        SettingsSectionLabel(context.tr('help.quickActions')),
        Row(children: [
          Expanded(
              child: _ActionCard(
                  data: _actions[0], onTap: _openContact)),
          const SizedBox(width: 12),
          Expanded(
              child: _ActionCard(
                  data: _actions[1], onTap: _showGuide)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _ActionCard(
                  data: _actions[2], onTap: _showRatingDialog)),
          const SizedBox(width: 12),
          Expanded(
              child: _ActionCard(
                  data: _actions[3], onTap: _openWebsite)),
        ]),
        const SizedBox(height: 20),
        SettingsSectionLabel(context.tr('help.faq')),
        if (faqWithIndex.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(context.tr('help.noResult', {'q': _query}),
                style: TextStyle(fontSize: 13, color: p.textMuted)),
          ),
        for (final (origIdx, question, answer) in faqWithIndex)
          _FaqItem(
            question: question,
            answer: answer,
            isOpen: _openFaq == origIdx,
            onTap: () => setState(
                () => _openFaq = (_openFaq == origIdx) ? null : origIdx),
          ),
      ],
    );
  }
}

// ── FAQ Item ─────────────────────────────────────────────────────────────────

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool isOpen;
  final VoidCallback onTap;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.slate200),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          question,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: p.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more,
                            size: 20, color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(answer,
                        style:
                            TextStyle(fontSize: 13, color: p.textMuted)),
                  ),
                  crossFadeState: isOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final (String, IconData, Color, Color) data;
  final VoidCallback onTap;
  const _ActionCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (labelKey, icon, bg, fg) = data;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.slate200),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(height: 8),
              Text(context.tr(labelKey),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
