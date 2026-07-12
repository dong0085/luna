import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../providers/providers.dart';
import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/player_controls.dart';
import '../widgets/story_cover.dart';

/// Playback with controls, background audio, save-on-first-play and resume.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  StreamSubscription<ProcessingState>? _completeSub;

  /// The player is an app-wide singleton, so a fresh listener can immediately
  /// receive a stale `completed` from a previous playback. Only treat
  /// `completed` as real once we've first seen the newly-loaded source become
  /// active (loading/buffering/ready).
  bool _readyForCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final story = ref.read(currentStoryProvider);
      if (story != null) {
        // Reopening from the mini player: the story is already loaded and
        // playing, so re-loading would reset the source and restart it. Only
        // load when this is a different (freshly generated / chosen) story.
        final loaded = ref.read(playerControllerProvider);
        if (loaded?.id != story.id) {
          ref.read(playerControllerProvider.notifier).load(story);
        }
      }
      // When the story ends, drift to the "finished" screen.
      final player = ref.read(audioPlayerProvider);
      _completeSub = player.processingStateStream.listen((s) {
        if (s != ProcessingState.completed) {
          _readyForCompletion = true;
        } else if (_readyForCompletion && mounted) {
          context.pushReplacement(Routes.finished);
        }
      });
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final story = ref.watch(currentStoryProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final player = controller.player;

    if (story == null) {
      return const AmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('No story loaded.')),
        ),
      );
    }

    return AmbientBackground(
      seed: 2,
      starCount: 50,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: IconButton(
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.moon.withValues(alpha: 0.6),
                  ),
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(Routes.home),
                ),
              ),
              Positioned(
                top: 8,
                right: 22,
                child: GestureDetector(
                  onTap: () => context.push(Routes.settings),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.moon.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppTheme.moon.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      size: 20,
                      color: AppTheme.moon.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final isSmall = height < 760;
                  final isTiny = height < 650;

                  final coverSize = isTiny ? 140.0 : (isSmall ? 180.0 : 232.0);
                  final padding = EdgeInsets.fromLTRB(
                    30,
                    isTiny ? 44.0 : (isSmall ? 50.0 : 56.0),
                    30,
                    isTiny ? 16.0 : (isSmall ? 28.0 : 40.0),
                  );

                  return Padding(
                    padding: padding,
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        StoryCover(size: coverSize),
                        SizedBox(
                          height: isTiny ? 16.0 : (isSmall ? 24.0 : 34.0),
                        ),
                        Text(
                          story.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: text.headlineMedium?.copyWith(
                            fontSize: isTiny
                                ? 22.0
                                : (isSmall ? 24.0 : 27.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${story.settings.length.label} · ${_moodLabel(story.settings.mood)}',
                          style: text.bodyMedium?.copyWith(
                            color: AppTheme.star,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(
                          height: isTiny ? 10.0 : (isSmall ? 14.0 : 18.0),
                        ),
                        // Sleep timer chip (visual — a natural next feature to wire).
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: AppTheme.ember.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppTheme.ember.withValues(
                                alpha: 0.22,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bedtime_outlined,
                                size: 14,
                                color: AppTheme.ember,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Sleep timer · when story ends',
                                style: TextStyle(
                                  color: AppTheme.ember,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 3),
                        // Progress driven by the player's position stream.
                        StreamBuilder<Duration>(
                          stream: player.positionStream,
                          builder: (context, snap) {
                            final pos = snap.data ?? Duration.zero;
                            final total =
                                player.duration ?? story.duration;
                            final value = total.inMilliseconds == 0
                                ? 0.0
                                : pos.inMilliseconds /
                                      total.inMilliseconds;
                            return StoryProgressBar(
                              value: value,
                              leftLabel: _fmt(pos),
                              rightLabel: _fmt(total),
                              onSeek: (f) => player.seek(total * f),
                            );
                          },
                        ),
                        SizedBox(
                          height: isTiny ? 16.0 : (isSmall ? 22.0 : 30.0),
                        ),
                        StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (context, snap) {
                            final playing = snap.data?.playing ?? false;
                            final ps = snap.data?.processingState;
                            final loading =
                                ps == ProcessingState.loading ||
                                ps == ProcessingState.buffering;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ControlButton(
                                  icon: Icons.restart_alt,
                                  onTap: controller.restart,
                                ),
                                const SizedBox(width: 26),
                                PlayButton(
                                  playing: playing,
                                  loading: loading,
                                  onTap: controller.playPause,
                                ),
                                const SizedBox(width: 26),
                                ControlButton(
                                  icon: Icons.replay,
                                  subLabel: '15',
                                  onTap: controller.rewind15,
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(
                          height: isTiny ? 12.0 : (isSmall ? 18.0 : 26.0),
                        ),
                        TextButton(
                          onPressed: () => context.go(Routes.home),
                          child: Text(
                            'Back to home',
                            style: text.labelLarge?.copyWith(
                              color: AppTheme.moon.withValues(
                                alpha: 0.62,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _moodLabel(String mood) =>
      mood.isEmpty ? 'Calm' : mood[0].toUpperCase() + mood.substring(1);
}
