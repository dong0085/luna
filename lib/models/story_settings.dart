import 'story_length.dart';

/// The settings a user picked when creating a story.
///
/// The documented backend contract is `{topic, mood, narratorType, length}`.
/// `mood` may be the literal "adaptive" — the backend resolves it. [voice] maps
/// onto the required `narratorType` (see [resolvedNarratorType]). Only
/// [backgroundSound] stays local-only and out of the POST via [toRequestJson],
/// so we never change the API contract unilaterally. Coordinate with the
/// backend dev before wiring anything else into the request.
class StorySettings {
  const StorySettings({
    required this.topic,
    this.mood = 'calm',
    this.length = StoryLength.short,
    this.voice,
    this.backgroundSound,
  });

  /// The story seed / theme. Quick-start's chosen spark maps onto this field.
  final String topic;

  /// May be the literal "Adaptive" — resolved before it reaches the backend.
  final String mood;
  final StoryLength length;

  /// Local-only. May be "Adaptive".
  final String? voice;

  /// Local-only ambience (None / Rain / Waves / Fireplace / Adaptive).
  final String? backgroundSound;

  bool get isAdaptiveMood => mood.trim().toLowerCase() == 'adaptive';

  /// What gets sent as `mood`, lowercased. "Adaptive" is passed through as
  /// `adaptive` for the backend to resolve.
  String get resolvedMood => mood.trim().toLowerCase();

  /// The backend's required `narratorType`: `adaptive` | `default` | `warm` |
  /// `soft` | `deep`. The UI's [voice] labels lowercase directly onto these.
  /// Quick-start leaves [voice] null (and any unrecognized value) falling back
  /// to `adaptive` so the backend picks the voice.
  static const _narratorTypes = {'adaptive', 'default', 'warm', 'soft', 'deep'};
  String get resolvedNarratorType {
    final v = voice?.trim().toLowerCase();
    return _narratorTypes.contains(v) ? v! : 'adaptive';
  }

  StorySettings copyWith({
    String? topic,
    String? mood,
    StoryLength? length,
    String? voice,
    String? backgroundSound,
  }) {
    return StorySettings(
      topic: topic ?? this.topic,
      mood: mood ?? this.mood,
      length: length ?? this.length,
      voice: voice ?? this.voice,
      backgroundSound: backgroundSound ?? this.backgroundSound,
    );
  }

  /// Payload for `POST /stories/generate` — contract fields only, mood and
  /// narratorType resolved.
  Map<String, dynamic> toRequestJson() => {
        'topic': topic,
        'mood': resolvedMood,
        'narratorType': resolvedNarratorType,
        'length': length.apiValue,
      };

  /// Full local serialization (includes the local-only fields).
  Map<String, dynamic> toJson() => {
        'topic': topic,
        'mood': mood,
        'length': length.apiValue,
        'voice': voice,
        'backgroundSound': backgroundSound,
      };

  factory StorySettings.fromJson(Map<String, dynamic> json) => StorySettings(
        topic: json['topic'] as String? ?? '',
        mood: json['mood'] as String? ?? 'calm',
        length: StoryLength.fromApi(json['length'] as String?),
        voice: json['voice'] as String?,
        backgroundSound: json['backgroundSound'] as String?,
      );
}
