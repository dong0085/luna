import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../models/story.dart';
import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/mini_player.dart';

/// Level 2. A replay library of stories the user has listened to. Populated as
/// a side effect of playback — nothing is generated here.
class BookshelfScreen extends ConsumerWidget {
  const BookshelfScreen({super.key});

  // A little palette so saved covers look varied.
  static const _palettes = <List<Color>>[
    [AppTheme.violetDeep, AppTheme.star, AppTheme.ember],
    [Color(0xFF6E63C9), Color(0xFF9E8EF2), AppTheme.ember],
    [Color(0xFFA08BF0), Color(0xFFC9B9FF), Color(0xFFEFC79A)],
    [Color(0xFF7D6FDB), AppTheme.star, AppTheme.ember],
    [Color(0xFF6B60C4), Color(0xFFA492F0), AppTheme.ember],
  ];
  static const _heights = [200.0, 150.0, 176.0, 150.0, 200.0, 168.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(libraryProvider);
    final text = Theme.of(context).textTheme;

    return AmbientBackground(
      seed: 4,
      starCount: 46,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const MiniPlayer(),
        appBar: AppBar(
          leadingWidth: 44,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text('Your Bookshelf',
                      style: text.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                Expanded(
                  child: stories.isEmpty
                      ? const _EmptyShelf()
                      : MasonryGridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 22,
                          crossAxisSpacing: 16,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: stories.length,
                          itemBuilder: (context, i) {
                            final story = stories[i];
                            return _ShelfItem(
                              story: story,
                              colors: _palettes[i % _palettes.length],
                              height: _heights[i % _heights.length],
                              onTap: () {
                                ref
                                    .read(currentStoryProvider.notifier)
                                    .set(story);
                                context.push(Routes.storyDetail);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfItem extends StatelessWidget {
  const _ShelfItem({
    required this.story,
    required this.colors,
    required this.height,
    required this.onTap,
  });

  final Story story;
  final List<Color> colors;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final resume = story.lastPositionSeconds > 0 && !story.completed;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                    stops: const [0.0, 0.36, 1.0],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _dot(0.24, 0.16, 3),
                    _dot(0.64, 0.26, 2),
                    // hills
                    Positioned(
                      bottom: -26,
                      right: -0.16 * 160,
                      child: _hill(140, 90, const Color(0xB8090A22)),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -0.12 * 160,
                      child: _hill(130, 80, const Color(0x800E1030)),
                    ),
                    // moon
                    Positioned(
                      top: height * 0.18,
                      right: 26,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFBF3DE),
                          boxShadow: [
                            BoxShadow(
                              color: colors.first.withValues(alpha: 0.9),
                              offset: const Offset(9, 8),
                              spreadRadius: -1,
                            ),
                            BoxShadow(
                              color: const Color(0x73FBF3DE),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(story.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
              )),
          const SizedBox(height: 4),
          Text(
            resume ? 'Resume' : story.settings.length.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: resume ? AppTheme.ember : AppTheme.moon.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hill(double w, double h, Color color) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.elliptical(120, 80)),
        ),
      );

  Widget _dot(double left, double top, double d) => Positioned(
        left: left * 160,
        top: top * height,
        child: Container(
          width: d,
          height: d,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFF7E6),
          ),
        ),
      );
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // crescent moon carved from a parchment disc
                SizedBox(
                  width: 96,
                  height: 96,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.moon,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.ember.withValues(alpha: 0.28),
                              blurRadius: 60,
                              spreadRadius: 14,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.night,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Text('Your stories appear here',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: 278,
                  child: Text(
                    'After you listen to a story, it settles onto your shelf so '
                    'you can drift back to it any night.',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: AppTheme.moon.withValues(alpha: 0.58),
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Builder(
            builder: (context) => GradientButton(
              label: 'Create your first story',
              onPressed: () => context.push(Routes.quickStart),
            ),
          ),
        ),
      ],
    );
  }
}
