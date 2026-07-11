import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// The warm glowing moon used as a header ornament (Home, Generating).
class MoonGlow extends StatelessWidget {
  const MoonGlow({super.key, this.size = 58, this.pulse = false});

  final double size;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final moon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [Color(0xFFF7EFDA), AppTheme.ember, Color(0x00E8B27D)],
          stops: [0.0, 0.6, 0.72],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.ember.withValues(alpha: 0.35),
            blurRadius: size * 0.86,
            spreadRadius: size * 0.17,
          ),
        ],
      ),
    );

    if (!pulse) return moon;
    return moon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.05, duration: 2500.ms, curve: Curves.easeInOut)
        .fadeIn();
  }
}
