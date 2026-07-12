import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/story_length.dart';
import '../theme/app_theme.dart';

/// Short / Medium / Long chooser shared by Quick start and Custom.
class LengthSelector extends StatelessWidget {
  const LengthSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final StoryLength value;
  final ValueChanged<StoryLength> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final length in StoryLength.values) ...[
          Expanded(child: _card(length, length == value)),
          if (length != StoryLength.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _card(StoryLength length, bool selected) {
    return GestureDetector(
      onTap: () => onChanged(length),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? const RadialGradient(
                  center: Alignment(0, -1),
                  radius: 1.2,
                  colors: [Color(0x47B9A6FF), Color(0x14B9A6FF)],
                )
              : null,
          color: selected ? null : AppTheme.moon.withValues(alpha: 0.05),
          border: Border.all(
            color: selected
                ? AppTheme.star
                : AppTheme.moon.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.star.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(length.label,
                style: GoogleFonts.fraunces(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? AppTheme.moon
                      : AppTheme.moon.withValues(alpha: 0.82),
                )),
          ],
        ),
      ),
    );
  }
}
