import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../design_system/ds.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  static const List<_SlideData> _slides = [
    _SlideData(
      icon: Icons.groups_2_outlined,
      title: 'Bienvenue sur TeamUp',
      subtitle:
          'Le réseau qui connecte les étudiants pour monter des équipes de projet.',
    ),
    _SlideData(
      icon: Icons.auto_awesome,
      title: 'Trouve les bons coéquipiers',
      subtitle:
          'Un matching par compétences et centres d\'intérêt te propose les profils les plus pertinents.',
    ),
    _SlideData(
      icon: Icons.chat_bubble_outline,
      title: 'Collabore en temps réel',
      subtitle:
          'Discute, postule à des projets et construis ton équipe, directement dans l\'app.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandHeader(iconSize: 28, fontSize: 20),
                  TextButton(
                    onPressed: widget.onDone,
                    child: Text(
                      'Passer',
                      style: TextStyle(color: p.textMuted),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slides ────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon in soft rounded square
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: p.itemHoverBg,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            slide.icon,
                            size: 56,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide.title,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            fontSize: 15,
                            color: p.textMuted,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Page dots ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? primary : p.slate200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // ── CTA button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: AppButton(
                onPressed: _next,
                child: Text(isLast ? 'Commencer' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
