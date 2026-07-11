import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'data/story_repository.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Local persistence (Bookshelf, resume, cached-audio paths).
  await Hive.initFlutter();
  final repository = StoryRepository();
  await repository.init();

  // Background audio + lock-screen controls. Must be awaited before runApp,
  // and there is exactly one AudioPlayer app-wide (see audioPlayerProvider).
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.luna.audio',
    androidNotificationChannelName: 'Luna playback',
    androidNotificationOngoing: true,
  );

  runApp(
    ProviderScope(
      overrides: [storyRepositoryProvider.overrideWithValue(repository)],
      child: const LunaApp(),
    ),
  );
}
