import 'package:flutter/material.dart';

/// Carries the effective "reduce motion" flag down the tree so plain (non-Riverpod)
/// animated widgets can consult it from `context`. Fed at the app root from
/// `reduceMotionProvider`; OR-ed with the platform `disableAnimations` setting.
class MotionConfig extends InheritedWidget {
  const MotionConfig({
    super.key,
    required this.reduceMotion,
    required super.child,
  });

  final bool reduceMotion;

  /// Effective reduce-motion for [context] — the in-app toggle OR the platform
  /// accessibility setting. Returns false when no [MotionConfig] is present
  /// (e.g. isolated widget tests), so animations stay on by default.
  static bool of(BuildContext context) {
    final config = context.dependOnInheritedWidgetOfExactType<MotionConfig>();
    final platform = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return (config?.reduceMotion ?? false) || platform;
  }

  @override
  bool updateShouldNotify(MotionConfig oldWidget) =>
      reduceMotion != oldWidget.reduceMotion;
}
