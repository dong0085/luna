import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/story_cover.dart';

/// Shown when a story reaches the end. The story is already on the shelf
/// (save-on-play), so this is a calm send-off rather than a real save step.
class FinishedScreen extends StatelessWidget {
  const FinishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                          'The stories are yours to keep',
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
                          'Save tonight’s story to your Bookshelf, or drift back '
                          'home — it’ll be here whenever you want it again.',
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
                  label: 'Save to Bookshelf',
                  icon: Icons.bookmark_border,
                  onPressed: () => context.go(Routes.bookshelf),
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
