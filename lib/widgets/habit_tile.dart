import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import 'celebrate.dart';
import 'habit_style.dart';

/// One-tap loop tile. Completion is celebrated, never struck through:
/// the tile tints toward success and compresses slightly instead.
class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const HabitTile({super.key, required this.habit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final id = habit.id;
    if (id == null) return const SizedBox.shrink();

    final streak = provider.currentStreak(id);
    final color = colorFor(habit.colorName);
    final complete = _isComplete(provider, id);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedContainer(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: Ah.s4),
      decoration: BoxDecoration(
        color: complete
            ? Color.alphaBlend(Ah.mint.withValues(alpha: 0.08), Ah.surface1)
            : Ah.surface1,
        borderRadius: BorderRadius.circular(Ah.rLg),
        border: Border.all(
          color: complete ? Ah.mint.withValues(alpha: 0.25) : Ah.hairline,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Ah.rLg),
          child: Padding(
            padding: const EdgeInsets.all(Ah.s12),
            child: Row(
              children: [
                _buildAction(context, provider, id, color),
                const SizedBox(width: Ah.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Ah.s4),
                      _buildSubtitle(context, provider, id, streak),
                      if (habit.anchor.isNotEmpty && !complete) ...[
                        const SizedBox(height: 3),
                        Text(
                          'After ${habit.anchor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(iconFor(habit.iconName), color: color, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isComplete(HabitProvider provider, int id) {
    if (habit.isQuitHabit) return !provider.isCompletedToday(id);
    if (habit.isAmountTracking) {
      return provider.todayAmount(id) >= habit.targetAmount;
    }
    return provider.isCompletedToday(id);
  }

  /// Celebrate after a state change that protected the loop —
  /// the user's own celebration phrase, then milestone moments.
  void _afterProtected(BuildContext context, HabitProvider provider, int id) {
    final streak = provider.currentStreak(id);
    if (kStreakMilestones.contains(streak)) {
      celebrateMilestone(context, streak: streak, habitName: habit.name);
    } else {
      celebrateLoop(context, phrase: habit.celebration);
    }
  }

  Widget _buildAction(
      BuildContext context, HabitProvider provider, int id, Color color) {
    if (habit.isQuitHabit) {
      return _buildQuitAction(context, provider, id);
    }
    if (habit.isAmountTracking) {
      return _buildAmountAction(context, provider, id, color);
    }
    return _buildCheckoffAction(context, provider, id, color);
  }

  Widget _buildCheckoffAction(
      BuildContext context, HabitProvider provider, int id, Color color) {
    final done = provider.isCompletedToday(id);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      label: done ? 'Mark ${habit.name} not done' : 'Complete ${habit.name}',
      child: GestureDetector(
        onTap: () async {
          if (!done) {
            await provider.toggleToday(id);
            if (context.mounted) _afterProtected(context, provider, id);
          } else {
            HapticFeedback.selectionClick();
            await provider.toggleToday(id);
          }
        },
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color : Colors.transparent,
            border: Border.all(
              color: done ? color : Ah.textTertiary,
              width: 2,
            ),
          ),
          child: done
              ? const Icon(Icons.check, color: Ah.onAccent, size: 26)
              : null,
        ),
      ),
    );
  }

  Widget _buildAmountAction(
      BuildContext context, HabitProvider provider, int id, Color color) {
    final current = provider.todayAmount(id);
    final target = habit.targetAmount;
    final done = current >= target;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      button: true,
      label: 'Add one ${habit.unit.isNotEmpty ? habit.unit : "unit"} '
          'to ${habit.name}',
      child: GestureDetector(
        onTap: () async {
          final wasDone = done;
          HapticFeedback.selectionClick();
          await provider.incrementAmount(id);
          final nowDone = provider.todayAmount(id) >= target;
          if (!wasDone && nowDone && context.mounted) {
            _afterProtected(context, provider, id);
          }
        },
        onLongPress: () => _showAmountSheet(context, provider, id, current),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Ah.surface3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(done ? Ah.mint : color),
                ),
              ),
              Text(
                '$current',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: done ? Ah.mint : Ah.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAmountSheet(
      BuildContext context, HabitProvider provider, int id, int current) {
    final controller = TextEditingController(text: '$current');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          Ah.gutter,
          Ah.s8,
          Ah.gutter,
          MediaQuery.of(ctx).viewInsets.bottom + Ah.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set ${habit.unit.isNotEmpty ? habit.unit : "amount"}',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: Ah.s16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Target: ${habit.targetAmount}',
              ),
            ),
            const SizedBox(height: Ah.s16),
            FilledButton(
              onPressed: () {
                final val = int.tryParse(controller.text) ?? 0;
                provider.setAmount(id, val);
                Navigator.of(ctx).pop();
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuitAction(
      BuildContext context, HabitProvider provider, int id) {
    final slippedToday = provider.isCompletedToday(id);
    return Semantics(
      button: true,
      label: slippedToday
          ? 'Undo slip for ${habit.name}'
          : 'Log a slip for ${habit.name}',
      child: GestureDetector(
        onTap: () => _confirmSlip(context, provider, id),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: slippedToday ? Ah.tint(Ah.danger) : Ah.tint(Ah.mint),
            border: Border.all(
              color: slippedToday ? Ah.danger : Ah.mint,
              width: 1.5,
            ),
          ),
          child: Icon(
            slippedToday ? Icons.warning_rounded : Icons.shield_outlined,
            color: slippedToday ? Ah.danger : Ah.mint,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _confirmSlip(BuildContext context, HabitProvider provider, int id) {
    if (provider.isCompletedToday(id)) {
      // Undo the slip
      HapticFeedback.selectionClick();
      provider.toggleToday(id);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log a slip?'),
        content: Text(
          'This resets your "${habit.name}" streak. Only log if you actually slipped — honesty keeps the streak meaningful.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Ah.danger),
            onPressed: () {
              provider.toggleToday(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Yes, I slipped'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(
      BuildContext context, HabitProvider provider, int id, int streak) {
    final labelStyle = Theme.of(context).textTheme.labelMedium;

    if (habit.isQuitHabit) {
      return Row(
        children: [
          Icon(Icons.shield,
              size: 14, color: streak > 0 ? Ah.mint : Ah.textTertiary),
          const SizedBox(width: Ah.s4),
          Text('$streak ${streak == 1 ? "day" : "days"} free',
              style: labelStyle),
        ],
      );
    }

    if (habit.isAmountTracking) {
      final current = provider.todayAmount(id);
      return Row(
        children: [
          const Icon(Icons.track_changes, size: 14, color: Ah.info),
          const SizedBox(width: Ah.s4),
          Text('$current/${habit.targetAmount} ${habit.unit}',
              style: labelStyle),
          const SizedBox(width: Ah.s8),
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: streak > 0 ? Ah.warning : Ah.textTertiary,
          ),
          const SizedBox(width: 2),
          Text('$streak', style: labelStyle),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          size: 14,
          color: streak > 0 ? Ah.warning : Ah.textTertiary,
        ),
        const SizedBox(width: Ah.s4),
        Text('$streak ${streak == 1 ? "day" : "days"}', style: labelStyle),
      ],
    );
  }
}
