import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../widgets/habit_style.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final weeklyBreakdown = provider.weeklyMinutesByType;
    final activeMinutes = provider.activeMinutesThisWeek;
    final sessions = provider.activitySessionsThisWeek;
    final profile = provider.profile;
    final latestMetric =
        provider.bodyMetrics.isEmpty ? null : provider.bodyMetrics.first;
    final firstMetric =
        provider.bodyMetrics.isEmpty ? null : provider.bodyMetrics.last;
    final weightChange = latestMetric == null || firstMetric == null
        ? null
        : latestMetric.weightKg - firstMetric.weightKg;

    final sorted = [...habits]..sort((a, b) {
        if (a.id == null || b.id == null) return 0;
        return provider.currentStreak(b.id!) - provider.currentStreak(a.id!);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly report')),
      body: habits.isEmpty && provider.activities.isEmpty
          ? Center(
              child: Text(
                'Log activity or create loops to see your report.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Active minutes',
                        value: '$activeMinutes',
                        color: Colors.blue,
                        icon: Icons.directions_run,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Sessions',
                        value: '$sessions',
                        color: Colors.orange,
                        icon: Icons.event_available,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Calories est.',
                        value: '${provider.estimatedCaloriesThisWeek}',
                        color: Colors.green,
                        icon: Icons.local_fire_department_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Star points',
                        value: '${provider.starPoints}',
                        color: Colors.purple,
                        icon: Icons.star,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (profile != null) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.monitor_weight_outlined),
                      title: Text(
                        'BMI ${profile.bmi.toStringAsFixed(1)} - ${profile.bmiLabel}',
                      ),
                      subtitle: Text(
                        weightChange == null
                            ? 'Add body check-ins to compare before and after.'
                            : 'Weight change since start: ${weightChange >= 0 ? "+" : ""}${weightChange.toStringAsFixed(1)} kg',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_late_outlined),
                    title: const Text('Planned sessions'),
                    subtitle: Text(
                      provider.missedPlannedSessionsThisWeek == 0
                          ? 'On track this week.'
                          : '${provider.missedPlannedSessionsThisWeek} session${provider.missedPlannedSessionsThisWeek == 1 ? "" : "s"} missed or still open.',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Movement breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (weeklyBreakdown.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No movement logged this week yet.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  )
                else
                  ...weeklyBreakdown.entries.map(
                    (entry) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.timeline),
                        title: Text(entry.key),
                        trailing: Text(
                          '${entry.value} min',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Behavior loops',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...sorted.map((h) {
                  final streak =
                      h.id != null ? provider.currentStreak(h.id!) : 0;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        iconFor(h.iconName),
                        color: colorFor(h.colorName),
                      ),
                      title: Text(h.name),
                      trailing: Text(
                        '$streak ${streak == 1 ? "day" : "days"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy data as CSV'),
                  onPressed: () async {
                    final csv = provider.exportAsCsv();
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV copied to clipboard'),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

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
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
