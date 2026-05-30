import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_strings.dart';
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
      image: 'assets/onb_welcome.jpg',
      icon: Icons.groups_2_outlined,
      titleKey: 'onb.s1.title',
      subtitleKey: 'onb.s1.sub',
    ),
    _SlideData(
      image: 'assets/onb_teammates.jpg',
      icon: Icons.auto_awesome,
      titleKey: 'onb.s2.title',
      subtitleKey: 'onb.s2.sub',
    ),
    _SlideData(
      image: 'assets/onb_collaborate.jpg',
      icon: Icons.chat_bubble_outline,
      titleKey: 'onb.s3.title',
      subtitleKey: 'onb.s3.sub',
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
            // ── Top bar: brand · language switch · skip ───────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BrandHeader(iconSize: 28, fontSize: 20),
                  Row(
                    children: [
                      const LanguageToggle(),
                      TextButton(
                        onPressed: widget.onDone,
                        child: Text(
                          context.tr('common.skip'),
                          style: TextStyle(color: p.textMuted),
                        ),
                      ),
                    ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Real photo (rounded). Falls back to a themed icon
                        // tile if the asset is unavailable.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            slide.image,
                            height: 280,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 280,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: p.itemHoverBg,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(slide.icon, size: 72, color: primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          context.tr(slide.titleKey),
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.tr(slide.subtitleKey),
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
                child: Text(isLast ? context.tr('onb.start') : context.tr('onb.next')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String image;
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  const _SlideData({
    required this.image,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });
}
