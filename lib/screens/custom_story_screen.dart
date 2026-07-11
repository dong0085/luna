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
import '../widgets/gradient_button.dart';
import '../widgets/length_selector.dart';

/// Custom on-ramp: full control over topic, mood, voice, background sound and
/// length. "Adaptive" lets Luna choose; those choices stay local (see
/// [StorySettings]).
class CustomStoryScreen extends ConsumerStatefulWidget {
  const CustomStoryScreen({super.key});

  @override
  ConsumerState<CustomStoryScreen> createState() => _CustomStoryScreenState();
}

class _CustomStoryScreenState extends ConsumerState<CustomStoryScreen> {
  final _topic = TextEditingController();
  StoryLength _length = StoryLength.medium;
  String _mood = 'Adaptive';
  String _voice = 'Adaptive';
  String _sound = 'Adaptive';

  static const _moods = ['Adaptive', 'Calm', 'Dreamy', 'Cozy', 'Adventurous', 'Mysterious'];
  static const _voices = ['Adaptive', 'Default', 'Warm', 'Soft', 'Deep'];
  static const _sounds = ['Adaptive', 'None', 'Rain', 'Waves', 'Fireplace'];

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  void _generate() {
    final settings = StorySettings(
      topic: _topic.text.trim(),
      mood: _mood,
      length: _length,
      voice: _voice,
      backgroundSound: _sound,
    );
    ref.read(generationProvider.notifier).generate(settings);
    context.push(Routes.generating);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AmbientBackground(
      seed: 8,
      starCount: 38,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar.
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 24, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      color: AppTheme.moon,
                      onPressed: () => context.pop(),
                    ),
                    Text('Custom story',
                        style: text.headlineSmall?.copyWith(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 20),
                  children: [
                    Row(
                      children: [
                        const Text('✦',
                            style: TextStyle(color: AppTheme.ember, fontSize: 13)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Adaptive lets Luna choose what best fits your story',
                            style: TextStyle(
                              color: AppTheme.ember.withValues(alpha: 0.75),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _label('Topic'),
                    _TopicField(controller: _topic),
                    _label('Mood'),
                    _ChipRow(
                      options: _moods,
                      selected: _mood,
                      onSelect: (v) => setState(() => _mood = v),
                    ),
                    _label('Narrator voice'),
                    _ChipRow(
                      options: _voices,
                      selected: _voice,
                      onSelect: (v) => setState(() => _voice = v),
                    ),
                    _label('Background sound'),
                    _ChipRow(
                      options: _sounds,
                      selected: _sound,
                      onSelect: (v) => setState(() => _sound = v),
                    ),
                    _label('Length'),
                    LengthSelector(
                      value: _length,
                      onChanged: (l) => setState(() => _length = l),
                    ),
                  ],
                ),
              ),
              // Pinned CTA.
              Container(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x000E1030), AppTheme.night],
                    stops: [0.0, 0.4],
                  ),
                ),
                child: GradientButton(label: 'Generate story', onPressed: _generate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
        child: Text(t.toUpperCase(),
            style: GoogleFonts.fraunces(
              color: AppTheme.moon.withValues(alpha: 0.62),
              fontSize: 13,
              letterSpacing: 1.6,
            )),
      );
}

class _TopicField extends StatelessWidget {
  const _TopicField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppTheme.dusk.withValues(alpha: 0.75),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.moon, fontSize: 15, height: 1.4),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'A lighthouse keeper and a lonely whale',
                hintStyle: TextStyle(color: AppTheme.moon.withValues(alpha: 0.4)),
              ),
            ),
          ),
          Icon(Icons.mic_none, color: AppTheme.star.withValues(alpha: 0.9), size: 20),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final o in options)
          _Chip(
            label: o,
            selected: o == selected,
            adaptive: o == 'Adaptive',
            onTap: () => onSelect(o),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.adaptive,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool adaptive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg;
    final Gradient? gradient;
    final Color? bg;
    final BoxBorder? border;

    if (selected) {
      fg = AppTheme.night;
      gradient = LinearGradient(
        colors: adaptive
            ? const [AppTheme.ember, Color(0xFFF0C79A)]
            : const [AppTheme.star, AppTheme.starLight],
      );
      bg = null;
      border = null;
    } else {
      fg = adaptive ? AppTheme.ember : AppTheme.moon.withValues(alpha: 0.8);
      gradient = null;
      bg = AppTheme.moon.withValues(alpha: 0.07);
      border = Border.all(
        color: adaptive
            ? AppTheme.ember.withValues(alpha: 0.4)
            : AppTheme.moon.withValues(alpha: 0.12),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: gradient,
          color: bg,
          border: border,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (adaptive ? AppTheme.ember : AppTheme.star)
                        .withValues(alpha: 0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (adaptive) ...[
              Text('✦', style: TextStyle(fontSize: 13, color: fg)),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                )),
          ],
        ),
      ),
    );
  }
}
