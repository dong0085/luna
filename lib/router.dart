import 'package:go_router/go_router.dart';

import 'screens/bookshelf_screen.dart';
import 'screens/custom_story_screen.dart';
import 'screens/finished_screen.dart';
import 'screens/generating_screen.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'screens/quick_start_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/story_detail_screen.dart';

/// App routes. Level 1 is Home; the two on-ramps converge on
/// Generate → Generating → Player. The Bookshelf is a separate replay path.
abstract final class Routes {
  static const home = '/';
  static const quickStart = '/quick-start';
  static const custom = '/custom';
  static const generating = '/generating';
  static const player = '/player';
  static const bookshelf = '/bookshelf';
  static const storyDetail = '/story-detail';
  static const settings = '/settings';
  static const finished = '/finished';
}

final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: Routes.quickStart,
      builder: (context, state) => const QuickStartScreen(),
    ),
    GoRoute(
      path: Routes.custom,
      builder: (context, state) => const CustomStoryScreen(),
    ),
    GoRoute(
      path: Routes.generating,
      builder: (context, state) => const GeneratingScreen(),
    ),
    GoRoute(
      path: Routes.player,
      builder: (context, state) => const PlayerScreen(),
    ),
    GoRoute(
      path: Routes.bookshelf,
      builder: (context, state) => const BookshelfScreen(),
    ),
    GoRoute(
      path: Routes.storyDetail,
      builder: (context, state) => const StoryDetailScreen(),
    ),
    GoRoute(
      path: Routes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: Routes.finished,
      builder: (context, state) => const FinishedScreen(),
    ),
  ],
);
