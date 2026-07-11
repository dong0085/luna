import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// The primary call-to-action: a full-width violet gradient pill with dark text
/// and a soft glow. Matches every "Generate story" / "Save to Bookshelf" button
/// in the design.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.padding = const EdgeInsets.all(18),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.ctaGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.star.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: AppTheme.night),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.night,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
