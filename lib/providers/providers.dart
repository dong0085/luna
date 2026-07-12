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
  void clear() => state = null;
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

// --- Player (playback + explicit save + resume) -----------------------------

final playerControllerProvider =
    NotifierProvider<PlayerController, Story?>(PlayerController.new);

/// Drives the shared [AudioPlayer]: loads a story, resumes from its last
/// position, and — once the story is on the shelf — continuously persists the
/// position. A freshly generated story is only an in-memory draft: it reaches
/// the Bookshelf when the user explicitly [save]s it (the Finished screen), and
/// is dropped by [discard] (the mini player's ×). Replaying an already-saved
/// story keeps persisting its resume position.
class PlayerController extends Notifier<Story?> {
  late final AudioPlayer _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<ProcessingState>? _stateSub;

  /// True once the current story lives in the repo — either because we're
  /// replaying a saved story or because the user just saved this draft. Gates
  /// position/completion persistence so a draft never touches Hive on its own.
  bool _saved = false;
  DateTime _lastPersist = DateTime.fromMillisecondsSinceEpoch(0);

  AudioPlayer get player => _player;

  @override
  Story? build() {
    _player = ref.read(audioPlayerProvider);
    ref.onDispose(() {
      _positionSub?.cancel();
      _stateSub?.cancel();
    });
    return null;
  }

  /// Load a story into the player and resume from its last position.
  Future<void> load(Story story) async {
    state = story;
    // Already-saved stories (Bookshelf replay) keep persisting their position;
    // a fresh draft does not until the user saves it.
    _saved = ref.read(storyRepositoryProvider).exists(story.id);
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

  /// Persist the current story to the Bookshelf. This is the single explicit
  /// save point (the Finished screen's "Save to Bookshelf").
  Future<void> save() async {
    final story = state;
    if (story == null) return;
    final saved = story.copyWith(listenedAt: DateTime.now());
    state = saved;
    _saved = true;
    ref.read(currentStoryProvider.notifier).set(saved);
    await ref.read(storyRepositoryProvider).save(saved);
    ref.read(libraryProvider.notifier).refresh();
  }

  /// Drop the current story: stop playback and clear it from the player and the
  /// now-playing channel so the mini player disappears. A never-saved draft is
  /// simply gone; a saved story stays on the shelf (only its playback stops).
  Future<void> discard() async {
    await _player.stop();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _saved = false;
    state = null;
    ref.read(currentStoryProvider.notifier).clear();
  }

  Future<void> _persistPosition(Duration pos) async {
    final story = state;
    if (story == null || !_saved) return;
    final updated = story.copyWith(lastPositionSeconds: pos.inSeconds);
    state = updated;
    await ref.read(storyRepositoryProvider).save(updated);
  }

  Future<void> _markCompleted() async {
    final story = state;
    if (story == null) return;
    final updated = story.copyWith(completed: true, lastPositionSeconds: 0);
    state = updated;
    ref.read(currentStoryProvider.notifier).set(updated);
    // Park at the start so a finished story shows 0:00 and replays cleanly
    // (the mini player stays put when a story ends off the Player screen).
    await _player.seek(Duration.zero);
    // Only persist if the story is on the shelf; a finished draft still waits
    // for an explicit save.
    if (_saved) {
      await ref.read(storyRepositoryProvider).save(updated);
      ref.read(libraryProvider.notifier).refresh();
    }
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
