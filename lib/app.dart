import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'widgets/motion.dart';

class LunaApp extends StatelessWidget {
  const LunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Luna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      // Provide the reduce-motion flag above every screen so ambient animations
      // can consult it from context.
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) => MotionConfig(
            reduceMotion: ref.watch(reduceMotionProvider),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
