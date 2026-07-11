# Luna — Design Brief

A design brief for **Luna**, an adult sleep app that generates calm bedtime stories
and reads them aloud. Use this document as the source of truth when designing screens
in Claude (web). It describes the mood, visual language, palette, type, components, and
each screen so the generated designs stay consistent.

---

## 1. Product in one line

Luna writes a gentle bedtime story on request and narrates it, wrapping the listener in
a storybook world so they drift off to sleep.

**Who it is for:** adults winding down at night, often in bed, in the dark, one-handed,
eyes half closed.

**The feeling to design for:** calm, warm, safe, unhurried — like a night light and a
soft voice. Every screen should feel like it is already nighttime inside the app.

---

## 2. Design principles

1. **Night-first.** The app lives in the dark. Deep indigo backgrounds, warm low-contrast
   text, soft glows. Light is used sparingly, like moonlight.
2. **Calm over busy.** Generous spacing, few elements per screen, one clear action at a
   time. Stillness is the default; motion is slow and gentle.
3. **Storybook, not sci-fi.** A warm, literary, hand-made feel — serif display type,
   parchment-toned text, illustrated covers. It reads like a bedtime book, softly lit.
4. **One-handed and sleepy-proof.** Large tap targets, primary actions low on the screen
   within thumb reach, high legibility at a glance.
5. **Sleep-friendly light.** Warm tones over cool blue, gentle contrast, no harsh white,
   no flashing. Comfortable to look at with the lights off.

---

## 3. Visual language

- **Atmosphere:** a night sky gradient behind every screen — deep indigo at the edges,
  a slightly lighter dusk toward the top, fading darker at the bottom. Optional drifting
  stars / soft particles and a faint moon glow.
- **Surfaces:** cards and inputs sit on softly raised dusk-colored panels with large
  rounded corners (16–28px) and no hard borders. Think smooth, pillowy shapes.
- **Depth:** created with soft glows and gentle gradients rather than heavy shadows.
- **Covers:** each story gets an illustrated cover using violet-to-amber gradients with a
  simple celestial motif (moon, stars, a book). Covers vary slightly so a shelf of them
  feels hand-made.

---

## 4. Color palette

A night palette: indigo base, warm parchment text, soft violet and amber accents.

| Role                | Name   | Hex        | Use                                             |
| ------------------- | ------ | ---------- | ----------------------------------------------- |
| Background (deep)   | Night  | `#0E1030`  | Main scaffold background                        |
| Background (top)    | Dusk-1 | `#161A45`  | Top of the ambient gradient                     |
| Background (bottom) | Ink    | `#090A22`  | Bottom of the ambient gradient                  |
| Surface / raised    | Dusk   | `#1B1E48`  | Cards, inputs, chips, panels                    |
| Primary text        | Moon   | `#F3E9D2`  | Titles and body — warm parchment                |
| Accent (primary)    | Star   | `#B9A6FF`  | Buttons, highlights, active states, progress    |
| Accent (warm)       | Ember  | `#E8B27D`  | Secondary highlights, "resume", cover gradients |

**Usage guidance**

- Text sits at Moon on Night for a warm, gentle contrast that stays readable at night.
- Star (violet) marks the primary action and the "now" — the play button, the filled
  progress, the selected length.
- Ember (amber) is the warm touch — resume hints, cover gradients, small accents. Use it
  in small doses so it stays special.
- Cover gradients run Star → Ember (top-left to bottom-right).

---

## 5. Typography

Two families: a storybook serif for voice, a soft sans for reading comfort.

- **Display / headline / title — Fraunces (serif).** Warm, literary, a little whimsical.
  Used for the app name, screen titles, story titles, and stage messages.
- **Body / labels / buttons — Nunito Sans.** Rounded, friendly, highly legible for
  paragraphs of story text and UI labels.

**Scale (suggested)**

| Style          | Family      | Size / weight        | Used for                     |
| -------------- | ----------- | -------------------- | ---------------------------- |
| Display        | Fraunces    | 40–48 / semibold     | App name, hero moments       |
| Headline       | Fraunces    | 24–28 / medium       | Screen + story titles        |
| Title          | Fraunces    | 18–20 / medium       | Section labels, list titles  |
| Body           | Nunito Sans | 16 / regular         | Story text, descriptions     |
| Label / button | Nunito Sans | 14–16 / bold         | Buttons, chips, captions     |

Keep line length comfortable and line spacing relaxed (1.4–1.6) for restful reading.

---

## 6. Iconography & imagery

- **Icons:** thin, rounded, outline style. Calm and simple. Celestial where it fits
  (moon, stars, open book).
- **Imagery:** illustrated, soft, painterly. Gradients over photographs.
- **Motifs:** open book, crescent moon, stars, gentle hills, a lighthouse, a quiet train.

---

## 7. Motion & atmosphere

Slow, soft, and continuous — motion should soothe, never grab attention.

- **Transitions:** gentle fades and slow slides (300–500ms, ease-in-out).
- **Ambient loops:** drifting stars / floating particles behind every screen, very slow.
- **Loading:** a book opening, or pages turning, instead of a spinner.
- **State changes:** cross-fade text and controls rather than snapping.
- **Player:** a soft breathing glow around the play button while audio plays.

---

## 8. Component library

Design these once and reuse them across screens.

- **Ambient background** — the night gradient with optional drifting particles. Sits
  behind every screen.
- **Hero choice card** — large tappable card: leading icon (Ember), title (Fraunces),
  one-line description (Nunito Sans). Rounded 20px, dusk surface, soft glow on press.
- **Primary button (filled)** — Star background, Night text, rounded 18px, generous
  padding. The single clear action on a screen.
- **Text button** — Moon text, no fill. For lower-priority actions.
- **Text input** — dusk fill, rounded 16px, no hard border, soft placeholder. The seed
  field carries a microphone icon on the right for voice input.
- **Length selector** — three side-by-side pills (Short / Medium / Long) with a label and
  a duration (~5 / ~10 / ~15 min). Selected pill glows Star with a violet border.
- **Choice chip** — small rounded chips for mood and voice options; selected chip fills Star.
- **Story cover** — illustrated tile, Star→Ember gradient, celestial motif, title, and a
  small caption (duration, or "Resume" in Ember when partly played).
- **Progress bar** — thin track, Star fill, small Moon thumb, elapsed / total time below.
- **Player controls** — restart, 15-second rewind, a large circular Star play/pause, laid
  out for thumb reach.

---

## 9. Screens

Seven screens. Two navigation levels: **Home** (level 1) and **Bookshelf** (level 2).
The two on-ramps (Quick start, Custom) flow into Generate → Generating → Player. The
Bookshelf is a separate replay path straight to the Player.

### 9.1 Home (level 1)

The calm front door.

- App name "Luna" in Fraunces, a one-line tagline in Star ("Calm stories to drift off to").
- Two large **hero choice cards**, stacked:
  - **Quick start** — "Say or type a seed, pick a length, and go."
  - **Custom story** — "Full control over topic, mood, voice and length."
- A quiet text button near the bottom: **Open your Bookshelf**.
- Ambient night background with slow drifting stars.

Layout: name at top, hero cards centered, bookshelf link low within thumb reach.

### 9.2 Quick start

The fast path to a story.

- Headline: "What should tonight's story be about?"
- A large **seed input** (say or type) with a microphone icon for voice input.
- A **length selector** (Short / Medium / Long).
- A primary **Generate story** button pinned low.

Mood and voice use gentle defaults here — keep this screen light and quick.

### 9.3 Custom story

Full control, still calm.

- **Topic / theme** text input.
- **Mood / style** as a row of choice chips (calm, dreamy, cozy, adventurous, mysterious).
- **Narrator voice** as a dropdown or chips (Default, Warm, Soft, Deep).
- **Length selector**.
- Primary **Generate story** button.

Scrolls vertically; group each setting with a Fraunces section label and breathing room.

### 9.4 Generating

An immersive wait, not a spinner.

- A hero animation — a **book opening** or turning pages — centered.
- Staged messages that cross-fade on a slow timer:
  1. "Writing your story…"
  2. "Creating narration…"
  3. "Preparing playback…"
- A thin Star progress line beneath.
- Fully immersive; the ambient background carries through.

(These stages are paced feeling, so keep the animation engaging for a long wait.)

### 9.5 Player

The heart of the app — where the story is read aloud.

- Large illustrated **cover art** (Star→Ember gradient, celestial motif), centered.
- **Story title** (Fraunces) and a small caption below (length · mood) in Star.
- **Progress bar** with elapsed / total time.
- **Controls** in a thumb-friendly row: restart, 15-second rewind, and a large circular
  Star **play/pause** with a soft breathing glow while playing.
- A quiet **Generate another** text button below.
- A downward chevron at the top to ease back out.

Designed for the dark: large controls, warm glow, minimal text. Audio continues in the
background and on the lock screen (design lock-screen metadata: title, cover, duration).

### 9.6 Bookshelf (level 2)

A replay library of stories the listener has heard.

- Header: "Your Bookshelf".
- A **two-column shelf** of story covers with slightly varied heights, so it feels
  hand-made. Each cover shows the title and a small caption — duration, or "Resume" in
  Ember when partly played.
- Tapping a cover opens Story detail (or resumes straight into the Player).

**Empty state (fresh install):** a calm centerpiece — a crescent-moon icon, a warm line
"Your stories appear here," and a soft subtext: "After you listen to a story, it settles
onto your shelf so you can drift back to it any night."

### 9.7 Story detail

A quiet page for one saved story.

- Large **cover art**, centered.
- **Title** (Fraunces) with small **tags** for length, mood, and voice.
- A short blurb or the opening of the story text.
- Primary action: **Resume** (or **Play** if unplayed).
- Secondary action when partly played: **Start over**.
- A quiet remove-from-shelf action in the top bar.

---

## 10. Accessibility & comfort

- **Warm, gentle contrast:** Moon text on Night meets readability while staying soft on
  sleepy eyes. Keep body text at 16px or larger.
- **Large tap targets:** at least 48px, primary actions within thumb reach.
- **Sleep-friendly light:** warm tones, steady brightness, slow motion, no harsh white,
  no flashing.
- **One-handed:** key actions low and centered.
- **Glanceable:** clear hierarchy so a half-asleep user finds play, pause, and resume at once.

---

## 11. What to generate first

Priority order for mockups:

1. **Home** — sets the mood and the whole visual language.
2. **Player** — the core experience; nail the calm, the cover, and the controls.
3. **Generating** — the immersive book-opening wait.
4. **Bookshelf** — the shelf of covers plus the calm empty state.
5. **Quick start** and **Custom story** — the two on-ramps.
6. **Story detail** — the quiet replay page.

Deliver each as a mobile screen (portrait), dark, with the ambient night background, using
the palette and type above.
