import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';

/// Local preferences. The app is authless, so the design's profile card and
/// "Sign out" are dropped — only settings that map to real local state remain.
///
/// NOTE: toggles/values are held in-session for now; persisting them to Hive is
/// a follow-up (they don't yet feed generation defaults).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoplay = true;
  bool _nightDimming = true;
  bool _reduceMotion = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AmbientBackground(
      seed: 6,
      starCount: 40,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      color: AppTheme.moon,
                      onPressed: () => context.pop(),
                    ),
                    Text('Settings',
                        style: text.headlineSmall?.copyWith(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    children: [
                      _profileCard(),
                      _groupLabel('Story defaults'),
                      _group([
                        _valueRow('Default length', 'Medium', sub: '~10 min'),
                        _valueRow('Narrator voice', 'Warm'),
                        _valueRow('Default mood', 'Cozy'),
                      ]),
                      _groupLabel('Bedtime'),
                      _group([
                        _valueRow('Sleep timer', '30 min',
                            sub: 'Fade out and pause'),
                        _toggleRow(
                          'Autoplay next story',
                          _autoplay,
                          (v) => setState(() => _autoplay = v),
                        ),
                      ]),
                      _groupLabel('Comfort'),
                      _group([
                        _toggleRow(
                          'Night dimming',
                          _nightDimming,
                          (v) => setState(() => _nightDimming = v),
                          sub: 'Dim the screen while playing',
                        ),
                        _toggleRow(
                          'Reduce motion',
                          _reduceMotion,
                          (v) => setState(() => _reduceMotion = v),
                        ),
                      ]),
                      const SizedBox(height: 26),
                      _signOutButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Visual only — the app is authless, so these don't do anything, but the
  // design calls for them.
  Widget _profileCard() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.dusk.withValues(alpha: 0.9),
              const Color(0xFF14163A).withValues(alpha: 0.85),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.4),
                  radius: 1.05,
                  colors: [Color(0xFFF7EFDA), AppTheme.ember, AppTheme.violetDeep],
                  stops: [0.0, 0.55, 1.05],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.ember.withValues(alpha: 0.3),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mara Ellison',
                      style: GoogleFonts.fraunces(
                        color: AppTheme.moon,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      )),
                  const SizedBox(height: 2),
                  Text('mara@ellison.co',
                      style: TextStyle(
                        color: AppTheme.moon.withValues(alpha: 0.5),
                        fontSize: 13,
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                size: 20, color: AppTheme.moon.withValues(alpha: 0.4)),
          ],
        ),
      );

  Widget _signOutButton() => SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppTheme.moon.withValues(alpha: 0.06),
            border: Border.all(color: AppTheme.ember.withValues(alpha: 0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.all(15),
                child: Center(
                  child: Text('Sign out',
                      style: TextStyle(
                        color: AppTheme.ember,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _groupLabel(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 26, 6, 12),
        child: Text(t.toUpperCase(),
            style: GoogleFonts.fraunces(
              color: AppTheme.moon.withValues(alpha: 0.55),
              fontSize: 13,
              letterSpacing: 1.8,
            )),
      );

  Widget _group(List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          color: AppTheme.moon.withValues(alpha: 0.07),
        ));
      }
      children.add(rows[i]);
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.dusk.withValues(alpha: 0.7),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(children: children),
    );
  }

  Widget _valueRow(String label, String value, {String? sub}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Expanded(child: _labelBlock(label, sub)),
            Text(value,
                style: const TextStyle(
                  color: AppTheme.star,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 20, color: AppTheme.moon.withValues(alpha: 0.4)),
          ],
        ),
      );

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged,
          {String? sub}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Expanded(child: _labelBlock(label, sub)),
            _Toggle(value: value, onChanged: onChanged),
          ],
        ),
      );

  Widget _labelBlock(String label, String? sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                color: AppTheme.moon,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              )),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub,
                style: TextStyle(
                  color: AppTheme.moon.withValues(alpha: 0.5),
                  fontSize: 12.5,
                )),
          ],
        ],
      );
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: value
              ? const LinearGradient(colors: [AppTheme.star, AppTheme.starLight])
              : null,
          color: value ? null : AppTheme.moon.withValues(alpha: 0.14),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppTheme.star.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? AppTheme.night : AppTheme.moon,
          ),
        ),
      ),
    );
  }
}
