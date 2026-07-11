# Luna — Backend API Endpoints

Coordination doc for the backend dev. Luna is **authless** and persists
everything **locally** (Hive). That rules out most endpoints a backend usually
grows — there is **no auth, no user, no bookshelf/library/sync, and no separate
audio endpoint**. The "Sign out" button and profile card are cosmetic
(design-fidelity rule); the audio URL rides inside the generate response and is
cached client-side by URL.

**Two live endpoints + one optional.** Keep the surface aligned with what the
app actually consumes.

---

## 1. `POST /stories/generate` — already frozen

The single generation call. Contract is fixed; **do not change unilaterally**
(`lib/data/story_api.dart`, `StorySettings.toRequestJson()`).

**Request**
```json
{ "topic": "A lighthouse that hums", "mood": "calm", "length": "short" }
```
- `mood` — always a real mood, never `"adaptive"` (client resolves Adaptive → `calm`).
- `length` — one of `short` | `medium` | `long`.
- Local-only fields (`voice`, `backgroundSound`) are deliberately **omitted**.

**Response**
```json
{
  "id": "abc123",
  "title": "A Lighthouse That Hums",
  "story": "Once, in the soft hush of evening…",
  "audioUrl": "https://…/story.mp3",
  "durationSeconds": 605
}
```
- `audioUrl` must be **remote** (`LockCachingAudioSource` only caches URLs).
- Generation is slow (~30–60s+); client timeout is 120s.

**Errors** — `{ "error": { "code": "...", "message": "..." } }` (see `StoryApiException`).

---

## 2. `GET /stories/sparks` — NEW (Quick Start bubbles)

Powers the drifting "spark" bubbles on the Quick Start screen
(`lib/screens/quick_start_screen.dart`). Replaces the hardcoded `_seeds` list.

**Key idea:** each spark is a **full story-settings object** with a separate
display `heading`. The bubble shows only `heading`; the rest of the object
rides underneath and is carried into generation when the user taps **Begin** —
so a pre-themed spark generates with its own mood/length, not defaults.

**Returns 10, shows 3.** The screen renders 3 bubbles at a time
(`_slots`) and cycles through the fetched pool. `10` is the fetch size, not a
layout number. Fetch once per screen open; no pagination.

**Request** — none (optionally `?count=10` later).

**Response**
```json
{
  "sparks": [
    { "heading": "A lighthouse that hums",   "topic": "A lighthouse that hums",   "mood": "calm",   "length": "short" },
    { "heading": "The last train to nowhere","topic": "The last train to nowhere","mood": "dreamy", "length": "medium" }
    // … 10 total
  ]
}
```

Per-item shape:
| field | type | notes |
|---|---|---|
| `heading` | string | The only thing displayed. Kept **separate from `topic`** even if identical today, so a catchy label can diverge from the generation seed later. |
| `topic` | string | The generation seed. |
| `mood` | string | Real mood (`calm`/`dreamy`/`cozy`/…), never `"adaptive"`. |
| `length` | string | `short` \| `medium` \| `long`. |

**Decision — `voice` / `backgroundSound` are omitted.** They're local-only and
would never reach the POST anyway (`toRequestJson()` drops them). Omitting keeps
the backend surface matched to what it consumes; the client defaults them to
Adaptive. Add them **only** if product wants pre-themed ambience per spark
(e.g. a "rain" spark that pre-selects Rain) — that's a later, explicit call.

**Contract discipline is preserved for free.** A tapped spark → build a
`StorySettings(topic, mood, length)` → reuse the existing `generate(settings)`
path. Even if a spark later carries `voice`/`backgroundSound`, they never leak
into the POST because `toRequestJson()` already sends only `topic`/`mood`/`length`.

---

## 3. `GET /stories/moods` — OPTIONAL / FUTURE

Only if the Custom screen's mood chips should be server-driven instead of
hardcoded. Scope it to **`mood` only** — `voice` and `backgroundSound` are
local-only client concerns and never belong in a backend list.

```json
{ "moods": ["calm", "dreamy", "cozy", "adventurous", "mysterious"] }
```

Not required for launch; the client list works fine standalone.

---

## Client wiring notes (for whoever does the Flutter side)

- **Single swap point stays single.** Add a mock `fetchSparks()` to `StoryApi`
  mirroring `generateStory` (canned list, real shape) so offline dev works and
  the real HTTP call swaps in one place.
- **Riverpod handoff.** The "carry into the next screen" plumbing already
  exists: `generationProvider.generate(settings)` takes the whole
  `StorySettings`, and `Story.settings` persists it. The only real change on
  Begin is passing the spark's full settings instead of
  `StorySettings(topic: seed, length: short)` (`quick_start_screen.dart:90-91`).
- **CI.** A network-backed sparks provider means `test/screens_smoke_test.dart`
  must override it for the Quick Start screen (which needs no override today).
  Keep the mock as the default so the test can fake it cleanly.
