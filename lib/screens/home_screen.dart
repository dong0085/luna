import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import '../widgets/moon_glow.dart';

/// Level 1. Moon-lit hero with the two on-ramps and an entry to the Bookshelf.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AmbientBackground(
      seed: 1,
      starCount: 60,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Settings gear.
              Positioned(
                top: 12,
                right: 22,
                child: _CircleIconButton(
                  icon: Icons.settings_outlined,
                  onTap: () => context.push(Routes.settings),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 44, 26, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const MoonGlow(size: 58, pulse: true),
                    const SizedBox(height: 20),
                    Text('Luna',
                        style: text.displayLarge?.copyWith(
                          fontSize: 46,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 6),
                    Text('Calm stories to drift off to',
                        style: text.titleMedium?.copyWith(
                          color: AppTheme.star,
                          fontWeight: FontWeight.w600,
                        )),
                    const Spacer(),
                    _HomeCard(
                      icon: Icons.auto_awesome,
                      title: 'Quick start',
                      desc: 'Say or type a seed, pick a length, and go.',
                      onTap: () => context.push(Routes.quickStart),
                    ),
                    const SizedBox(height: 18),
                    _HomeCard(
                      icon: Icons.tune,
                      title: 'Custom story',
                      desc: 'Full control over topic, mood, voice and length.',
                      onTap: () => context.push(Routes.custom),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push(Routes.bookshelf),
                      child: Text('Open your Bookshelf  ›',
                          style: text.labelLarge?.copyWith(
                            color: AppTheme.moon.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.dusk.withValues(alpha: 0.95),
                const Color(0xFF16163A).withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 40,
                offset: const Offset(0, 14),
                spreadRadius: -18,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.6),
                    radius: 1.2,
                    colors: [Color(0x52E8B27D), Color(0x14E8B27D)],
                  ),
                  border: Border.all(color: AppTheme.ember.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, color: AppTheme.ember, size: 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: text.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 5),
                    Text(desc,
                        style: text.bodyMedium?.copyWith(
                          color: AppTheme.moon.withValues(alpha: 0.62),
                          height: 1.5,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.moon.withValues(alpha: 0.07),
          border: Border.all(color: AppTheme.moon.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, size: 22, color: AppTheme.moon.withValues(alpha: 0.78)),
      ),
    );
  }
}
