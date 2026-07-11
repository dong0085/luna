import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/moon_glow.dart';
import '../widgets/motion.dart';
import '../widgets/star_field.dart';

/// Moonrise intro: the moon fades in and drifts up while the stars twinkle in
/// behind it, then the wordmark settles (letter-spacing ease). Purely timed —
/// all startup init completes before runApp — so it hands off to Home on a
/// fixed clock. Reduce-motion shows a calm static frame and leaves sooner.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _exit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The hold matches the animation (fully settled ~1.9s) plus a beat of calm.
    _exit ??= Timer(
      MotionConfig.of(context)
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 2600),
      () {
        if (mounted) context.go(Routes.home);
      },
    );
  }

  @override
  void dispose() {
    _exit?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MotionConfig.of(context);

    Widget stars = const IgnorePointer(child: StarField(seed: 1));
    // Home uses the same header (moon at 58 + 46pt wordmark), so the splash
    // reads as that header condensing into place when the route swaps.
    Widget moon = const MoonGlow(size: 58, pulse: true);
    Widget title = _wordmark(context, letterSpacing: 1);

    if (!reduce) {
      stars = stars.animate().fadeIn(delay: 350.ms, duration: 1200.ms);
      moon = moon
          .animate()
          .fadeIn(duration: 900.ms, curve: Curves.easeOut)
          .move(
            begin: const Offset(0, 30),
            end: Offset.zero,
            duration: 1100.ms,
            curve: Curves.easeOutCubic,
          );
      // Delays live on the effects (part of the animation timeline) — an
      // Animate-level delay schedules a real Timer, which trips the smoke
      // test's pending-timer check on teardown.
      title = _wordmark(context, letterSpacing: 1)
          .animate()
          .fadeIn(delay: 850.ms, duration: 800.ms, curve: Curves.easeOut)
          .custom(
            delay: 850.ms,
            duration: 1000.ms,
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => _wordmark(
              context,
              letterSpacing: lerpDouble(9, 1, value)!,
            ),
          );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned.fill(child: stars),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  moon,
                  const SizedBox(height: 20),
                  title,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same face as the Home header wordmark, so the handoff feels seamless.
  Widget _wordmark(BuildContext context, {required double letterSpacing}) {
    return Text(
      'Luna',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 46,
            fontWeight: FontWeight.w600,
            letterSpacing: letterSpacing,
          ),
    );
  }
}
