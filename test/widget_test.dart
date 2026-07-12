import 'package:flutter_test/flutter_test.dart';
import 'package:luna/models/story.dart';
import 'package:luna/models/story_length.dart';
import 'package:luna/models/story_settings.dart';

void main() {
  test('Story survives a JSON round-trip', () {
    final story = Story(
      id: 'story-123',
      title: 'The Midnight Mountain Railway',
      text: 'Full generated story text…',
      audioUrl: 'https://api.example.com/audio/story-123.mp3',
      durationSeconds: 302,
      settings: const StorySettings(
        topic: 'A quiet train through the mountains',
        mood: 'calm',
        length: StoryLength.short,
        voice: 'Warm',
      ),
      lastPositionSeconds: 42,
      listenedAt: DateTime(2026, 7, 10, 22, 30),
      completed: false,
    );

    final restored = Story.fromJson(story.toJson());

    expect(restored.id, story.id);
    expect(restored.title, story.title);
    expect(restored.durationSeconds, 302);
    expect(restored.lastPositionSeconds, 42);
    expect(restored.settings.length, StoryLength.short);
    expect(restored.settings.voice, 'Warm');
    expect(restored.listenedAt, story.listenedAt);
  });

  test('Request payload maps voice onto narratorType (contract fields only)', () {
    const settings = StorySettings(
      topic: 'A lighthouse and a whale',
      mood: 'dreamy',
      length: StoryLength.medium,
      voice: 'Soft',
    );

    final payload = settings.toRequestJson();

    expect(payload.keys, containsAll(['topic', 'mood', 'narratorType', 'length']));
    expect(payload.containsKey('voice'), isFalse);
    expect(payload['narratorType'], 'soft');
    expect(payload['length'], 'medium');
  });

  test('Request payload defaults narratorType to adaptive when voice is unset', () {
    const settings = StorySettings(topic: 'A quiet lighthouse');

    expect(settings.toRequestJson()['narratorType'], 'adaptive');
  });
}
