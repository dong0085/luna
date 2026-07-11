import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/story.dart';
import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/star_field.dart';

/// Faked-timing loading screen: a slowly turning night sky with cross-fading
/// phrases. It runs once and advances to the Player the moment generation
/// returns (unlike the looping design prototype).
class GeneratingScreen extends ConsumerStatefulWidget {
  const GeneratingScreen({super.key});

  @override
  ConsumerState<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends ConsumerState<GeneratingScreen> {
  static const _phrases = [
    'Turning the night sky',
    'Writing your story',
    'Gathering quiet stars',
    'Dreaming up characters',
    'Creating the narration',
    'Preparing playback',
  ];

  Timer? _timer;
  int _phrase = 0;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2100), (_) {
      if (!mounted) return;
      setState(() => _phrase = (_phrase + 1) % _phrases.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goToPlayer(Story story) {
    if (_navigated) return;
    _navigated = true;
    ref.read(currentStoryProvider.notifier).set(story);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pushReplacement(Routes.player);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    ref.listen(generationProvider, (_, next) {
      next.whenData((story) {
        if (story != null) _goToPlayer(story);
      });
    });

    final hasError = ref.watch(generationProvider).hasError;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Slowly rotating sky.
            const _RotatingSky(),
            if (hasError)
              _ErrorView(
                onRetry: () {
                  ref.read(generationProvider.notifier).reset();
                  context.go(Routes.home);
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 550),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.15),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        '${_phrases[_phrase]}…',
                        key: ValueKey(_phrase),
                        textAlign: TextAlign.center,
                        style: text.headlineSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          fontSize: 24,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const _LoadingDots(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RotatingSky extends StatefulWidget {
  const _RotatingSky();

  @override
  State<_RotatingSky> createState() => _RotatingSkyState();
}

class _RotatingSkyState extends State<_RotatingSky>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 180),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 940,
        height: 940,
        child: RotationTransition(
          turns: _spin,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF1A1E4C),
                      Color(0xFF12153C),
                      Color(0xFF0C0D2A),
                      Color(0xFF090A22),
                    ],
                    stops: [0.0, 0.46, 0.74, 1.0],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              const Positioned.fill(child: StarField(count: 60, seed: 9)),
              _orb(0.30, 0.24, 46, const Color(0xFFE8B27D)),
              _orb(0.72, 0.34, 26, AppTheme.violetDeep),
              _orb(0.58, 0.68, 34, const Color(0xFF7C6BD6)),
              _orb(0.22, 0.66, 20, const Color(0xFFC98B5A)),
              _orb(0.80, 0.62, 16, AppTheme.star),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb(double l, double t, double size, Color color) {
    return Align(
      alignment: Alignment(l * 2 - 1, t * 2 - 1),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0)],
            stops: const [0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: size * 0.7,
              spreadRadius: size * 0.18,
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -6, duration: (2000 + size * 60).round().ms),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.star,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(delay: (i * 250).ms)
              .scaleXY(
                begin: 0.6,
                end: 1.2,
                duration: 700.ms,
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 60, color: AppTheme.ember),
          const SizedBox(height: 24),
          Text("The story didn't come together",
              style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Something interrupted the night. Try again in a moment.',
              style: text.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          GradientButton(label: 'Back to start', onPressed: onRetry),
        ],
      ),
    );
  }
}
