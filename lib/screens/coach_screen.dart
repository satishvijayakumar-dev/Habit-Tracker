import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../widgets/habit_style.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final plan = _buildPlan(provider, habits);
    final pathName = provider.selectedPath ?? 'ActivHealth';

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: habits.isEmpty
          ? _CoachEmptyState(
              onAdd: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _PulseHeader(
                  provider: provider,
                  habits: habits,
                  pathName: pathName,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Today plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...plan.map(
                  (item) => _CoachPlanCard(
                    item: item,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            HabitDetailScreen(habitId: item.habit.id!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ReflectionCard(provider: provider, habits: habits),
              ],
            ),
    );
  }

  List<_CoachPlanItem> _buildPlan(HabitProvider provider, List<Habit> habits) {
    final items = <_CoachPlanItem>[];

    for (final habit in habits) {
      if (habit.id == null) continue;
      final id = habit.id!;
      final streak = provider.currentStreak(id);
      final done = _isDoneToday(provider, habit);
      final note = provider.completionDetailFor(id, DateTime.now())?.note ?? '';

      if (habit.isQuitHabit) {
        items.add(
          _CoachPlanItem(
            habit: habit,
            priority: done ? 1 : 3,
            title: done ? 'Protect the clean day' : 'Reset without hiding it',
            body: done
                ? 'You are ${streak == 1 ? "1 day" : "$streak days"} free. Reinforce the anchor that protected you today.'
                : _fallbackText(habit,
                    'A slip is logged today. Use the smallest recovery loop and note the trigger.'),
            icon: done ? Icons.shield_outlined : Icons.restart_alt,
          ),
        );
      } else if (habit.isAmountTracking) {
        final current = provider.todayAmount(id);
        final remaining =
            (habit.targetAmount - current).clamp(0, habit.targetAmount);
        items.add(
          _CoachPlanItem(
            habit: habit,
            priority: done ? 1 : 4,
            title: done ? 'Target reached' : 'Close the gap',
            body: done
                ? 'Nice. Add a quick note about when this was easiest.'
                : _fallbackText(
                    habit,
                    '$remaining ${habit.unit.isEmpty ? "more" : habit.unit} left. Try the smallest version now.',
                  ),
            icon: done ? Icons.flag_circle_outlined : Icons.track_changes,
          ),
        );
      } else {
        items.add(
          _CoachPlanItem(
            habit: habit,
            priority: done ? 1 : (streak > 0 ? 4 : 3),
            title: done ? 'Done today' : 'Keep the chain alive',
            body: done
                ? 'Capture the cue that made ${habit.name} happen today.'
                : streak > 0
                    ? _fallbackText(
                        habit,
                        '$streak-day streak at risk. Finish the fallback version.',
                      )
                    : _fallbackText(
                        habit,
                        'Start with a two-minute version, then mark it complete.',
                      ),
            icon: done
                ? Icons.check_circle_outline
                : Icons.local_fire_department_outlined,
          ),
        );
      }

      if (done && note.isEmpty) {
        items.add(
          _CoachPlanItem(
            habit: habit,
            priority: 2,
            title: 'Add the why',
            body:
                'A short diary note turns a checkmark into a pattern you can repeat.',
            icon: Icons.edit_note_outlined,
          ),
        );
      }
    }

    items.sort((a, b) => b.priority.compareTo(a.priority));
    return items.take(5).toList();
  }

  bool _isDoneToday(HabitProvider provider, Habit habit) {
    final id = habit.id!;
    if (habit.isQuitHabit) return !provider.isCompletedToday(id);
    if (habit.isAmountTracking) {
      return provider.todayAmount(id) >= habit.targetAmount;
    }
    return provider.isCompletedToday(id);
  }

  String _fallbackText(Habit habit, String backup) {
    if (habit.fallbackBehavior.isEmpty) return backup;
    return 'Fallback: ${habit.fallbackBehavior}';
  }
}

class _PulseHeader extends StatelessWidget {
  final HabitProvider provider;
  final List<Habit> habits;
  final String pathName;

  const _PulseHeader({
    required this.provider,
    required this.habits,
    required this.pathName,
  });

  @override
  Widget build(BuildContext context) {
    final complete = provider.completedTodayCount;
    final total = habits.length;
    final ratio = total == 0 ? 0.0 : complete / total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$pathName: $complete of $total loops protected',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: ratio, minHeight: 10),
          ),
          const SizedBox(height: 12),
          Text(
            ratio == 1
                ? 'All loops are safe for today. Use the diary to record what worked.'
                : 'Focus on the smallest next action. ActivHealth loops improve when the fallback is clear.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachPlanCard extends StatelessWidget {
  final _CoachPlanItem item;
  final VoidCallback onOpen;

  const _CoachPlanCard({required this.item, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final color = colorFor(item.habit.colorName);
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                    if (item.habit.anchor.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'After: ${item.habit.anchor}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      item.habit.name,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final HabitProvider provider;
  final List<Habit> habits;

  const _ReflectionCard({required this.provider, required this.habits});

  @override
  Widget build(BuildContext context) {
    final notes = habits
        .where((habit) => habit.id != null)
        .expand((habit) => provider.getNotesForHabit(habit.id!))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_stories_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  'Pattern journal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notes.isEmpty
                  ? 'Add diary notes from any loop detail screen. Coach will surface recent patterns here.'
                  : '"${notes.first.note}"',
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _CoachEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_alt_outlined,
              size: 70,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Build your first coaching loop',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Create one ActivHealth loop with an anchor, fallback, and celebration. Coach will turn check-ins into a short action plan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create loop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachPlanItem {
  final Habit habit;
  final int priority;
  final String title;
  final String body;
  final IconData icon;

  const _CoachPlanItem({
    required this.habit,
    required this.priority,
    required this.title,
    required this.body,
    required this.icon,
  });
}
