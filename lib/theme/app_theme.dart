import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Storybook-at-night palette + typography, taken directly from the Luna design
/// mockups (Fraunces + Nunito Sans, a violet/ember/parchment night palette).
class AppTheme {
  AppTheme._();

  // Night palette.
  static const Color night = Color(0xFF0E1030); // primary background
  static const Color nightDeep = Color(0xFF090A22); // gradient bottom
  static const Color nightTop = Color(0xFF161A45); // gradient top
  static const Color dusk = Color(0xFF1B1E48); // raised surfaces (rgba 27,30,72)
  static const Color duskCard = Color(0xFF2D2C60); // bubble / raised card

  static const Color moon = Color(0xFFF3E9D2); // warm parchment text

  static const Color star = Color(0xFFB9A6FF); // violet accent
  static const Color starLight = Color(0xFFD6C8FF); // button highlight
  static const Color violetDeep = Color(0xFF8B79E8); // cover gradient start

  static const Color ember = Color(0xFFE8B27D); // warm gold accent
  static const Color emberLight = Color(0xFFF0C79A);

  // Common translucent parchment tints.
  static Color moonFaint([double o = 0.6]) => moon.withValues(alpha: o);

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: night,
      primary: star,
      secondary: ember,
      onSurface: moon,
      onPrimary: night,
    );

    final base = ThemeData.from(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: night,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: moon,
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 5,
        activeTrackColor: star,
        inactiveTrackColor: moon.withValues(alpha: 0.16),
        thumbColor: moon,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
      ),
    );
  }

  /// Serif (Fraunces) for display/headline/title — the storybook voice.
  /// Soft sans (Nunito Sans) for body/label — comfortable reading at night.
  static TextTheme _textTheme(TextTheme base) {
    final serif = GoogleFonts.frauncesTextTheme(base);
    final sans = GoogleFonts.nunitoSansTextTheme(base);
    return base.copyWith(
      displayLarge: serif.displayLarge?.copyWith(color: moon),
      displayMedium: serif.displayMedium?.copyWith(color: moon),
      displaySmall: serif.displaySmall?.copyWith(color: moon),
      headlineLarge: serif.headlineLarge?.copyWith(color: moon),
      headlineMedium: serif.headlineMedium?.copyWith(color: moon),
      headlineSmall: serif.headlineSmall?.copyWith(color: moon),
      titleLarge: serif.titleLarge?.copyWith(color: moon),
      titleMedium: serif.titleMedium?.copyWith(color: moon),
      titleSmall: serif.titleSmall?.copyWith(color: moon),
      bodyLarge: sans.bodyLarge?.copyWith(color: moon),
      bodyMedium: sans.bodyMedium?.copyWith(color: moonFaint(0.7)),
      bodySmall: sans.bodySmall?.copyWith(color: moonFaint(0.6)),
      labelLarge: sans.labelLarge?.copyWith(color: moon),
      labelMedium: sans.labelMedium?.copyWith(color: moon),
      labelSmall: sans.labelSmall?.copyWith(color: moon),
    );
  }

  // --- Reusable gradients ---------------------------------------------------

  /// Screen background — the night-sky gradient behind every screen.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [nightTop, night, nightDeep],
    stops: [0.0, 0.48, 1.0],
  );

  /// Primary CTA fill: radial(120% 160% at 50% 0%, #D6C8FF, #B9A6FF 70%).
  static const RadialGradient ctaGradient = RadialGradient(
    center: Alignment(0, -1),
    radius: 1.4,
    colors: [starLight, star],
    stops: [0.0, 0.7],
  );

  /// Story cover gradient: linear(150deg, #8B79E8, #B9A6FF 32%, #E8B27D).
  static const LinearGradient coverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violetDeep, star, ember],
    stops: [0.0, 0.32, 1.0],
  );
}
