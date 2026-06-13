import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

/// Friendly coach greeting shown once when the app opens: what you did,
/// missed, or need to do next — plus a 1-tap energy check-in (which replaces
/// the old standalone check-in card). Dismissible.
bool _shownThisSession = false;

Future<void> maybeShowCoachOnOpen(
  BuildContext context,
  HabitProvider provider,
) async {
  if (_shownThisSession) return;
  if (!provider.hasSelectedPath) return; // not past onboarding yet
  _shownThisSession = true;

  // Let the first frame settle so the sheet animates over a built screen.
  await Future<void>.delayed(const Duration(milliseconds: 400));
  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _CoachSheet(provider: provider),
  );
}

class _CoachSheet extends StatelessWidget {
  final HabitProvider provider;
  const _CoachSheet({required this.provider});

  String get _greeting {
    final hour = DateTime.now().hour;
    final name = provider.userName;
    final part = hour < 12
        ? 'Morning'
        : hour < 18
            ? 'Afternoon'
            : 'Evening';
    return name.isEmpty ? '$part!' : '$part, $name!';
  }

  String get _message {
    final remaining = provider.habits.length - provider.completedTodayCount;
    final missed = provider.missedPlannedSessionsThisWeek;
    if (provider.habits.isEmpty) {
      return "Let's design your first loop — small and doable. I'll handle the rest.";
    }
    if (remaining <= 0 && missed == 0) {
      return "You've closed every loop and you're on track for the week. Genuinely strong. Keep the momentum gentle today.";
    }
    if (remaining > 0 && missed > 0) {
      return "You have $remaining loop${remaining == 1 ? '' : 's'} open today and $missed session${missed == 1 ? '' : 's'} left this week. Pick one — momentum beats perfection.";
    }
    if (remaining > 0) {
      return "$remaining loop${remaining == 1 ? '' : 's'} left to close today. Want to knock the easiest one out first?";
    }
    return "Loops done — nice. One short session would put the week firmly in the green.";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CoachAvatar(size: 52),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting, style: textTheme.titleLarge),
                    Text('Your ActivHealth coach',
                        style: textTheme.labelMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Ah.s16),
          Text(_message, style: textTheme.bodyLarge?.copyWith(height: 1.5)),
          const SizedBox(height: Ah.s24),
          Text('How is your energy today?', style: textTheme.labelMedium),
          const SizedBox(height: Ah.s8),
          Row(
            children: ['Low', 'Steady', 'High']
                .map((e) => Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(right: e == 'High' ? 0 : Ah.s8),
                        child: _EnergyButton(
                          label: e,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            provider.saveCheckIn(
                              energy: e,
                              soreness:
                                  provider.todayCheckIn['soreness'] ?? 'Low',
                              time: provider.todayCheckIn['time'] ?? '30 min',
                              mood: provider.todayCheckIn['mood'] ?? 'Focused',
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: Ah.s12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe later'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _EnergyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Low' => Ah.warning,
      'High' => Ah.mint,
      _ => Ah.info,
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Ah.rMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Ah.s12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(Ah.rMd),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: color)),
          ),
        ),
      ),
    );
  }
}

/// The coach's visual identity — a gradient orb wearing an "AH" cap.
/// (Placeholder for an illustrated mascot asset; the silhouette reads as a
/// capped coach and themes cleanly.)
class CoachAvatar extends StatelessWidget {
  final double size;
  const CoachAvatar({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: Ah.brandGradient,
              shape: BoxShape.circle,
              boxShadow: Ah.accentGlow(opacity: 0.25),
            ),
            child: Icon(Icons.face_retouching_natural,
                color: Ah.onAccent, size: size * 0.5),
          ),
          // Cap brim
          Positioned(
            top: size * 0.12,
            child: Container(
              width: size * 0.62,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Ah.onAccent,
                borderRadius: BorderRadius.circular(size),
              ),
              alignment: Alignment.center,
              child: Text(
                'AH',
                style: TextStyle(
                  color: Ah.accent,
                  fontSize: size * 0.12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
