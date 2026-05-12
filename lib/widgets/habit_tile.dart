import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import 'habit_style.dart';

/// Compact tile shown on the Today screen.
class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onTap;

  const HabitTile({super.key, required this.habit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final id = habit.id;
    if (id == null) return const SizedBox.shrink();

    final done = provider.isCompletedToday(id);
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
              IconButton(
                iconSize: 32,
                onPressed: () => provider.toggleToday(id),
                icon: Icon(
                  done ? Icons.check_circle : Icons.circle_outlined,
                  color: done ? Colors.green : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        color: done ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: streak > 0
                              ? Colors.orange
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$streak day${streak == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
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
}
