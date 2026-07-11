import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/story_length.dart';
import '../models/story_settings.dart';
import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';

/// Quick start on-ramp, per the bubbles spec: drifting "spark" bubbles of story
/// seeds arrive, bob, live a few seconds and fade out (max 3 at once). Tap one
/// to select it (others dim + blur) and a confirm bubble pops up beside it;
/// "Start" generates and heads to Generating.
class QuickStartScreen extends ConsumerStatefulWidget {
  const QuickStartScreen({super.key, this.seed});

  /// Seed for deterministic spawn/lifecycle in tests.
  final int? seed;

  @override
  ConsumerState<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends ConsumerState<QuickStartScreen> {
  // 8 fixed slots (x%, y%) inside the field box — all x in 32–68% so bubbles
  // never touch the frame edge.
  static const _slots = [
    Offset(0.33, 0.14), Offset(0.67, 0.18), Offset(0.50, 0.30),
    Offset(0.32, 0.44), Offset(0.68, 0.46), Offset(0.34, 0.66),
    Offset(0.66, 0.64), Offset(0.50, 0.78),
  ];

  static const _headings = [
    'A lighthouse that hums',
    'The last train to nowhere',
    'Snow over a sleeping town',
    'A whale who collects lullabies',
    'The library beneath the sea',
    'Moths and a porch light',
    'A garden that grows at night',
    'Keeper of the small tides',
    'Where the fog goes to rest',
    'A map drawn in starlight',
    'The quiet between two stars',
    'A ferry with no schedule',
  ];

  late final math.Random _rng = math.Random(widget.seed);
  final List<_Bubble> _bubbles = [];
  int? _selectedId;
  int _bid = 1;
  int _bhi = 0; // rolling heading index
  int _blast = -1; // last-used slot (never reused back-to-back)

  final Set<Timer> _timers = {};
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    // Initial burst, then the self-rescheduling cadence.
    _after(200, _spawnBubble);
    _after(1700, _spawnBubble);
    _after(3400, _spawnBubble);
    _scheduleSpawn();
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  // --- Timers ---------------------------------------------------------------

  void _after(int ms, VoidCallback fn) {
    late Timer t;
    t = Timer(Duration(milliseconds: ms), () {
      _timers.remove(t);
      if (!mounted) return;
      fn();
    });
    _timers.add(t);
  }

  void _scheduleSpawn() {
    // Fill toward 3 quickly, then relax (only replacing bubbles that die).
    final ms = _bubbles.length < 3
        ? 700 + _rng.nextInt(1200) // 700–1900
        : 1600 + _rng.nextInt(2200); // 1600–3800
    _spawnTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      _spawnBubble();
      _scheduleSpawn();
    });
  }

  // --- Spawn / lifecycle ----------------------------------------------------

  void _spawnBubble() {
    if (_selectedId != null) return; // guard 1: frozen while selecting
    if (_bubbles.length >= 3) return; // guard 2: never more than 3

    // guard 3: free slots = not last-used and not overlapping an active slot.
    final active = _bubbles.map((b) => _slots[b.slot]).toList();
    final free = <int>[];
    for (var i = 0; i < _slots.length; i++) {
      if (i == _blast) continue;
      final s = _slots[i];
      final overlaps = active.any(
        (a) => (a.dx - s.dx).abs() < 0.22 && (a.dy - s.dy).abs() < 0.13,
      );
      if (!overlaps) free.add(i);
    }
    if (free.isEmpty) return;
    final slot = free[_rng.nextInt(free.length)];
    _blast = slot;

    // guard 5: next heading not already on screen.
    final live = _bubbles.map((b) => b.text).toSet();
    String? text;
    for (var k = 0; k < _headings.length; k++) {
      final cand = _headings[(_bhi + k) % _headings.length];
      if (!live.contains(cand)) {
        text = cand;
        _bhi = (_bhi + k + 1) % _headings.length;
        break;
      }
    }
    if (text == null) return;

    final id = _bid++;
    final bubble = _Bubble(
      id: id,
      text: text,
      slot: slot,
      dur: 6.0 + _rng.nextDouble() * 1.5, // 6.0–7.5s
      delay: _rng.nextDouble() * 2.0, // 0–2s
    );
    setState(() => _bubbles.add(bubble));

    _after(40, () => _patch(id, true)); // pop in
    final life = 6500 + _rng.nextInt(2500); // 6.5–9s on screen
    _after(life, () {
      if (_selectedId != id) _patch(id, false); // fade/scale out
    });
    _after(life + 600, () {
      if (_selectedId != id) _remove(id); // remove after exit plays
    });
  }

  void _patch(int id, bool vis) {
    final i = _bubbles.indexWhere((b) => b.id == id);
    if (i < 0) return;
    setState(() => _bubbles[i].vis = vis);
  }

  void _remove(int id) => setState(() => _bubbles.removeWhere((b) => b.id == id));

  // --- Selection ------------------------------------------------------------

  void _select(int id) {
    if (_selectedId != null) return; // can't select two
    setState(() => _selectedId = id);
  }

  void _cancel() {
    final id = _selectedId;
    setState(() => _selectedId = null);
    if (id != null) {
      _patch(id, false);
      _after(600, () => _remove(id));
    }
  }

  void _begin(String seed) {
    final settings = StorySettings(topic: seed, length: StoryLength.short);
    ref.read(generationProvider.notifier).generate(settings);
    context.push(Routes.generating);
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    _Bubble? selected;
    for (final b in _bubbles) {
      if (b.id == _selectedId) selected = b;
    }

    return AmbientBackground(
      seed: 14,
      starCount: 44,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: AppTheme.moon,
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'Quick start',
                    style: text.headlineSmall?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tap a spark that calls to you',
                style: text.bodyMedium?.copyWith(
                  color: AppTheme.moon.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Unselected bubbles first, selected raised above them.
                        for (final b in _bubbles)
                          if (b.id != _selectedId) _bubbleAt(c, b),
                        if (selected != null) _bubbleAt(c, selected),
                        if (selected != null) _confirmAt(c, selected),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubbleAt(BoxConstraints c, _Bubble b) {
    final slot = _slots[b.slot];
    return Positioned(
      key: ValueKey('pos-${b.id}'),
      left: slot.dx * c.maxWidth,
      top: slot.dy * c.maxHeight,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: _BubbleView(
          key: ValueKey(b.id),
          bubble: b,
          selected: _selectedId == b.id,
          dimmed: _selectedId != null && _selectedId != b.id,
          onTap: () => _select(b.id),
        ),
      ),
    );
  }

  Widget _confirmAt(BoxConstraints c, _Bubble b) {
    final slot = _slots[b.slot];
    final rightSide = slot.dx < 0.5;
    final cx = (slot.dx + (rightSide ? 0.16 : -0.16)).clamp(0.32, 0.68);
    final cy = (slot.dy + 0.16).clamp(0.0, 0.82);
    return Positioned(
      left: cx * c.maxWidth,
      top: cy * c.maxHeight,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: _ConfirmCard(
          origin: rightSide ? Alignment.topLeft : Alignment.topRight,
          onCancel: _cancel,
          onStart: () => _begin(b.text),
        ),
      ),
    );
  }
}

class _Bubble {
  _Bubble({
    required this.id,
    required this.text,
    required this.slot,
    required this.dur,
    required this.delay,
  });

  final int id;
  final String text;
  final int slot;
  final double dur; // bob duration (s)
  final double delay; // bob delay (s)
  bool vis = false;
}

/// A single bubble. Bob (outer) is a per-bubble controller with the delay folded
/// in as a phase offset — no wall-clock timers (test-safe). Pop / select / dim
/// (inner) are implicit animations driven by [bubble.vis] / [selected] / [dimmed].
class _BubbleView extends StatefulWidget {
  const _BubbleView({
    super.key,
    required this.bubble,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final _Bubble bubble;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  State<_BubbleView> createState() => _BubbleViewState();
}

class _BubbleViewState extends State<_BubbleView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.bubble.dur * 1000).round()),
  );

  @override
  void initState() {
    super.initState();
    // Fold the 0–2s delay into a starting phase so no Timer is needed.
    _bob.value = (widget.bubble.delay / widget.bubble.dur) % 1.0;
    _bob.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bubble;
    final scale = !b.vis
        ? 0.2
        : widget.selected
            ? 1.06
            : widget.dimmed
                ? 0.92
                : 1.0;
    final opacity = !b.vis
        ? 0.0
        : widget.dimmed
            ? 0.22
            : 1.0;

    Widget card = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 600),
      curve: const Cubic(.34, 1.4, .6, 1), // springy overshoot
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 500),
        child: _card(b),
      ),
    );

    // Blur the dimmed bubbles, tweened over 0.4s for a soft feel.
    card = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: widget.dimmed ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      builder: (context, sigma, child) => ImageFiltered(
        enabled: sigma > 0.02,
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
      child: card,
    );

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -9 * Curves.easeInOut.transform(_bob.value)),
          child: child,
        ),
        child: card,
      ),
    );
  }

  Widget _card(_Bubble b) {
    final selected = widget.selected;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment(-0.2, -1),
            end: Alignment(0.2, 1),
            colors: [Color(0xF52D2C60), Color(0xF01B1E48)],
          ),
          border: Border.all(
            color: AppTheme.star.withValues(alpha: selected ? 0.7 : 0.14),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: Color(0xB3000000),
                    blurRadius: 44,
                    spreadRadius: -14,
                    offset: Offset(0, 20),
                  ),
                  BoxShadow(
                    color: AppTheme.star.withValues(alpha: 0.45),
                    blurRadius: 34,
                    spreadRadius: -4,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 38,
                    spreadRadius: -16,
                    offset: Offset(0, 16),
                  ),
                ],
        ),
        child: Text(
          b.text,
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: b.id % 3 == 0 ? 18 : 16, // a little size variety
            height: 1.3,
            color: AppTheme.moon,
          ),
        ),
      ),
    );
  }
}

/// The "Start this one?" confirm card: bobs at a fixed 6s, scales in from the
/// corner nearest the bubble, ember-tinted inner border.
class _ConfirmCard extends StatefulWidget {
  const _ConfirmCard({
    required this.origin,
    required this.onCancel,
    required this.onStart,
  });

  final Alignment origin;
  final VoidCallback onCancel;
  final VoidCallback onStart;

  @override
  State<_ConfirmCard> createState() => _ConfirmCardState();
}

class _ConfirmCardState extends State<_ConfirmCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment(-0.2, -1),
          end: Alignment(0.2, 1),
          colors: [Color(0xFA2D2C60), Color(0xF51E204E)],
        ),
        border: Border.all(color: AppTheme.ember.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xB3000000),
            blurRadius: 46,
            offset: Offset(0, 20),
            spreadRadius: -14,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Start this one?',
            style: GoogleFonts.fraunces(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.moon,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill('Not this', filled: false, onTap: widget.onCancel),
              const SizedBox(width: 9),
              _pill('Start', filled: true, onTap: widget.onStart),
            ],
          ),
        ],
      ),
    );

    // Scale-in from the corner nearest the bubble.
    final entering = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: const Cubic(.34, 1.4, .6, 1),
      builder: (context, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.7 + 0.3 * v,
          alignment: widget.origin,
          child: child,
        ),
      ),
      child: content,
    );

    // Gentle 6s bob.
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -9 * Curves.easeInOut.transform(_bob.value)),
        child: child,
      ),
      child: entering,
    );
  }

  Widget _pill(String label, {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: filled ? 18 : 15, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: filled
              ? const LinearGradient(colors: [AppTheme.star, AppTheme.starLight])
              : null,
          color: filled ? null : AppTheme.moon.withValues(alpha: 0.08),
          border: filled
              ? null
              : Border.all(color: AppTheme.moon.withValues(alpha: 0.14)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: filled ? FontWeight.w800 : FontWeight.w700,
            color: filled ? AppTheme.night : AppTheme.moon.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
