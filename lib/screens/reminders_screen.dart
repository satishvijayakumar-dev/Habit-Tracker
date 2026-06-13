import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

/// User-set daily reminders. Each fires a friendly coach nudge at the chosen
/// time (scheduled via the local notification service).
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  String _format(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _add(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && context.mounted) {
      await context
          .read<HabitProvider>()
          .addReminder(picked.hour, picked.minute);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final reminders = provider.reminderMinutes;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Text(
            'Daily nudges from your coach. Set as many as you like — a morning move, a lunch walk, an evening wind-down.',
            style: textTheme.bodyMedium
                ?.copyWith(color: Ah.textSecondary, height: 1.4),
          ),
          const SizedBox(height: Ah.s16),
          if (reminders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Ah.s24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Ah.tint(Ah.accent),
                        borderRadius: BorderRadius.circular(Ah.rLg),
                      ),
                      child: const Icon(Icons.notifications_active,
                          color: Ah.accent, size: 28),
                    ),
                    const SizedBox(height: Ah.s12),
                    Text('No reminders yet', style: textTheme.titleMedium),
                    const SizedBox(height: Ah.s4),
                    Text('Add one to get a gentle daily prompt.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall),
                  ],
                ),
              ),
            )
          else
            ...reminders.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: Ah.s8),
                  child: Card(
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Ah.tint(Ah.accent),
                          borderRadius: BorderRadius.circular(Ah.rSm),
                        ),
                        child: const Icon(Icons.alarm, color: Ah.accent),
                      ),
                      title: Text(_format(m), style: textTheme.titleMedium),
                      subtitle: const Text('Daily'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove',
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          provider.removeReminder(m);
                        },
                      ),
                    ),
                  ),
                )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reminders_fab',
        backgroundColor: Ah.accent,
        foregroundColor: Ah.onAccent,
        onPressed: () => _add(context),
        icon: const Icon(Icons.add_alarm),
        label: const Text('Add reminder'),
      ),
    );
  }
}
