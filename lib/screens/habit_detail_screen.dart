import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_style.dart';
import 'add_edit_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final int habitId;
  const HabitDetailScreen({super.key, required this.habitId});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final provider = context.read<HabitProvider>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete loop?'),
        content: const Text(
            'This will permanently delete the loop and all its history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Ah.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await provider.deleteHabit(widget.habitId);
    if (!mounted) return;
    navigator.pop();
  }

  void _showNoteDialog(
      BuildContext context, HabitProvider provider, Habit habit) {
    final existing = provider.completionDetailFor(habit.id!, DateTime.now());
    _noteController.text = existing?.note ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Habit diary'),
        content: TextField(
          controller: _noteController,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'How did it go? Any reflections?',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.addNote(habit.id!, _noteController.text.trim());
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    // The habit can disappear mid-frame (e.g. just deleted). Never crash:
    // render an empty frame while the route pops.
    Habit? found;
    for (final h in provider.habits) {
      if (h.id == widget.habitId) {
        found = h;
        break;
      }
    }
    if (found == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final habit = found;

    final streak = provider.currentStreak(habit.id!);
    final total = provider.completionsFor(habit.id!).length;
    final completionsInMonth = provider.completionsInMonth(habit.id!, _month);
    final notes = provider.getNotesForHabit(habit.id!);

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => AddEditHabitScreen(habit: habit)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorFor(habit.colorName).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconFor(habit.iconName),
                        color: colorFor(habit.colorName), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(habit.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: habit.isQuitHabit
                                    ? Ah.tint(Ah.danger)
                                    : Ah.tint(Ah.mint),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                habit.isQuitHabit ? 'Quit' : 'Build',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: habit.isQuitHabit
                                      ? Ah.danger
                                      : Ah.mint,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (habit.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(habit.description,
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                        ],
                        if (habit.isAmountTracking) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target: ${habit.targetAmount} ${habit.unit}',
                            style: const TextStyle(
                                fontSize: 12, color: Ah.info),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (habit.anchor.isNotEmpty ||
              habit.fallbackBehavior.isNotEmpty ||
              habit.celebration.isNotEmpty) ...[
            _LoopBlueprintCard(habit: habit),
            const SizedBox(height: 12),
          ],

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: habit.isQuitHabit ? 'Days free' : 'Current streak',
                  value: '$streak',
                  unit: streak == 1 ? 'day' : 'days',
                  icon: habit.isQuitHabit
                      ? Icons.shield
                      : Icons.local_fire_department,
                  color: habit.isQuitHabit ? Ah.mint : Ah.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Total',
                  value: '$total',
                  unit: habit.isQuitHabit
                      ? (total == 1 ? 'slip' : 'slips')
                      : (total == 1 ? 'completion' : 'completions'),
                  icon: Icons.check_circle_outline,
                  color: Ah.mint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (habit.isQuitHabit)
            _buildQuitButton(context, provider, habit)
          else if (habit.isAmountTracking)
            _buildAmountButton(context, provider, habit)
          else
            _buildCheckoffButton(provider, habit),

          const SizedBox(height: 8),

          // Diary note button
          OutlinedButton.icon(
            onPressed: () => _showNoteDialog(context, provider, habit),
            icon: const Icon(Icons.edit_note),
            label: const Text('Add diary note'),
          ),
          const SizedBox(height: 24),

          // Month calendar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1)),
              Text(
                DateFormat('MMMM yyyy').format(_month),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftMonth(1)),
            ],
          ),
          const SizedBox(height: 8),
          _MonthGrid(
            month: _month,
            completions: completionsInMonth,
            accent: colorFor(habit.colorName),
          ),
          const SizedBox(height: 24),

          // Diary notes section
          if (notes.isNotEmpty) ...[
            Text('Diary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...notes.take(10).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: Ah.s8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEE, MMM d yyyy').format(c.date),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(c.note,
                              style:
                                  Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCheckoffButton(HabitProvider provider, Habit habit) {
    final done = provider.isCompletedToday(habit.id!);
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.mediumImpact();
        provider.toggleToday(habit.id!);
      },
      icon: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked),
      label: Text(done ? 'Completed today' : 'Mark as complete'),
      style: FilledButton.styleFrom(
        backgroundColor: done ? Ah.mint : null,
      ),
    );
  }

  Widget _buildAmountButton(
      BuildContext context, HabitProvider provider, Habit habit) {
    final current = provider.todayAmount(habit.id!);
    final done = current >= habit.targetAmount;
    return FilledButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        provider.incrementAmount(habit.id!);
      },
      icon: Icon(done ? Icons.check_circle : Icons.add),
      label: Text(
        '$current / ${habit.targetAmount} ${habit.unit}${done ? " — Done!" : ""}',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: done ? Ah.mint : null,
      ),
    );
  }

  Widget _buildQuitButton(
      BuildContext context, HabitProvider provider, Habit habit) {
    final slippedToday = provider.isCompletedToday(habit.id!);
    return FilledButton.icon(
      onPressed: () {
        if (slippedToday) {
          provider.toggleToday(habit.id!);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Log a slip?'),
              content: Text('This resets your "${habit.name}" streak.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel')),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: Ah.danger),
                  onPressed: () {
                    provider.toggleToday(habit.id!);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Yes, I slipped'),
                ),
              ],
            ),
          );
        }
      },
      icon: Icon(slippedToday ? Icons.undo : Icons.warning_rounded),
      label: Text(slippedToday ? 'Undo slip' : 'Log a slip'),
      style: FilledButton.styleFrom(
        backgroundColor: slippedToday ? Ah.warning : Ah.danger,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.unit,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(width: 4),
                Text(unit, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoopBlueprintCard extends StatelessWidget {
  final Habit habit;

  const _LoopBlueprintCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined, size: 18, color: Ah.accent),
                const SizedBox(width: 8),
                Text(
                  'Loop blueprint',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (habit.pathName.isNotEmpty)
              _LoopLine(label: 'Path', value: habit.pathName),
            if (habit.anchor.isNotEmpty)
              _LoopLine(label: 'After I', value: habit.anchor),
            _LoopLine(label: 'I will', value: habit.name),
            if (habit.fallbackBehavior.isNotEmpty)
              _LoopLine(label: 'Fallback', value: habit.fallbackBehavior),
            if (habit.celebration.isNotEmpty)
              _LoopLine(label: 'Celebrate', value: habit.celebration),
            _LoopLine(label: 'Size', value: habit.difficulty),
          ],
        ),
      ),
    );
  }
}

class _LoopLine extends StatelessWidget {
  final String label;
  final String value;

  const _LoopLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final Set<DateTime> completions;
  final Color accent;

  const _MonthGrid({
    required this.month,
    required this.completions,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7;
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    final cells = <Widget>[];
    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final l in weekdayLabels) {
      cells.add(Center(
        child: Text(l, style: Theme.of(context).textTheme.labelSmall),
      ));
    }

    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final done = completions.contains(date);
      final isToday = date == todayKey;
      cells.add(
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: done ? accent : Ah.surface2,
              borderRadius: BorderRadius.circular(6),
              border: isToday
                  ? Border.all(color: done ? Ah.textPrimary : accent, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$d',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done ? Ah.onAccent : Ah.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}
