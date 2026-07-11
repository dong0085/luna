import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/story_length.dart';
import '../models/story_settings.dart';
import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';

/// Quick start on-ramp, per the design: drifting "spark" bubbles of story
/// seeds. Tap one to select it, then confirm to generate. (This replaces the
/// build plan's type/voice seed — see the note handed to the user.)
class QuickStartScreen extends ConsumerStatefulWidget {
  const QuickStartScreen({super.key});

  @override
  ConsumerState<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends ConsumerState<QuickStartScreen> {
  static const _seeds = [
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

  // Fractional slots (x, y) within the bubble area, spread to avoid overlap.
  static const _slots = [
    Offset(0.30, 0.16),
    Offset(0.70, 0.40),
    Offset(0.36, 0.68),
  ];

  final _rng = math.Random();
  // Mutable, shuffled copy (`_seeds` is const and can't be shuffled in place).
  late final List<String> _pool = List<String>.from(_seeds)..shuffle(_rng);
  late List<_Bubble> _bubbles;
  int? _selected;
  Timer? _cycle;
  int _nextId = 0;
  int _seedCursor = 0;

  @override
  void initState() {
    super.initState();
    _bubbles = List.generate(_slots.length, (i) => _spawn(i));
    // Gently rotate one bubble at a time when nothing is selected.
    _cycle = Timer.periodic(const Duration(milliseconds: 4200), (_) {
      if (!mounted || _selected != null) return;
      setState(() {
        final i = _rng.nextInt(_bubbles.length);
        _bubbles[i] = _spawn(i);
      });
    });
  }

  _Bubble _spawn(int slot) {
    final text = _pool[_seedCursor % _pool.length];
    _seedCursor++;
    return _Bubble(
      id: _nextId++,
      text: text,
      slot: slot,
      dur: (5.5 + _rng.nextDouble() * 2),
    );
  }

  @override
  void dispose() {
    _cycle?.cancel();
    super.dispose();
  }

  void _begin(String seed) {
    final settings = StorySettings(topic: seed, length: StoryLength.short);
    ref.read(generationProvider.notifier).generate(settings);
    context.push(Routes.generating);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    _Bubble? selectedBubble;
    for (final b in _bubbles) {
      if (b.id == _selected) selectedBubble = b;
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
                  Text('Quick start',
                      style: text.headlineSmall?.copyWith(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              Text('Tap a spark that calls to you',
                  style: text.bodyMedium?.copyWith(
                    color: AppTheme.moon.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                  )),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final b in _bubbles)
                          _positioned(
                            c,
                            b,
                            dimmed: _selected != null && _selected != b.id,
                            selected: _selected == b.id,
                          ),
                        if (selectedBubble != null)
                          _confirmCard(c, selectedBubble),
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

  Widget _positioned(
    BoxConstraints c,
    _Bubble b, {
    required bool dimmed,
    required bool selected,
  }) {
    final slot = _slots[b.slot];
    final child = _BubbleView(
      key: ValueKey(b.id),
      text: b.text,
      dur: b.dur,
      dimmed: dimmed,
      selected: selected,
      onTap: () {
        if (_selected == null) setState(() => _selected = b.id);
      },
    );
    return Positioned(
      left: slot.dx * c.maxWidth - 75,
      top: slot.dy * c.maxHeight,
      child: SizedBox(width: 150, child: child),
    );
  }

  Widget _confirmCard(BoxConstraints c, _Bubble b) {
    final text = Theme.of(context).textTheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Center(
        child: Container(
          width: 180,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D2C60), Color(0xFF1E204E)],
            ),
            border: Border.all(color: AppTheme.ember.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 46,
                offset: const Offset(0, 20),
                spreadRadius: -14,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start this one?',
                  style: text.titleMedium?.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 13),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _pill(
                    'Not this',
                    filled: false,
                    onTap: () => setState(() => _selected = null),
                  ),
                  const SizedBox(width: 9),
                  _pill('Begin', filled: true, onTap: () => _begin(b.text)),
                ],
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).scaleXY(begin: 0.9, end: 1),
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

class _Bubble {
  _Bubble({required this.id, required this.text, required this.slot, required this.dur});
  final int id;
  final String text;
  final int slot;
  final double dur;
}

class _BubbleView extends StatelessWidget {
  const _BubbleView({
    super.key,
    required this.text,
    required this.dur,
    required this.dimmed,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final double dur;
  final bool dimmed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final view = GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: dimmed ? 0.22 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          scale: selected ? 1.06 : (dimmed ? 0.92 : 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xF52D2C60), Color(0xF01B1E48)],
              ),
              border: Border.all(
                color: AppTheme.star.withValues(alpha: selected ? 0.7 : 0.14),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? AppTheme.star.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.55),
                  blurRadius: selected ? 34 : 38,
                  offset: const Offset(0, 16),
                  spreadRadius: selected ? -4 : -16,
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                fontSize: 16,
                height: 1.3,
                color: AppTheme.moon,
              ),
            ),
          ),
        ),
      ),
    );

    // Gentle float unless selected.
    if (selected) return view;
    return view
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -5, end: 5, duration: (dur * 1000).round().ms, curve: Curves.easeInOut);
  }
}
