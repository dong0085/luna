import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';
import 'motion.dart';
import 'star_field.dart';

/// The night-sky gradient with a drifting star field behind the given [child].
/// Used as the root of nearly every screen. When [enter] is set, the foreground
/// content fades + slides up on first build (§11) — the stars stay put.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.stars = true,
    this.starCount = 48,
    this.seed = 1,
    this.enter = true,
  });

  final Widget child;
  final bool stars;
  final int starCount;
  final int seed;
  final bool enter;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (enter && !MotionConfig.of(context)) {
      // Spec §11: opacity + a small 18px upward slide.
      content = content
          .animate()
          .fadeIn(duration: 700.ms, curve: Curves.easeOut)
          .move(
            begin: const Offset(0, 18),
            end: Offset.zero,
            duration: 800.ms,
            curve: Curves.easeOut,
          );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Stack(
        children: [
          if (stars)
            Positioned.fill(
              child: IgnorePointer(
                child: StarField(count: starCount, seed: seed),
              ),
            ),
          Positioned.fill(child: content),
        ],
      ),
    );
  }
}
