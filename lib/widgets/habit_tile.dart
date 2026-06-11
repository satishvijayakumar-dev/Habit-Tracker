import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import 'habit_style.dart';

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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAction(context, provider, id),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: _isComplete(provider, id)
                            ? TextDecoration.lineThrough
                            : null,
                        color: _isComplete(provider, id) ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSubtitle(provider, id, streak),
                    if (habit.anchor.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'After ${habit.anchor}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(iconFor(habit.iconName), color: color, size: 24),
            ],
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

  Widget _buildAction(BuildContext context, HabitProvider provider, int id) {
    if (habit.isQuitHabit) {
      return _buildQuitAction(context, provider, id);
    }
    if (habit.isAmountTracking) {
      return _buildAmountAction(context, provider, id);
    }
    return _buildCheckoffAction(provider, id);
  }

  Widget _buildCheckoffAction(HabitProvider provider, int id) {
    final done = provider.isCompletedToday(id);
    return IconButton(
      iconSize: 32,
      onPressed: () => _onCheckoff(provider, id),
      icon: Icon(
        done ? Icons.check_circle : Icons.circle_outlined,
        color: done ? Colors.green : Colors.grey.shade400,
      ),
    );
  }

  void _onCheckoff(HabitProvider provider, int id) {
    provider.toggleToday(id);
  }

  Widget _buildAmountAction(
      BuildContext context, HabitProvider provider, int id) {
    final current = provider.todayAmount(id);
    final target = habit.targetAmount;
    final done = current >= target;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: () => provider.incrementAmount(id),
      onLongPress: () => _showAmountDialog(context, provider, id, current),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                done ? Colors.green : Colors.blue,
              ),
            ),
            Text(
              '$current',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: done ? Colors.green : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAmountDialog(
      BuildContext context, HabitProvider provider, int id, int current) {
    final controller = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set ${habit.unit.isNotEmpty ? habit.unit : "amount"}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Target: ${habit.targetAmount}',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
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
    );
  }

  Widget _buildQuitAction(
      BuildContext context, HabitProvider provider, int id) {
    final slippedToday = provider.isCompletedToday(id);
    return IconButton(
      iconSize: 32,
      onPressed: () => _confirmSlip(context, provider, id),
      icon: Icon(
        slippedToday ? Icons.warning_rounded : Icons.shield_outlined,
        color: slippedToday ? Colors.red : Colors.green,
      ),
    );
  }

  void _confirmSlip(BuildContext context, HabitProvider provider, int id) {
    if (provider.isCompletedToday(id)) {
      // Undo the slip
      provider.toggleToday(id);
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log a slip?'),
        content: Text(
          'This resets your "${habit.name}" streak. Only log if you actually slipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

  Widget _buildSubtitle(HabitProvider provider, int id, int streak) {
    if (habit.isQuitHabit) {
      return Row(
        children: [
          Icon(Icons.shield,
              size: 14,
              color: streak > 0 ? Colors.green : Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            '$streak ${streak == 1 ? "day" : "days"} free',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      );
    }

    if (habit.isAmountTracking) {
      final current = provider.todayAmount(id);
      return Row(
        children: [
          const Icon(Icons.track_changes, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            '$current/${habit.targetAmount} ${habit.unit}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.local_fire_department,
            size: 14,
            color: streak > 0 ? Colors.orange : Colors.grey.shade400,
          ),
          const SizedBox(width: 2),
          Text(
            '$streak',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          size: 14,
          color: streak > 0 ? Colors.orange : Colors.grey.shade400,
        ),
        const SizedBox(width: 4),
        Text(
          '$streak ${streak == 1 ? "day" : "days"}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
