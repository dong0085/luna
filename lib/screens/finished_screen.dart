import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/story_cover.dart';

/// Shown when a story reaches the end. For a freshly generated story this is
/// the one explicit save point ("Save to Bookshelf"); for a replay of an
/// already-saved story it's a calm send-off (there's nothing to save).
class FinishedScreen extends ConsumerWidget {
  const FinishedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final story = ref.watch(currentStoryProvider);
    // A replayed story is already on the shelf (it exists in the repo); a fresh
    // draft is not. Only the draft gets the explicit save prompt. (Reading the
    // repo — not the player — keeps this off the audio plugin in widget tests.)
    final alreadySaved =
        story != null && ref.read(storyRepositoryProvider).exists(story.id);
    return AmbientBackground(
      seed: 10,
      starCount: 44,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 40, 34, 24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StoryCover(size: 150),
                      const SizedBox(height: 38),
                      SizedBox(
                        width: 280,
                        child: Text(
                          alreadySaved
                              ? 'Sleep well tonight'
                              : 'The stories are yours to keep',
                          textAlign: TextAlign.center,
                          style: text.headlineMedium?.copyWith(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 270,
                        child: Text(
                          alreadySaved
                              ? 'This story is already on your shelf, waiting '
                                  'for the next quiet night.'
                              : 'Save tonight’s story to your Bookshelf, or '
                                  'drift back home — it’ll be here whenever you '
                                  'want it again.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: AppTheme.moon.withValues(alpha: 0.6),
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  label:
                      alreadySaved ? 'Back to Bookshelf' : 'Save to Bookshelf',
                  icon:
                      alreadySaved ? Icons.auto_stories : Icons.bookmark_border,
                  onPressed: () {
                    // Fresh draft: persist here (the one explicit save point).
                    // Replay: it's already saved, so just head to the shelf.
                    if (!alreadySaved) {
                      ref.read(playerControllerProvider.notifier).save();
                    }
                    context.go(Routes.bookshelf);
                  },
                ),
                TextButton(
                  onPressed: () => context.go(Routes.home),
                  child: Text('Back to home',
                      style: TextStyle(
                        color: AppTheme.moon.withValues(alpha: 0.66),
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
}
