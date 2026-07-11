import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/story.dart';

/// Local library of listened stories, backed by a single Hive box.
///
/// Each [Story] is stored as a JSON string keyed by its `id` — no TypeAdapters
/// / codegen needed. This powers the Bookshelf, save-on-play, resume position,
/// and cached replay.
class StoryRepository {
  static const _boxName = 'stories';

  late final Box<String> _box;

  /// Open the box. Call once, after `Hive.initFlutter()`, before `runApp`.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// All saved stories, most recently listened first.
  List<Story> all() {
    final stories = _box.values
        .map((s) => Story.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    stories.sort((a, b) {
      final at = a.listenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.listenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return stories;
  }

  Story? get(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return Story.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  bool exists(String id) => _box.containsKey(id);

  Future<void> save(Story story) =>
      _box.put(story.id, jsonEncode(story.toJson()));

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();
}
