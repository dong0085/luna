import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luna/data/story_repository.dart';
import 'package:luna/models/story.dart';
import 'package:luna/models/story_length.dart';
import 'package:luna/models/story_settings.dart';
import 'package:luna/providers/providers.dart';
import 'package:luna/screens/bookshelf_screen.dart';
import 'package:luna/screens/custom_story_screen.dart';
import 'package:luna/screens/finished_screen.dart';
import 'package:luna/screens/generating_screen.dart';
import 'package:luna/screens/home_screen.dart';
import 'package:luna/screens/quick_start_screen.dart';
import 'package:luna/screens/settings_screen.dart';
import 'package:luna/screens/splash_screen.dart';
import 'package:luna/screens/story_detail_screen.dart';
import 'package:luna/theme/app_theme.dart';
import 'package:luna/widgets/motion.dart';

/// Renders each screen at phone dimensions and fails on any layout overflow or
/// build assertion — the headless stand-in for the click-through we can't run.
/// (Player is excluded: its audio plugin isn't available in a widget test; it's
/// verified on macOS / by the manual walkthrough.)
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final story = Story(
    id: 'story-1',
    title: 'The Lantern Keeper',
    text:
        'Every evening, when the harbor went the colour of plums, Old Rell '
            'climbed the winding stair to light the lantern. ' *
        3,
    audioUrl: 'https://example.com/a.mp3',
    durationSeconds: 605,
    settings: const StorySettings(
      topic: 'a lighthouse keeper',
      mood: 'Cozy',
      length: StoryLength.medium,
      voice: 'Warm',
    ),
    lastPositionSeconds: 252,
    listenedAt: DateTime(2026, 7, 9),
  );

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    StoryRepository? repo,
    Story? current,
    bool reduceMotion = false,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // List element type is inferred as riverpod's Override (not named here
    // because it isn't part of the package's public export surface).
    final overrides = [
      storyRepositoryProvider.overrideWithValue(repo ?? _FakeRepo()),
    ];
    if (current != null) {
      overrides.add(
        currentStoryProvider.overrideWith(() => _SeededCurrentStory(current)),
      );
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: MotionConfig(reduceMotion: reduceMotion, child: screen),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));
    // Replace the tree so State.dispose() cancels timers/tickers cleanly.
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('Splash renders', (t) => pump(t, const SplashScreen()));
  testWidgets('Home renders', (t) => pump(t, const HomeScreen()));
  testWidgets('Quick start renders', (t) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(390, 844);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(
      ProviderScope(
        overrides: [storyRepositoryProvider.overrideWithValue(_FakeRepo())],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const QuickStartScreen(seed: 1),
        ),
      ),
    );
    // First bubble spawns at 200ms (+40ms vis); let the pop-in settle.
    await t.pump(const Duration(milliseconds: 260));
    await t.pump(const Duration(milliseconds: 700));

    // Find the first displayed bubble by looking for one of the seed texts.
    final seeds = [
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
    Finder? bubble;
    for (final seed in seeds) {
      final finder = find.text(seed);
      if (finder.evaluate().isNotEmpty) {
        bubble = finder;
        break;
      }
    }
    expect(bubble, isNotNull);
    await t.tap(bubble!);
    await t.pump(const Duration(milliseconds: 400));

    // Replace the tree so State.dispose() cancels timers/tickers cleanly.
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 100));
  });
  testWidgets('Custom renders', (t) => pump(t, const CustomStoryScreen()));
  testWidgets('Settings renders', (t) => pump(t, const SettingsScreen()));
  testWidgets(
    'Bookshelf (empty) renders',
    (t) => pump(t, const BookshelfScreen()),
  );
  testWidgets('Finished renders', (t) => pump(t, const FinishedScreen()));
  testWidgets('Generating renders', (t) => pump(t, const GeneratingScreen()));
  testWidgets(
    'Story detail renders',
    (t) => pump(t, StoryDetailScreen(story: story)),
  );
  testWidgets(
    'Bookshelf (populated) renders',
    (t) => pump(
      t,
      const BookshelfScreen(),
      repo: _FakeRepo([story, story, story]),
    ),
  );

  // Reduce-motion path (stilled animations) must also render cleanly.
  testWidgets(
    'Splash renders (reduce motion)',
    (t) => pump(t, const SplashScreen(), reduceMotion: true),
  );
  testWidgets(
    'Home renders (reduce motion)',
    (t) => pump(t, const HomeScreen(), reduceMotion: true),
  );
  testWidgets(
    'Generating renders (reduce motion)',
    (t) => pump(t, const GeneratingScreen(), reduceMotion: true),
  );
}

class _FakeRepo implements StoryRepository {
  _FakeRepo([this.stories = const []]);
  final List<Story> stories;

  @override
  Future<void> init() async {}
  @override
  List<Story> all() => stories;
  @override
  Story? get(String id) => null;
  @override
  bool exists(String id) => false;
  @override
  Future<void> save(Story story) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> clear() async {}
}

class _SeededCurrentStory extends CurrentStoryNotifier {
  _SeededCurrentStory(this.story);
  final Story story;
  @override
  Story? build() => story;
}
