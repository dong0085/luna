import 'story_settings.dart';

/// A generated story plus the local playback/library state layered on top of it.
///
/// The first five fields come straight from the backend response. The rest are
/// local-only: they power the Bookshelf, resume-playback and cached replay.
class Story {
  const Story({
    required this.id,
    required this.title,
    required this.text,
    required this.audioUrl,
    required this.durationSeconds,
    required this.settings,
    this.localAudioPath,
    this.lastPositionSeconds = 0,
    this.listenedAt,
    this.completed = false,
  });

  // --- From the backend ---
  final String id;
  final String title;
  final String text;
  final String audioUrl;
  final int durationSeconds;

  // --- Local only ---
  final StorySettings settings;

  /// Path to cached audio once available (reserved for future use;
  /// `LockCachingAudioSource` currently manages its own cache by URL).
  final String? localAudioPath;

  /// Resume point. Continuously updated during playback.
  final int lastPositionSeconds;

  /// When the user first started listening (the save-on-play trigger).
  final DateTime? listenedAt;

  /// Whether playback reached the end at least once.
  final bool completed;

  Duration get duration => Duration(seconds: durationSeconds);
  Duration get lastPosition => Duration(seconds: lastPositionSeconds);

  Story copyWith({
    String? localAudioPath,
    int? lastPositionSeconds,
    DateTime? listenedAt,
    bool? completed,
  }) {
    return Story(
      id: id,
      title: title,
      text: text,
      audioUrl: audioUrl,
      durationSeconds: durationSeconds,
      settings: settings,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      lastPositionSeconds: lastPositionSeconds ?? this.lastPositionSeconds,
      listenedAt: listenedAt ?? this.listenedAt,
      completed: completed ?? this.completed,
    );
  }

  /// Build from a fresh `POST /stories/generate` response and the settings used.
  factory Story.fromGenerationJson(
    Map<String, dynamic> json,
    StorySettings settings,
  ) {
    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['story'] as String,
      audioUrl: json['audioUrl'] as String,
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      settings: settings,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'story': text,
        'audioUrl': audioUrl,
        'durationSeconds': durationSeconds,
        'settings': settings.toJson(),
        'localAudioPath': localAudioPath,
        'lastPositionSeconds': lastPositionSeconds,
        'listenedAt': listenedAt?.toIso8601String(),
        'completed': completed,
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] as String,
        title: json['title'] as String,
        text: json['story'] as String,
        audioUrl: json['audioUrl'] as String,
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        settings: StorySettings.fromJson(
          Map<String, dynamic>.from(json['settings'] as Map),
        ),
        localAudioPath: json['localAudioPath'] as String?,
        lastPositionSeconds: (json['lastPositionSeconds'] as num?)?.toInt() ?? 0,
        listenedAt: json['listenedAt'] == null
            ? null
            : DateTime.parse(json['listenedAt'] as String),
        completed: json['completed'] as bool? ?? false,
      );
}
