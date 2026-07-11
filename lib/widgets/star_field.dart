import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A drifting, twinkling star field — the ambient layer behind most screens.
///
/// One [AnimationController] drives the whole field via a single [CustomPainter]
/// (rather than N animated widgets). Star positions are deterministic per
/// [seed], matching the design's pseudo-random layout.
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
    // A long, slow loop; drift + twinkle phases are derived from its value.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
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
      final small = _r(i) < 0.85;
      final size = small ? 1 + _r(i + 1) * 1.6 : 2.4 + _r(i + 2) * 1.8;
      return _Star(
        dx: _r(i + 3),
        dy: _r(i + 4),
        radius: size / 2,
        gold: _r(i) < 0.2,
        speed: 0.6 + _r(i + 6) * 1.4,
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
    required this.speed,
    required this.phase,
  });

  final double dx; // 0..1 across width
  final double dy; // 0..1 across height
  final double radius;
  final bool gold;
  final double speed;
  final double phase;
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.stars, this.t);

  final List<_Star> stars;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Slow vertical drift of the whole field (±20px, ease in/out).
    final drift = math.sin(t * math.pi * 2) * 20;
    final paint = Paint();
    for (final s in stars) {
      final twinkle =
          0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * math.pi * 2 * s.speed + s.phase));
      paint.color = (s.gold ? AppTheme.ember : AppTheme.moon)
          .withValues(alpha: twinkle.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(s.dx * size.width, s.dy * size.height + drift),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.t != t || old.stars != stars;
}
