import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// The dreamy cover art used across the app: a violet→ember gradient card with
/// a crescent moon, rolling hills and a few stars. Optionally floats gently.
class StoryCover extends StatelessWidget {
  const StoryCover({
    super.key,
    required this.size,
    this.gradient = AppTheme.coverGradient,
    this.carveColor = AppTheme.violetDeep,
    this.float = true,
  });

  final double size;
  final Gradient gradient;

  /// Colour used to "bite" the crescent out of the moon (should read as the
  /// cover's own violet so the moon looks lit from one side).
  final Color carveColor;
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
              // crescent moon: a parchment disc with an offset disc carving it
              Positioned(
                top: s * 0.24,
                right: s * 0.20,
                child: SizedBox(
                  width: moonD,
                  height: moonD,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: moonD,
                        height: moonD,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFBF3DE),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBF3DE).withValues(alpha: 0.5),
                              blurRadius: moonD * 0.5,
                              spreadRadius: moonD * 0.1,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: moonD * 0.24,
                        top: moonD * 0.21,
                        child: Container(
                          width: moonD,
                          height: moonD,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: carveColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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

    if (!float) return framed;
    return framed
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -8, duration: 3500.ms, curve: Curves.easeInOut);
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
          color: const Color(0xFFFFF7E6),
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
