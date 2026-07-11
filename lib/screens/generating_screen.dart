import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/story.dart';
import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/motion.dart';
import '../widgets/star_field.dart';
import '../widgets/story_cover.dart';

/// The "conjuring the night" sequence (generating-animation spec): a huge
/// rotating star-sky turns in scripted eased steps over a slow constant spin,
/// cross-fading italic status phrases and pulsing dots, and — the payoff — the
/// story cover flies in and scales up before the app hands off to the Player.
///
/// It is a scripted phase machine (§4) layered over two continuous motions (§2).
/// `turn2` (the reveal) is gated on **both** the minimum load window elapsing
/// **and** generation actually finishing, so the sky keeps turning until the
/// story is ready.
class GeneratingScreen extends ConsumerStatefulWidget {
  const GeneratingScreen({super.key});

  @override
  ConsumerState<GeneratingScreen> createState() => _GeneratingScreenState();
}

/// The scripted phases (§4). `idle → turn1 → load → turn2 → arrive`.
enum _Phase { idle, turn1, load, turn2, arrive }

class _GeneratingScreenState extends ConsumerState<GeneratingScreen>
    with TickerProviderStateMixin {
  static const _phrases = [
    'Turning the night sky',
    'Writing your story',
    'Gathering quiet stars',
    'Creating the narration',
    'Preparing playback',
  ];

  // --- Timeline constants (§4). Change these to retune the demo length. ------
  static const _turn1At = Duration(milliseconds: 1200); // idle → turn1
  static const _loadAfterTurn1 = Duration(milliseconds: 1600); // turn1 → load
  static const _loadWindow = Duration(milliseconds: 8200); // min dwell in load
  static const _phrasePeriod = Duration(milliseconds: 1950); // per §4 cadence
  static const _coverDelay = Duration(milliseconds: 250); // reveal delay (§5)
  static const _arriveAfterTurn2 = Duration(milliseconds: 1700);
  static const _navAfterArrive = Duration(milliseconds: 1700); // → 3400 total

  // Continuous slow spin of the inner stars+orbs layer (§2, 220s linear).
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 220),
  );

  // Scripted phase machine (§4). One pending timer holds the current
  // transition, so cancelling it on dispose/error stops the whole chain.
  _Phase _phase = _Phase.idle;
  Timer? _pending;
  Timer? _phraseTimer;
  Timer? _coverTimer;

  double _rot = 0; // disk angle in turns (0 / 0.25 / 0.5)
  double _sky = 0; // disk opacity (fades in at start, → 0 at handoff)
  int _phraseIndex = 0;
  bool _minDwellDone = false;
  bool _coverShown = false;
  Story? _readyStory; // recorded when generation completes (any phase)
  bool _navigated = false;
  bool _errored = false;

  bool _reduce = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MotionConfig.of(context);
    if (!_started) {
      _started = true;
      _reduce = reduce;
      if (!_reduce) _spin.repeat();
      // Fade the sky in on the first frame, then run the scripted timeline.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _sky = 1);
      });
      _pending = Timer(_turn1At, _toTurn1);
    } else if (reduce != _reduce) {
      // Reduce-motion flipped mid-sequence: swap presentation only — keep the
      // phase, timeline and gating intact (§F).
      setState(() => _reduce = reduce);
      if (_reduce) {
        _spin.stop();
      } else if (!_spin.isAnimating) {
        _spin.repeat();
      }
    }
  }

  // --- Scripted transitions (§4) --------------------------------------------

  void _toTurn1() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.turn1;
      _rot = 0.25; // 90°
    });
    _pending = Timer(_loadAfterTurn1, _toLoad);
  }

  void _toLoad() {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.load;
      _phraseIndex = 0;
    });
    _phraseTimer = Timer.periodic(_phrasePeriod, (_) {
      if (!mounted) return;
      setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
    });
    // The load window is a *minimum* dwell — turn2 also waits on generation.
    _pending = Timer(_loadWindow, () {
      _minDwellDone = true;
      _tryTurn2();
    });
  }

  /// Advance to the reveal once the load window has elapsed *and* the story is
  /// ready. Called from both the min-dwell timer and the generation listener;
  /// the phase guard makes it fire exactly once.
  void _tryTurn2() {
    if (!mounted || _phase != _Phase.load) return;
    if (!_minDwellDone || _readyStory == null) return;
    _pending?.cancel();
    _phraseTimer?.cancel();
    setState(() {
      _phase = _Phase.turn2;
      _rot = 0.5; // 180°
      _sky = 0; // fade the sky out under the arriving cover
    });
    _coverTimer = Timer(_coverDelay, () {
      if (mounted) setState(() => _coverShown = true);
    });
    _pending = Timer(_arriveAfterTurn2, _toArrive);
  }

  void _toArrive() {
    if (!mounted) return;
    setState(() => _phase = _Phase.arrive);
    _pending = Timer(_navAfterArrive, () {
      final story = _readyStory;
      if (story != null) _goToPlayer(story);
    });
  }

  void _onGenError() {
    if (_errored) return;
    _errored = true;
    // Freeze the scripted turns; the slow spin keeps going under the error
    // card. turn2 can't fire (it requires a story), so the sky stays put.
    _pending?.cancel();
    _phraseTimer?.cancel();
    _coverTimer?.cancel();
    if (mounted) setState(() {});
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
  void dispose() {
    _pending?.cancel();
    _phraseTimer?.cancel();
    _coverTimer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen-only (no fireImmediately): both on-ramps set `loading` then push,
    // so the transition to data lands here — and a retained result from a prior
    // run can't instantly satisfy the gate.
    ref.listen(generationProvider, (_, next) {
      if (next.hasError) {
        _onGenError();
      } else {
        next.whenData((story) {
          if (story != null) {
            _readyStory = story;
            _tryTurn2();
          }
        });
      }
    });

    final hasError = ref.watch(generationProvider).hasError;
    // The disk must exceed the window in both axes so its edge never shows —
    // on a large macOS window 940 isn't enough (§H).
    final disk = math.max(940.0, MediaQuery.of(context).size.shortestSide * 1.2);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _skyLayer(disk),
            if (hasError)
              _ErrorView(
                onRetry: () {
                  ref.read(generationProvider.notifier).reset();
                  context.go(Routes.home);
                },
              )
            else ...[
              // Cross-fading phrase (§5) — pinned near the bottom.
              Positioned(
                left: 24,
                right: 24,
                bottom: 92,
                child: _phraseArea(),
              ),
              // Loading dots (§5), visible only while loading.
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: AnimatedOpacity(
                  opacity: _phase == _Phase.load ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  child: Center(child: _LoadingDots(reduce: _reduce)),
                ),
              ),
            ],
            // The arriving cover — the payoff (§5).
            _coverReveal(),
          ],
        ),
      ),
    );
  }

  // --- Sky (§2 / §3) --------------------------------------------------------

  Widget _skyLayer(double disk) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedOpacity(
          opacity: _sky,
          duration: const Duration(milliseconds: 900),
          child: AnimatedRotation(
            // Scripted eased quarter/half turns — a *separate* transform from
            // the 220s slow spin below (§2). Stilled under reduce-motion.
            turns: _reduce ? 0.0 : _rot,
            duration: const Duration(milliseconds: 1600),
            curve: const Cubic(.42, 0, .2, 1),
            child: SizedBox(
              width: disk,
              height: disk,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(0, -0.08), // 50% 46%
                    radius: 0.75,
                    colors: [
                      Color(0xFF1A1E4C),
                      Color(0xFF12153C),
                      Color(0xFF0C0D2A),
                      Color(0xFF090A22),
                    ],
                    stops: [0.0, 0.46, 0.74, 1.0],
                  ),
                ),
                child: ClipOval(
                  child: RotationTransition(
                    turns: _spin,
                    child: Stack(
                      children: [
                        const Positioned.fill(child: StarField(count: 40, seed: 9)),
                        for (var i = 0; i < _orbs.length; i++) _orb(i),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _orbs = [
    (l: 0.30, t: 0.24, s: 46.0, c: AppTheme.ember),
    (l: 0.72, t: 0.34, s: 26.0, c: AppTheme.violetDeep),
    (l: 0.58, t: 0.68, s: 34.0, c: AppTheme.violetMid),
    (l: 0.22, t: 0.66, s: 20.0, c: AppTheme.emberDeep),
    (l: 0.80, t: 0.62, s: 16.0, c: AppTheme.star),
    (l: 0.44, t: 0.40, s: 12.0, c: AppTheme.ember),
  ];

  Widget _orb(int i) {
    final o = _orbs[i];
    final orb = Align(
      alignment: Alignment(o.l * 2 - 1, o.t * 2 - 1),
      child: Container(
        width: o.s,
        height: o.s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [o.c.withValues(alpha: 0.95), o.c.withValues(alpha: 0)],
            stops: const [0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: o.c.withValues(alpha: 0.4),
              blurRadius: o.s * 0.7,
              spreadRadius: o.s * 0.18,
            ),
          ],
        ),
      ),
    );
    if (_reduce) return orb;
    // Each orb floats on its own 6–11s cycle with a staggered start; they're
    // independent (not meant to sync), so an effect-level delay is fine.
    return orb
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .move(
          begin: Offset.zero,
          end: const Offset(4, -6),
          duration: (6000 + i * 1000).ms,
          delay: (i * 600).ms,
          curve: Curves.easeInOut,
        );
  }

  // --- Cross-fading phrase (§5) ---------------------------------------------

  Widget _phraseArea() {
    return SizedBox(
      height: 80,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 550),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) {
          final fade = FadeTransition(opacity: anim, child: child);
          if (_reduce) return fade; // opacity-only under reduce-motion
          // Slight upward slide (pixel-based, so it's consistent across the
          // varying phrase widths — AnimatedSlide's fractional offset isn't).
          return AnimatedBuilder(
            animation: anim,
            builder: (_, c) => Transform.translate(
              offset: Offset(0, (1 - anim.value) * 8),
              child: c,
            ),
            child: fade,
          );
        },
        child: _phase == _Phase.load
            ? _phraseText(_phrases[_phraseIndex], ValueKey(_phraseIndex))
            : const SizedBox.shrink(key: ValueKey('none')),
      ),
    );
  }

  Widget _phraseText(String phrase, Key key) {
    final style = GoogleFonts.fraunces(
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w500,
      fontSize: 23,
      height: 1.3,
      color: AppTheme.moon,
      shadows: const [
        Shadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 2)),
      ],
    );
    return RichText(
      key: key,
      textAlign: TextAlign.center,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: phrase),
          TextSpan(
            text: '…',
            style: style.copyWith(color: AppTheme.moon.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // --- Arriving cover — the payoff (§5) -------------------------------------

  Widget _coverReveal() {
    final story = _readyStory;
    if (story == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedOpacity(
            key: const ValueKey('cover-reveal'),
            opacity: _coverShown ? 1 : 0,
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOut,
            child: AnimatedScale(
              // Springy overshoot, unless reduce-motion (then it just fades).
              scale: _reduce ? 1.0 : (_coverShown ? 1.0 : 0.6),
              duration: const Duration(milliseconds: 1200),
              curve: const Cubic(.34, 1.3, .6, 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Same art as the Player greets you with, for a seamless
                  // handoff (float off here so it's at rest across the cut).
                  const StoryCover(size: 196, float: false),
                  const SizedBox(height: 28),
                  Text(
                    story.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.moon,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${story.settings.length.duration} · ${_moodLabel(story.settings.mood)}',
                    style: const TextStyle(
                      color: AppTheme.star,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _moodLabel(String mood) =>
      mood.isEmpty ? 'Calm' : mood[0].toUpperCase() + mood.substring(1);
}

/// Three violet dots pulsing in sequence (§5) — a 1.4s cycle offset by 0.25s
/// per dot. Driven by a single controller sampled with a phase offset (no
/// per-dot timers). Static under reduce-motion.
class _LoadingDots extends StatefulWidget {
  const _LoadingDots({required this.reduce});
  final bool reduce;

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  static const _stagger = 0.25 / 1.4; // 0.25s of a 1.4s cycle

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduce) {
      _controller.stop();
      return _row((_) => (scale: 1.0, opacity: 0.6));
    }
    if (!_controller.isAnimating) _controller.repeat();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _row((i) {
        final v = (_controller.value + i * _stagger) % 1.0;
        final t = 0.5 - 0.5 * math.cos(v * 2 * math.pi); // 0→1→0 (moonpulse)
        return (scale: 1 + 0.05 * t, opacity: 0.85 + 0.15 * t);
      }),
    );
  }

  Widget _row(({double scale, double opacity}) Function(int) sample) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final s = sample(i);
        return Transform.scale(
          scale: s.scale,
          child: Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.star.withValues(alpha: s.opacity),
            ),
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
