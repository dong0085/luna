import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luna/data/story_repository.dart';
import 'package:luna/models/story.dart';
import 'package:luna/models/story_length.dart';
import 'package:luna/models/story_settings.dart';
import 'package:luna/providers/providers.dart';
import 'package:luna/screens/generating_screen.dart';
import 'package:luna/theme/app_theme.dart';
import 'package:luna/widgets/motion.dart';

/// The scripted sequence is deterministic (timer-driven), so we can pump the
/// fake clock straight to the reveal and assert the cover payoff renders. The
/// smoke test only ever reaches the idle phase (it pumps 60ms), so this is the
/// gate for the turn2 layout at phone size.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final story = Story(
    id: 'gen-1',
    title: 'The Lantern Keeper',
    text: 'A quiet story.',
    audioUrl: 'https://example.com/a.mp3',
    durationSeconds: 605,
    settings: const StorySettings(
      topic: 'a lighthouse keeper',
      mood: 'cozy',
      length: StoryLength.medium,
    ),
  );

  Future<void> mount(WidgetTester t, {bool reduce = false}) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(390, 844);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          storyRepositoryProvider.overrideWithValue(_FakeRepo()),
          // A real loading→data transition (mirrors the on-ramps) so the
          // screen's listen-only handler records the story.
          generationProvider.overrideWith(() => _DelayedGen(story)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: MotionConfig(reduceMotion: reduce, child: const GeneratingScreen()),
        ),
      ),
    );
  }

  // The cover Column is pre-staged in the tree at opacity 0 so the reveal can
  // animate it in, so `find.text` matches it even while hidden — assert on the
  // reveal's opacity to test actual visibility.
  double coverOpacity(WidgetTester t) => t
      .widget<FadeTransition>(find.descendant(
        of: find.byKey(const ValueKey('cover-reveal')),
        matching: find.byType(FadeTransition),
      ))
      .opacity
      .value;

  testWidgets('reveals the cover after the scripted load window', (t) async {
    await mount(t);

    // Into the load window (~3000ms): a status phrase is cross-fading and the
    // cover is present but still hidden (opacity ~0).
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 2700));
    expect(find.textContaining('night sky', findRichText: true), findsOneWidget);
    expect(coverOpacity(t), lessThan(0.05));

    // Past the 8.2s min dwell → turn2 fires (story was ready early) and the
    // cover reveal begins; a follow-up pump lets the fade finish. Stop short of
    // arrive (12700ms) and navigate (14400ms) — there's no router here.
    await t.pump(const Duration(milliseconds: 8400)); // ~11400ms: reveal begins
    await t.pump(const Duration(milliseconds: 1200)); // ~12600ms: fade settled
    expect(find.text('The Lantern Keeper'), findsOneWidget);
    expect(find.text('~10 min · Cozy'), findsOneWidget);
    expect(coverOpacity(t), greaterThan(0.95));

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 100));
  });

  testWidgets('reveal still renders under reduce-motion', (t) async {
    await mount(t, reduce: true);
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 11100)); // ~11400ms: reveal begins
    await t.pump(const Duration(milliseconds: 1200)); //  ~12600ms: fade settled
    expect(find.text('The Lantern Keeper'), findsOneWidget);
    expect(find.text('~10 min · Cozy'), findsOneWidget);
    expect(coverOpacity(t), greaterThan(0.95));

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 100));
  });
}

/// Resolves after a short delay so the provider goes loading → data, the exact
/// transition the screen listens for.
class _DelayedGen extends GenerationNotifier {
  _DelayedGen(this.story);
  final Story story;

  @override
  Future<Story?> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return story;
  }
}

class _FakeRepo implements StoryRepository {
  @override
  Future<void> init() async {}
  @override
  List<Story> all() => const [];
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
