import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// The dreamy cover art used across the app: a violet→ember gradient card with
/// a crescent moon, rolling hills and a few stars. Floats gently unless
/// reduce-motion is on.
class StoryCover extends StatelessWidget {
  const StoryCover({
    super.key,
    required this.size,
    this.gradient = AppTheme.coverGradient,
    this.float = true,
  });

  final double size;
  final Gradient gradient;
  final bool float;

  @override
  Widget build(BuildContext context) {
    final s = size;
    final scale = s / 232.0;
    final moonD = s * 0.25;

    final cover = ClipRRect(
      borderRadius: BorderRadius.circular(s * 0.112),
      child: SizedBox(
        width: s,
        height: s,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // stars
              _dot(s, 0.22, 0.18, 4 * scale, glow: true),
              _dot(s, 0.70, 0.30, 3 * scale, glow: true),
              _dot(s, 0.54, 0.14, 2 * scale),
              // hills (back then front)
              Positioned(
                bottom: -40 * scale,
                right: -0.15 * s,
                child: _hill(0.75 * s, 0.52 * s, const Color(0xBF090A22)),
              ),
              Positioned(
                bottom: -30 * scale,
                left: -0.10 * s,
                child: _hill(0.70 * s, 0.46 * s, const Color(0x8C0E1030)),
              ),
              // crescent moon (masked, true bite)
              Positioned(
                top: s * 0.24,
                right: s * 0.20,
                child: CrescentMoon(diameter: moonD),
              ),
            ],
          ),
        ),
      ),
    );

    final framed = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(s * 0.112),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violetDeep.withValues(alpha: 0.6),
            blurRadius: 60 * scale,
            offset: Offset(0, 30 * scale),
            spreadRadius: -20 * scale,
          ),
        ],
      ),
      child: cover,
    );

    if (!float || MotionConfig.of(context)) return framed;
    return RepaintBoundary(
      child: framed
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -8, duration: 3500.ms, curve: Curves.easeInOut),
    );
  }

  Widget _hill(double w, double h, Color color) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.elliptical(200, 120)),
      ),
    );
  }

  Widget _dot(double s, double left, double top, double d, {bool glow = false}) {
    return Positioned(
      left: left * s,
      top: top * s,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.moonWhite,
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFF7E6).withValues(alpha: 0.8),
                    blurRadius: d * 2,
                    spreadRadius: d * 0.4,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

/// A warm crescent — a filled disc with an offset bite carved out via an
/// even-odd path (not two stacked shapes), plus a soft parchment/ember glow.
class CrescentMoon extends StatelessWidget {
  const CrescentMoon({super.key, required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(diameter),
      painter: _CrescentPainter(),
    );
  }
}

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final full = Rect.fromLTWH(0, 0, d, d);
    final biteCenter = Offset(d * 0.68, d * 0.30);
    final biteRadius = d * 0.45;

    // Crescent = full disc minus an offset disc (even-odd).
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(full)
      ..addOval(Rect.fromCircle(center: biteCenter, radius: biteRadius));

    // Dual glow behind: a wider ember halo + a tighter parchment glow (§8).
    final emberGlow = Paint()
      ..color = AppTheme.ember.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.22);
    canvas.drawPath(path, emberGlow);
    final parchmentGlow = Paint()
      ..color = const Color(0xFFFBF3DE).withValues(alpha: 0.5)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, d * 0.10);
    canvas.drawPath(path, parchmentGlow);

    // Warm face.
    final face = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.24, -0.36), // circle at 38% 32%
        radius: 0.9,
        colors: [Color(0xFFFCF6E4), Color(0xFFF3E9D2), Color(0xFFE8B27D)],
        stops: [0.0, 0.42, 1.0],
      ).createShader(full);
    canvas.drawPath(path, face);
  }

  @override
  bool shouldRepaint(_CrescentPainter oldDelegate) => false;
}
