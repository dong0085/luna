# Luna

A calm bedtime-story app for adults. Luna generates gentle stories and reads them aloud with a storybook aesthetic meant to transport you into a bedtime-story world — then keeps every story you've heard on a replay Bookshelf so you can drift back any night.

Built at cuHacking 2026.

## What it does

- **Generate a story** two ways — **Quick start** (tap a drifting "spark" of an idea) or **Custom** (topic, mood, narrator voice, background sound, length).
- **Listen** with a full player: play/pause, restart, 15-second rewind, scrubbing, and **background audio + lock-screen controls** so it keeps playing with the screen off.
- **Fall asleep mid-story** — playback position is saved continuously, so replay resumes where you left off.
- **Bookshelf** — every story you start playing is saved locally and appears on a shelf for reliable replay (audio is cached on first listen).

Story lengths: Short (~5 min), Medium (~10 min), Long (~15 min).

No accounts. Everything is stored locally on the device.

## Tech

Flutter · Riverpod (state) · go_router (navigation) · just_audio + just_audio_background (playback) · Hive (local store) · Google Fonts (Fraunces + Nunito Sans). The UI was designed in Claude Design and implemented to match.

## Getting started

Requires the Flutter SDK (Dart 3.12+).

```bash
flutter pub get
flutter run            # pick a device; macOS desktop works out of the box
```

Run the checks:

```bash
flutter analyze        # expected: one intentional "LockCachingAudioSource is experimental" warning
flutter test           # unit tests + per-screen render tests
```

## Status

The frontend is complete and runs **end-to-end against a mock** generator (a canned story + a public sample audio clip). The generation backend (story text + narration) is not wired up yet.

To connect it, change one function — `StoryApi.generateStory()` in `lib/data/story_api.dart`. The API contract is:

```
POST /stories/generate
  { "topic": "...", "mood": "calm", "length": "short" }
→ { "id", "title", "story", "audioUrl", "durationSeconds" }
```

## Docs

See [CLAUDE.md](CLAUDE.md) for the architecture (provider graph, the generate → play → save → resume pipeline, persistence, and how to verify a visual change).
