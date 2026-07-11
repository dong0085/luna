import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luna/data/story_repository.dart';
import 'package:luna/models/story.dart';
import 'package:luna/providers/providers.dart';
import 'package:luna/screens/quick_start_screen.dart';
import 'package:luna/theme/app_theme.dart';

/// The QS_HEADINGS list, mirrored here to probe the live bubbles by text.
const _headings = [
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

int _liveCount() =>
    _headings.where((h) => find.text(h).evaluate().isNotEmpty).length;

String? _anyLive() {
  for (final h in _headings) {
    if (find.text(h).evaluate().isNotEmpty) return h;
  }
  return null;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> mount(WidgetTester t, {int seed = 1}) async {
    t.view.devicePixelRatio = 1.0;
    t.view.physicalSize = const Size(390, 844);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      ProviderScope(
        overrides: [storyRepositoryProvider.overrideWithValue(_FakeRepo())],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: QuickStartScreen(seed: seed),
        ),
      ),
    );
  }

  testWidgets('initial burst — first bubble after ~200ms, not before', (t) async {
    await mount(t);
    await t.pump(const Duration(milliseconds: 180));
    expect(_liveCount(), 0);
    await t.pump(const Duration(milliseconds: 90)); // total ~270ms
    expect(_liveCount(), greaterThanOrEqualTo(1));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 700));
  });

  testWidgets('never more than 3 bubbles, no duplicate texts', (t) async {
    await mount(t, seed: 3);
    for (var i = 0; i < 250; i++) {
      await t.pump(const Duration(milliseconds: 120)); // ~30s total
      expect(_liveCount(), lessThanOrEqualTo(3),
          reason: 'more than 3 bubbles at step $i');
      for (final h in _headings) {
        expect(find.text(h).evaluate().length, lessThanOrEqualTo(1),
            reason: 'duplicate live text "$h" at step $i');
      }
    }
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 700));
  });

  testWidgets('selected bubble is exempt from auto-death; field freezes', (t) async {
    await mount(t, seed: 5);
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 700));
    final text = _anyLive();
    expect(text, isNotNull);
    await t.tap(find.text(text!));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Start this one?'), findsOneWidget);

    // Well past the 6.5–9s lifetime: the selected bubble must still be there.
    await t.pump(const Duration(seconds: 12));
    expect(find.text(text), findsOneWidget);
    expect(find.text('Start this one?'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 700));
  });

  testWidgets('cannot select a second bubble while one is selected', (t) async {
    await mount(t, seed: 7);
    // Let a couple bubbles arrive.
    await t.pump(const Duration(milliseconds: 1900));
    final first = _anyLive();
    expect(first, isNotNull);
    await t.tap(find.text(first!));
    await t.pump(const Duration(milliseconds: 400));

    // Tap a different live bubble, if any — selection must not change.
    for (final h in _headings) {
      if (h != first && find.text(h).evaluate().isNotEmpty) {
        await t.tap(find.text(h));
        await t.pump(const Duration(milliseconds: 400));
        break;
      }
    }
    expect(find.text('Start this one?'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 700));
  });
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
