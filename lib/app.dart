import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class LunaApp extends StatelessWidget {
  const LunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Luna',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
