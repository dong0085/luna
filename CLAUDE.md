# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

**Luna** is a Flutter bedtime-story app (cuHacking 2026): it generates calm stories + narration, plays them with background audio, and saves listened stories to a replay "Bookshelf". No auth; persistence is local-only (Hive). The backend is not built yet — the app runs end-to-end against a mock.

## Commands

```bash
flutter run -d macos          # run (macOS is the connected device — see "Verification")
flutter analyze               # static analysis / type-check (fast, run this often)
flutter test                  # all tests
flutter test test/screens_smoke_test.dart          # just the per-screen render tests
flutter test --plain-name "Story survives a JSON round-trip"   # a single test by name
flutter pub add <pkg>         # add a dependency (lets pub resolve the version)
```

`flutter analyze` is expected to report exactly one warning: `LockCachingAudioSource is experimental`. That is intentional (cache-on-first-play) — treat a clean run as "1 issue found", not zero.

## Connecting the real backend

`lib/data/story_api.dart` `StoryApi.generateStory()` is the **single swap point**. It currently fakes a ~2s round-trip and returns a canned story pointing at a public sample MP3. The commented `http` block right below the mock is the real call. Change only this function to go live.

**API contract is `{topic, mood, length}` → `{id, title, story, audioUrl, durationSeconds}` and must not be changed unilaterally.** `StorySettings` also carries `voice`, `backgroundSound`, and a possible literal `"Adaptive"` — these are local-only. `StorySettings.toRequestJson()` deliberately omits them and resolves `"Adaptive"` mood to a real mood (`calm`). Keep that discipline: store new UI inputs locally; coordinate with the backend before adding anything to the POST.

## Architecture

State is Riverpod; routing is `go_router` (routes in `lib/router.dart`). The core loop is **Home → (Quick start | Custom) → Generating → Player → Finished**, with **Bookshelf → Story detail → Player** as a separate replay path.

**Provider graph** (`lib/providers/providers.dart`) — the pieces only make sense together:
- `audioPlayerProvider` is a **single app-wide `AudioPlayer`**, kept-alive (never autoDispose). `just_audio_background` allows exactly one player instance, so never construct another.
- `storyRepositoryProvider` throws by default and is **overridden in `main()`** with the Hive-opened instance. Tests override it with a fake.
- `generationProvider` (AsyncNotifier) runs the API call. The **Generating screen watches it** and navigates when it returns; it does not know about the API itself.
- `currentStoryProvider` is the **handoff channel**: generation sets it before Player; Bookshelf/Detail set it for replay. The Player always reads whatever is current.
- `PlayerController` drives the shared player: on `load()` it sets a `LockCachingAudioSource` (with a `MediaItem` tag — required for lock-screen/background metadata), seeks to the story's resume position, then wires listeners for **save-on-first-play** (persist the moment `playing` first becomes true), throttled position persistence, and completion.

**Persistence** (`lib/data/story_repository.dart`): one Hive box of `Story` JSON strings keyed by id — no TypeAdapters/codegen. `Story.toJson/fromJson` handle the (de)serialization; `libraryProvider` reflects the box and is refreshed after saves.

**Design system** (`lib/theme/app_theme.dart` + `lib/widgets/`): the UI was imported from a Claude Design project (`Luna.dc.html`) and implemented faithfully. Colors/gradients/fonts live as tokens on `AppTheme`; screens compose shared widgets (`StarField`, `StoryCover`, `GradientButton`, `MoonGlow`, player controls, `AmbientBackground`). Use `flutter_animate` for looping hero effects (float, breathe, shimmer); the star field is deliberately a single `CustomPainter` + one controller rather than N animated widgets. Google Fonts (Fraunces serif, Nunito Sans) load at runtime — reference them via `GoogleFonts.fraunces(...)`, never a bare `fontFamily: 'Fraunces'`.

**Design fidelity rule:** keep every component the design shows even when it has no backing feature (this app is authless, yet Settings still renders a profile card + "Sign out", and the Player a "Sleep timer" chip + gear). Do not strip UI just because it doesn't function.

## Verification

This is a visual app: `flutter analyze` + `flutter test` prove it **compiles**, not that it **renders correctly**.
- Run `flutter run -d macos` as the fidelity gate. A clean boot reaches a "DevTools available" line with no `RenderFlex`/overflow/exception in the log. `Failed to foreground app; open returned 1` is benign (macOS not auto-raising the window). A human still checks pixel fidelity and that fonts resolved rather than falling back.
- `test/screens_smoke_test.dart` is the **headless overflow gate**: it pumps every screen at 390×844 with faked providers (and `GoogleFonts.config.allowRuntimeFetching = false`), so overflow/build errors on screens a macOS launch never navigated to still fail CI. Run it after any layout change. It already caught a real `const`-list `.shuffle()` crash and CTA overflows. **PlayerScreen is excluded** (its audio plugin isn't available in a widget test) — verify the Player on a device/macOS instead.

## Platform setup already applied

- macOS deployment target is **12.0** (`audio_service` needs it) and `com.apple.security.network.client` is enabled in both `.entitlements` so Google Fonts + audio streaming work.
- Android manifest declares the `just_audio_background` service/receiver + `WAKE_LOCK`/`FOREGROUND_SERVICE`/`FOREGROUND_SERVICE_MEDIA_PLAYBACK` and `RECORD_AUDIO`/`INTERNET`; iOS `Info.plist` has the `audio` background mode + mic/speech usage strings. Background-audio platform config exists but screen-off playback + lock-screen controls still need a real-device check.
