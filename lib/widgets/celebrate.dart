import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Emotional feedback for the moments that matter: completing a loop,
/// closing the day, and hitting streak milestones.

const Set<int> kStreakMilestones = {3, 7, 14, 30, 60, 100};

/// Light celebration when a single loop is protected.
/// Surfaces the user's own celebration phrase (stored on the habit).
void celebrateLoop(BuildContext context, {String phrase = ''}) {
  HapticFeedback.mediumImpact();
  final message = phrase.trim().isEmpty ? 'That counts.' : phrase.trim();
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1800),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Ah.mint, size: 20),
            const SizedBox(width: Ah.s8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Full-screen moment for streak milestones (3/7/14/30/60/100 days).
Future<void> celebrateMilestone(
  BuildContext context, {
  required int streak,
  required String habitName,
}) {
  HapticFeedback.heavyImpact();
  final reduceMotion = MediaQuery.of(context).disableAnimations;
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Milestone',
    barrierColor: Ah.bg.withValues(alpha: 0.85),
    transitionDuration:
        reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
    pageBuilder: (context, _, __) => Center(
      child: Padding(
        padding: const EdgeInsets.all(Ah.s32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(Ah.s32),
            decoration: BoxDecoration(
              color: Ah.surface2,
              borderRadius: BorderRadius.circular(Ah.rXl),
              border: Border.all(color: Ah.hairline),
              boxShadow: Ah.accentGlow(opacity: 0.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    gradient: Ah.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_fire_department,
                      color: Ah.onAccent, size: 38),
                ),
                const SizedBox(height: Ah.s16),
                Text(
                  '$streak-day streak',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: Ah.s8),
                Text(
                  habitName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Ah.textSecondary,
                      ),
                ),
                const SizedBox(height: Ah.s24),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Keep it going'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
