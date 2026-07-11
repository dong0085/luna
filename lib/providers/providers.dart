import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/story_api.dart';
import '../data/story_repository.dart';
import '../models/story.dart';
import '../models/story_settings.dart';

// --- Services ---------------------------------------------------------------

final storyApiProvider = Provider<StoryApi>((ref) => StoryApi());

/// Overridden in `main()` with the initialized (box-open) instance.
final storyRepositoryProvider = Provider<StoryRepository>(
  (ref) => throw UnimplementedError('storyRepositoryProvider must be overridden'),
);

/// The single, app-wide [AudioPlayer]. `just_audio_background` allows exactly
/// one player instance, so this is a kept-alive singleton — never autoDispose.
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

// --- Library (saved / listened stories) -------------------------------------

final libraryProvider =
    NotifierProvider<LibraryNotifier, List<Story>>(LibraryNotifier.new);

class LibraryNotifier extends Notifier<List<Story>> {
  @override
  List<Story> build() => ref.read(storyRepositoryProvider).all();

  void refresh() => state = ref.read(storyRepositoryProvider).all();

  Future<void> remove(String id) async {
    await ref.read(storyRepositoryProvider).delete(id);
    refresh();
  }
}

// --- Reduce motion (accessibility / sleep-app calm) -------------------------

/// When true, ambient loops (starfield, breathing, sky spin, bubble bob…) are
/// stilled. Toggled from Settings; also OR-ed with `MediaQuery.disableAnimations`
/// by `MotionConfig`.
final reduceMotionProvider =
    NotifierProvider<ReduceMotionNotifier, bool>(ReduceMotionNotifier.new);

class ReduceMotionNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
  void toggle() => state = !state;
}

// --- The story currently loaded into the Player -----------------------------

final currentStoryProvider =
    NotifierProvider<CurrentStoryNotifier, Story?>(CurrentStoryNotifier.new);

class CurrentStoryNotifier extends Notifier<Story?> {
  @override
  Story? build() => null;

  void set(Story story) => state = story;
}

// --- Generation -------------------------------------------------------------

final generationProvider =
    AsyncNotifierProvider<GenerationNotifier, Story?>(GenerationNotifier.new);

class GenerationNotifier extends AsyncNotifier<Story?> {
  @override
  Future<Story?> build() async => null;

  Future<void> generate(StorySettings settings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(storyApiProvider).generateStory(settings),
    );
  }

  void reset() => state = const AsyncValue.data(null);
}

// --- Player (playback + save-on-play + resume) ------------------------------

final playerControllerProvider =
    NotifierProvider<PlayerController, Story?>(PlayerController.new);

/// Drives the shared [AudioPlayer]: loads a story, saves it on first play,
/// resumes from its last position, and continuously persists the position.
class PlayerController extends Notifier<Story?> {
  late final AudioPlayer _player;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<ProcessingState>? _stateSub;

  bool _savedThisLoad = false;
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);

  AudioPlayer get player => _player;

  @override
  Story? build() {
    _player = ref.read(audioPlayerProvider);
    ref.onDispose(() {
      _playingSub?.cancel();
      _positionSub?.cancel();
      _stateSub?.cancel();
    });
    return null;
  }

  /// Load a story into the player and resume from its last position.
  Future<void> load(Story story) async {
    state = story;
    _savedThisLoad = false;
    ref.read(currentStoryProvider.notifier).set(story);

    await _player.setAudioSource(
      LockCachingAudioSource(
        Uri.parse(story.audioUrl),
        tag: MediaItem(
          id: story.id,
          title: story.title,
          artist: 'Luna',
          duration: story.duration,
        ),
      ),
      initialPosition: story.lastPosition,
    );

    _wireListeners();
  }

  void _wireListeners() {
    _playingSub?.cancel();
    _playingSub = _player.playingStream.listen((playing) {
      // Save-on-first-play: the moment playback starts, the story earns its
      // place on the Bookshelf.
      if (playing && !_savedThisLoad) {
        _savedThisLoad = true;
        _saveOnPlay();
      }
    });

    _positionSub?.cancel();
    _positionSub = _player.positionStream.listen((pos) {
      final now = DateTime.now();
      if (now.difference(_lastPersist).inSeconds >= 5) {
        _lastPersist = now;
        _persistPosition(pos);
      }
    });

    _stateSub?.cancel();
    _stateSub = _player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed) _markCompleted();
    });
  }

  Future<void> _saveOnPlay() async {
    final story = state;
    if (story == null) return;
    final saved = story.copyWith(listenedAt: DateTime.now());
    state = saved;
    ref.read(currentStoryProvider.notifier).set(saved);
    await ref.read(storyRepositoryProvider).save(saved);
    ref.read(libraryProvider.notifier).refresh();
  }

  Future<void> _persistPosition(Duration pos) async {
    final story = state;
    if (story == null || !_savedThisLoad) return;
    final updated = story.copyWith(lastPositionSeconds: pos.inSeconds);
    state = updated;
    await ref.read(storyRepositoryProvider).save(updated);
  }

  Future<void> _markCompleted() async {
    final story = state;
    if (story == null) return;
    final updated = story.copyWith(completed: true, lastPositionSeconds: 0);
    state = updated;
    await ref.read(storyRepositoryProvider).save(updated);
    ref.read(libraryProvider.notifier).refresh();
  }

  Future<void> playPause() =>
      _player.playing ? _player.pause() : _player.play();

  Future<void> rewind15() async {
    final target = _player.position - const Duration(seconds: 15);
    await _player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> restart() async {
    await _player.seek(Duration.zero);
    await _player.play();
  }
}
