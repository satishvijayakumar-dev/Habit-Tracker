import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
            border: OutlineInputBorder(),
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
    final habit = provider.habits.firstWhere(
      (h) => h.id == widget.habitId,
      orElse: () => provider.habits.first,
    );

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
                            Text(habit.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: habit.isQuitHabit
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                habit.isQuitHabit ? 'Quit' : 'Build',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: habit.isQuitHabit
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (habit.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(habit.description,
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade600)),
                        ],
                        if (habit.isAmountTracking) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Target: ${habit.targetAmount} ${habit.unit}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.blue),
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
                  color: habit.isQuitHabit ? Colors.green : Colors.orange,
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
                  color: Colors.green,
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
          FilledButton.icon(
            onPressed: () => _showNoteDialog(context, provider, habit),
            icon: const Icon(Icons.edit_note),
            label: const Text('Add diary note'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.indigo,
            ),
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
          _MonthGrid(month: _month, completions: completionsInMonth),
          const SizedBox(height: 24),

          // Diary notes section
          if (notes.isNotEmpty) ...[
            const Text('Diary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...notes.take(10).map((c) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEE, MMM d yyyy').format(c.date),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(c.note, style: const TextStyle(fontSize: 14)),
                      ],
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
    return FilledButton.icon(
      onPressed: () => provider.toggleToday(habit.id!),
      icon: Icon(
        provider.isCompletedToday(habit.id!)
            ? Icons.check_circle
            : Icons.radio_button_unchecked,
      ),
      label: Text(provider.isCompletedToday(habit.id!)
          ? 'Completed today'
          : 'Mark as complete'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor:
            provider.isCompletedToday(habit.id!) ? Colors.green : null,
      ),
    );
  }

  Widget _buildAmountButton(
      BuildContext context, HabitProvider provider, Habit habit) {
    final current = provider.todayAmount(habit.id!);
    final done = current >= habit.targetAmount;
    return FilledButton.icon(
      onPressed: () => provider.incrementAmount(habit.id!),
      icon: Icon(done ? Icons.check_circle : Icons.add),
      label: Text(
        '$current / ${habit.targetAmount} ${habit.unit}${done ? " — Done!" : ""}',
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: done ? Colors.green : null,
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
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
        minimumSize: const Size.fromHeight(48),
        backgroundColor: slippedToday ? Colors.orange : Colors.red,
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
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(unit,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
            const Row(
              children: [
                Icon(Icons.route_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  'Loop blueprint',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
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
  const _MonthGrid({required this.month, required this.completions});

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday % 7;

    final cells = <Widget>[];
    const weekdayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (final l in weekdayLabels) {
      cells.add(Center(
        child: Text(l,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
      ));
    }

    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final done = completions.contains(date);
      cells.add(
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: done ? Colors.green : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$d',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done ? Colors.white : Colors.grey.shade700,
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

class Calendar {}
