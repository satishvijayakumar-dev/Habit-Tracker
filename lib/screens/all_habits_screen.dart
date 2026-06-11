import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../widgets/habit_style.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';

class AllHabitsScreen extends StatelessWidget {
  const AllHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All loops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddEditHabitScreen(),
              ),
            ),
          ),
        ],
      ),
      body: habits.isEmpty
          ? Center(
              child: Text(
                'No loops yet.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, i) {
                final h = habits[i];
                final streak = h.id != null ? provider.currentStreak(h.id!) : 0;
                return Dismissible(
                  key: ValueKey(h.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Delete "${h.name}"?'),
                            content: const Text(
                              'This will permanently delete the loop and all its history.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) {
                    if (h.id != null) provider.deleteHabit(h.id!);
                  },
                  child: ListTile(
                    leading: Icon(
                      iconFor(h.iconName),
                      color: colorFor(h.colorName),
                    ),
                    title: Text(h.name),
                    subtitle: Text(
                      'Streak: $streak ${streak == 1 ? "day" : "days"}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HabitDetailScreen(habitId: h.id!),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
