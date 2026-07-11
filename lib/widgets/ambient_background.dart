import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'star_field.dart';

/// The night-sky gradient with a drifting star field behind the given [child].
/// Used as the root of nearly every screen.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({
    super.key,
    required this.child,
    this.stars = true,
    this.starCount = 48,
    this.seed = 1,
  });

  final Widget child;
  final bool stars;
  final int starCount;
  final int seed;

  @override
  Widget build(BuildContext context) {
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
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
