import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/player_controls.dart';
import '../widgets/story_cover.dart';

/// Details for a saved story: cover, blurb, the settings used, and resume /
/// restart controls that go straight to the Player (replay — no generation).
class StoryDetailScreen extends ConsumerWidget {
  const StoryDetailScreen({super.key});

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(currentStoryProvider);
    final text = Theme.of(context).textTheme;

    if (story == null) {
      return const AmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Story not found.')),
        ),
      );
    }

    final resume = story.lastPositionSeconds > 0 && !story.completed;
    final left = story.duration - story.lastPosition;
    final progress = story.durationSeconds == 0
        ? 0.0
        : story.lastPositionSeconds / story.durationSeconds;

    return AmbientBackground(
      seed: 16,
      starCount: 38,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 8, 26, 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down,
                          color: AppTheme.moon.withValues(alpha: 0.7)),
                      onPressed: () => context.pop(),
                    ),
                    _circleButton(
                      Icons.delete_outline,
                      () async {
                        await ref
                            .read(libraryProvider.notifier)
                            .remove(story.id);
                        if (context.mounted) context.pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 6),
                        StoryCover(size: 186),
                        const SizedBox(height: 26),
                        Text(story.title,
                            textAlign: TextAlign.center,
                            style: text.headlineMedium?.copyWith(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 7),
                        Text(
                          '${story.settings.length.duration} · ${_lastPlayed(story.listenedAt)}',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.moon.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 9,
                          runSpacing: 9,
                          alignment: WrapAlignment.center,
                          children: [
                            _tag(story.settings.length.duration),
                            _tag(_cap(story.settings.mood)),
                            if (story.settings.voice != null)
                              _tag('${story.settings.voice} voice'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        // Excerpt with a fade at the bottom.
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.transparent],
                            stops: [0.6, 1.0],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 132),
                            child: Text(
                              story.text,
                              style: text.bodyLarge?.copyWith(
                                color: AppTheme.moon.withValues(alpha: 0.72),
                                fontSize: 15.5,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                StoryProgressBar(value: progress),
                const SizedBox(height: 18),
                GradientButton(
                  label: resume ? 'Resume · ${_fmt(left)} left' : 'Play',
                  icon: Icons.play_arrow,
                  onPressed: () {
                    ref.read(currentStoryProvider.notifier).set(story);
                    context.pushReplacement(Routes.player);
                  },
                ),
                if (resume)
                  TextButton(
                    onPressed: () {
                      ref.read(currentStoryProvider.notifier).set(
                            story.copyWith(lastPositionSeconds: 0),
                          );
                      context.pushReplacement(Routes.player);
                    },
                    child: Text('Start over',
                        style: TextStyle(
                          color: AppTheme.moon.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w700,
                        )),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

  String _lastPlayed(DateTime? when) {
    if (when == null) return 'Not played yet';
    final days = DateTime.now().difference(when).inDays;
    if (days <= 0) return 'Last played today';
    if (days == 1) return 'Last played yesterday';
    return 'Last played $days nights ago';
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppTheme.moon.withValues(alpha: 0.07),
          border: Border.all(color: AppTheme.moon.withValues(alpha: 0.14)),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.moon.withValues(alpha: 0.82),
            )),
      );

  Widget _circleButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.moon.withValues(alpha: 0.06),
            border: Border.all(color: AppTheme.moon.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, size: 17, color: AppTheme.moon.withValues(alpha: 0.7)),
        ),
      );
}
