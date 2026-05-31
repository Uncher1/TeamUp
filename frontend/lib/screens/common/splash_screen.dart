import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';

/// Branded launch splash. The hollow hexagon logo is "hand-drawn" stroke by
/// stroke, then the wordmark rises in. Shown for ~2s on every cold start.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final draw = CurvedAnimation(
        parent: _c, curve: const Interval(0.0, 0.65, curve: Curves.easeInOut));
    final wordCurve = CurvedAnimation(
        parent: _c, curve: const Interval(0.58, 0.95, curve: Curves.easeOut));
    final wordSlide = Tween<Offset>(
            begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(wordCurve);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 104,
              height: 104,
              child: AnimatedBuilder(
                animation: draw,
                builder: (_, _) => CustomPaint(
                  painter: _HexDrawPainter(progress: draw.value, color: primary),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SlideTransition(
              position: wordSlide,
              child: FadeTransition(
                opacity: wordCurve,
                child: Text(
                  'TeamUp',
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a hollow hexagon whose outline is revealed from 0 (nothing) to 1
/// (complete), giving a "being drawn" effect.
class _HexDrawPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _HexDrawPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.82; // leave room for the stroke
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i; // points at left & right, flat top & bottom
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.11
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final p = progress.clamp(0.0, 1.0);
    if (p >= 1.0) {
      canvas.drawPath(path, paint); // clean closed shape at the end
      return;
    }
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * p), paint);
    }
  }

  @override
  bool shouldRepaint(_HexDrawPainter old) =>
      old.progress != progress || old.color != color;
}
