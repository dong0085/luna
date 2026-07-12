import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/story.dart';
import '../models/story_settings.dart';

/// Talks to the story-generation backend (`../luna-api`).
///
/// [generateStory] POSTs the settings and turns the JSON response into a
/// [Story]. This is the single swap point between the app and the backend.
///
/// Contract (do not change unilaterally):
///   POST /stories/generate  { topic, mood, length }
///   -> 201 { id, title, story, audioUrl, durationSeconds }
///   errors -> { error: { code, message } }
class StoryApi {
  StoryApi({String? baseUrl}) : baseUrl = baseUrl ?? _defaultBaseUrl;

  final String baseUrl;

  /// Where the backend lives. Override at build/run time with
  /// `--dart-define=LUNA_API_URL=https://...`. The default targets a locally
  /// running `luna-api` — which macOS/iOS reach at `localhost`; an Android
  /// emulator needs `--dart-define=LUNA_API_URL=http://10.0.2.2:3000`.
  static const _defaultBaseUrl =
      String.fromEnvironment('LUNA_API_URL', defaultValue: 'http://localhost:3000');

  Future<Story> generateStory(StorySettings settings) async {
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$baseUrl/stories/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(settings.toRequestJson()),
          )
          .timeout(const Duration(seconds: 120)); // generation is slow (30–60s+)
    } catch (e) {
      // Connection refused, DNS failure, timeout — the backend never answered.
      throw StoryApiException('NETWORK_ERROR', 'Could not reach the story server. $e');
    }

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw StoryApiException.fromResponse(res.statusCode, res.body);
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw StoryApiException(
        'BAD_RESPONSE',
        'The story server returned an unexpected response.',
      );
    }
    return Story.fromGenerationJson(json, settings);
  }
}

/// Parsed backend error (`{ error: { code, message } }`).
class StoryApiException implements Exception {
  StoryApiException(this.code, this.message);

  /// Build from a non-2xx response, tolerating bodies that aren't the
  /// documented error JSON (e.g. a bare 500 HTML page or an empty body).
  factory StoryApiException.fromResponse(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        return StoryApiException(
          error['code']?.toString() ?? 'HTTP_$statusCode',
          error['message']?.toString() ?? 'Request failed ($statusCode).',
        );
      }
    } catch (_) {
      // Fall through to the generic message below.
    }
    return StoryApiException('HTTP_$statusCode', 'Request failed ($statusCode).');
  }

  final String code;
  final String message;

  @override
  String toString() => 'StoryApiException($code): $message';
}
