import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import 'story_cover.dart';

/// A persistent "now playing" bar for the screens outside the Player. When a
/// story is loaded, it sits in the Scaffold's bottom slot with the cover, title,
/// a play/pause control, a thin progress line and a × to discard. Tapping the
/// body reopens the full Player.
///
/// It reads [currentStoryProvider] first and renders nothing when there is no
/// story — so it never touches the audio player when idle (keeps the headless
/// smoke test, which has no audio plugin, green).
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final story = ref.watch(currentStoryProvider);
    if (story == null) return const SizedBox.shrink();

    final controller = ref.read(playerControllerProvider.notifier);
    final player = controller.player;
    final text = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.night.withValues(alpha: 0.94),
        border: Border(
          top: BorderSide(color: AppTheme.moon.withValues(alpha: 0.10)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, -8),
            spreadRadius: -12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress line driven by the player's position.
            StreamBuilder<Duration>(
              stream: player.positionStream,
              builder: (context, snap) {
                final pos = snap.data ?? Duration.zero;
                final total = player.duration ?? story.duration;
                final v = total.inMilliseconds == 0
                    ? 0.0
                    : (pos.inMilliseconds / total.inMilliseconds)
                        .clamp(0.0, 1.0);
                return _ProgressLine(value: v);
              },
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(Routes.player),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: [
                      StoryCover(size: 44, float: false),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${story.settings.length.label} · ${_moodLabel(story.settings.mood)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.star,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StreamBuilder<PlayerState>(
                        stream: player.playerStateStream,
                        builder: (context, snap) {
                          final playing = snap.data?.playing ?? false;
                          return _PlayPauseButton(
                            playing: playing,
                            onTap: controller.playPause,
                          );
                        },
                      ),
                      _CloseButton(onTap: controller.discard),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _moodLabel(String mood) =>
      mood.isEmpty ? 'Calm' : mood[0].toUpperCase() + mood.substring(1);
}

/// A 3px violet fill over a faint track, spanning the bar's full width.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      color: AppTheme.moon.withValues(alpha: 0.12),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.star, AppTheme.starLight],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact play/pause — the star-gradient disc from the main control, scaled to
/// the bar (no breathing animation here).
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.5),
            radius: 1.2,
            colors: [AppTheme.starLight, AppTheme.star],
            stops: [0.0, 0.7],
          ),
        ),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          size: 24,
          color: AppTheme.night,
        ),
      ),
    );
  }
}

/// The × that discards the current story and hides the bar.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          Icons.close,
          size: 22,
          color: AppTheme.moon.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
