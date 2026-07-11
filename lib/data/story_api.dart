import '../models/story.dart';
import '../models/story_length.dart';
import '../models/story_settings.dart';

/// Talks to the story-generation backend.
///
/// Right now [generateStory] is a MOCK — it fakes the ~2s round-trip and returns
/// canned content so the whole UI + playback flow can be built before the
/// backend exists. When the real endpoint is ready, this is the ONLY function
/// that changes: swap the mock block for the commented `http` call below.
///
/// Contract (do not change unilaterally):
///   POST /stories/generate  { topic, mood, length }
///   -> { id, title, story, audioUrl, durationSeconds }
class StoryApi {
  StoryApi({this.baseUrl = 'https://api.example.com'});

  final String baseUrl;

  Future<Story> generateStory(StorySettings settings) async {
    // --- MOCK ---------------------------------------------------------------
    await Future.delayed(const Duration(seconds: 2));
    final json = <String, dynamic>{
      'id': 'mock-${settings.length.apiValue}-'
          '${DateTime.now().millisecondsSinceEpoch}',
      'title': _mockTitle(settings),
      'story': _mockText(settings),
      // A reliable public sample so the Player works end-to-end offline of the
      // backend. Keep it REMOTE — LockCachingAudioSource only caches URLs.
      'audioUrl':
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'durationSeconds': _mockDuration(settings),
    };
    return Story.fromGenerationJson(json, settings);

    // --- REAL (swap in when backend is ready) -------------------------------
    // final res = await http
    //     .post(
    //       Uri.parse('$baseUrl/stories/generate'),
    //       headers: {'Content-Type': 'application/json'},
    //       body: jsonEncode(settings.toRequestJson()),
    //     )
    //     .timeout(const Duration(seconds: 120)); // generation is slow (30–60s+)
    // if (res.statusCode != 200) {
    //   throw StoryApiException.fromResponse(res.body);
    // }
    // return Story.fromGenerationJson(
    //   jsonDecode(res.body) as Map<String, dynamic>,
    //   settings,
    // );
  }

  String _mockTitle(StorySettings s) {
    final topic = s.topic.trim();
    if (topic.isEmpty) return 'A Quiet Night';
    final words = topic.split(RegExp(r'\s+')).take(4).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1);
    });
    return words.join(' ');
  }

  int _mockDuration(StorySettings s) => switch (s.length) {
        StoryLength.short => 302,
        StoryLength.medium => 605,
        StoryLength.long => 900,
      };

  String _mockText(StorySettings s) {
    final seed = s.topic.trim().isEmpty ? 'the quiet night' : s.topic.trim();
    return 'Once, in the soft hush of evening, there was $seed. '
        'The world slowed to the rhythm of a single, gentle breath... '
        '(mock ${s.length.label.toLowerCase()} story — real text arrives from '
        'the backend.)';
  }
}

/// Parsed backend error (`{ error: { code, message } }`).
class StoryApiException implements Exception {
  StoryApiException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'StoryApiException($code): $message';
}
