import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// A drifting, twinkling star field — the ambient layer behind most screens.
///
/// One [AnimationController] drives the whole field via a single [CustomPainter]
/// (rather than N animated widgets). Star positions are deterministic per
/// [seed], matching the design's pseudo-random layout. Stilled when reduce-motion
/// is on (renders a calm static frame).
class StarField extends StatefulWidget {
  const StarField({super.key, this.count = 48, this.seed = 1});

  final int count;
  final int seed;

  @override
  State<StarField> createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _stars = _buildStars();
    // 22s drift; ping-pongs (reverse) so translateY runs 0→-40→0 with no seam.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
  }

  @override
  void didUpdateWidget(StarField old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count || old.seed != widget.seed) {
      _stars = _buildStars();
    }
  }

  double _r(int n) {
    final x = math.sin(widget.seed * 999 + n * 37.13) * 10000;
    return x - x.floorToDouble();
  }

  List<_Star> _buildStars() {
    return List.generate(widget.count, (i) {
      final small = _r(i + 1) < 0.85;
      final size = small ? 1 + _r(i + 2) * 1.6 : 2.4 + _r(i + 2) * 1.8;
      // Integer cycles-per-loop so the sine phase is continuous at the 22s seam
      // and the effective twinkle period lands in the spec's 3–8s range.
      final period = 3 + _r(i + 6) * 5; // 3–8s target
      final cycles = (22 / period).round().clamp(3, 7).toDouble();
      return _Star(
        dx: _r(i + 3),
        dy: _r(i + 4),
        radius: size / 2,
        gold: _r(i + 8) < 0.2, // independent of size
        base: 0.3 + _r(i + 5) * 0.6, // per-dot base opacity 0.3–0.9
        cycles: cycles,
        phase: _r(i + 7) * math.pi * 2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MotionConfig.of(context);
    if (reduce) {
      _controller.stop();
      return RepaintBoundary(
        child: CustomPaint(
          painter: _StarPainter(_stars, 0.0, still: true),
          size: Size.infinite,
        ),
      );
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _StarPainter(_stars, _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Star {
  const _Star({
    required this.dx,
    required this.dy,
    required this.radius,
    required this.gold,
    required this.base,
    required this.cycles,
    required this.phase,
  });

  final double dx; // 0..1 across width
  final double dy; // 0..1 across an over-sized field (see painter)
  final double radius;
  final bool gold;
  final double base;
  final double cycles; // twinkles per 22s loop (integer)
  final double phase;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.stars, this.t, {this.still = false});

  final List<_Star> stars;
  final double t;
  final bool still;

  @override
  void paint(Canvas canvas, Size size) {
    // Whole field drifts translateY 0 → -40px, linear (the controller value
    // already ping-pongs). Field is over-sized ±40px so no edge gap appears.
    final drift = still ? 0.0 : -40 * t;
    final span = size.height + 80;
    final paint = Paint();
    for (final s in stars) {
      final double alpha;
      if (still) {
        alpha = s.base;
      } else {
        // twinkle 0.25↔1 on the dot's own period, scaled by its base opacity.
        final twinkle = 0.25 +
            0.75 * (0.5 + 0.5 * math.sin(t * math.pi * 2 * s.cycles + s.phase));
        alpha = (twinkle * s.base).clamp(0.0, 1.0);
      }
      paint.color = (s.gold ? AppTheme.ember : AppTheme.moon)
          .withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * span - 40 + drift),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.t != t || old.stars != stars || old.still != still;
}
