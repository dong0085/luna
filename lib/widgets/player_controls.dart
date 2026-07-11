import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// The large play/pause button that "breathes": it scales 1→1.03 while an
/// expanding ring of light radiates out and a soft outer glow swells — a slow
/// heartbeat (§2, 4.2s). Stilled under reduce-motion.
class PlayButton extends StatefulWidget {
  const PlayButton({
    super.key,
    required this.playing,
    required this.onTap,
    this.loading = false,
    this.size = 92,
  });

  final bool playing;
  final bool loading;
  final VoidCallback onTap;
  final double size;

  @override
  State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton>
    with SingleTickerProviderStateMixin {
  // 2100ms each way → a 4.2s full breathe cycle (peak at the midpoint).
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2100),
  );
  late final Animation<double> _breathe =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MotionConfig.of(context);
    if (reduce) {
      _controller.stop();
      return RepaintBoundary(
        child: _face(
            scale: 1, ringSpread: 0, ringAlpha: 0, glowBlur: 44, glowSpread: 6, glowAlpha: 0.35),
      );
    }
    if (!_controller.isAnimating) _controller.repeat(reverse: true);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (context, _) {
          final v = _breathe.value;
          return _face(
            scale: lerpDouble(1, 1.03, v)!,
            ringSpread: lerpDouble(0, 22, v)!,
            ringAlpha: lerpDouble(0.30, 0, v)!,
            glowBlur: lerpDouble(44, 64, v)!,
            glowSpread: lerpDouble(6, 14, v)!,
            glowAlpha: lerpDouble(0.35, 0.5, v)!,
          );
        },
      ),
    );
  }

  Widget _face({
    required double scale,
    required double ringSpread,
    required double ringAlpha,
    required double glowBlur,
    required double glowSpread,
    required double glowAlpha,
  }) {
    return Transform.scale(
      scale: scale,
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.5), // 35% 25%
              radius: 1.2,
              colors: [AppTheme.starLight, AppTheme.star],
              stops: [0.0, 0.7],
            ),
            boxShadow: [
              // Expanding ring (spread grows, fades to transparent).
              BoxShadow(
                color: AppTheme.star.withValues(alpha: ringAlpha),
                blurRadius: 0,
                spreadRadius: ringSpread,
              ),
              // Breathing outer glow.
              BoxShadow(
                color: AppTheme.star.withValues(alpha: glowAlpha),
                blurRadius: glowBlur,
                spreadRadius: glowSpread,
              ),
            ],
          ),
          child: Center(child: _glyph()),
        ),
      ),
    );
  }

  Widget _glyph() {
    if (widget.loading) {
      return const SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppTheme.night),
      );
    }
    if (widget.playing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [_bar(), const SizedBox(width: 7), _bar()],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: CustomPaint(size: const Size(30, 32), painter: _TrianglePainter()),
    );
  }

  Widget _bar() => Container(
        width: 8,
        height: 30,
        decoration: BoxDecoration(
          color: AppTheme.night,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.night;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// A small circular secondary control (restart / rewind), with an optional
/// tiny sub-label like "15".
class ControlButton extends StatelessWidget {
  const ControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.subLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? subLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.moon.withValues(alpha: 0.08),
          border: Border.all(color: AppTheme.moon.withValues(alpha: 0.12)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: AppTheme.moon),
            if (subLabel != null)
              Positioned(
                bottom: 14,
                child: Text(
                  subLabel!,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.moon,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The progress track: a glowing thumb over a violet fill, with tabular
/// position / duration labels. Tap or drag to seek when [onSeek] is provided.
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.value,
    this.leftLabel,
    this.rightLabel,
    this.onSeek,
  });

  final double value; // 0..1
  final String? leftLabel;
  final String? rightLabel;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            void seek(Offset local) =>
                onSeek?.call((local.dx / width).clamp(0.0, 1.0));
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: onSeek == null ? null : (d) => seek(d.localPosition),
              onHorizontalDragUpdate:
                  onSeek == null ? null : (d) => seek(d.localPosition),
              child: SizedBox(
                height: 18,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.moon.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [AppTheme.star, AppTheme.starLight],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment(v * 2 - 1, 0),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.moon,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.star.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (leftLabel != null || rightLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(leftLabel ?? '', style: _timeStyle),
                Text(rightLabel ?? '', style: _timeStyle),
              ],
            ),
          ),
      ],
    );
  }

  static final _timeStyle = TextStyle(
    color: AppTheme.moon.withValues(alpha: 0.6),
    fontSize: 13,
    fontWeight: FontWeight.w700,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
