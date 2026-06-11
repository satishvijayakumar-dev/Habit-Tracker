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

    final totalStreak = habits.fold<int>(
      0,
      (sum, h) => sum + (h.id != null ? provider.currentStreak(h.id!) : 0),
    );
    final avgStreak = habits.isEmpty ? 0.0 : totalStreak / habits.length;

    final sorted = [...habits]..sort((a, b) {
        if (a.id == null || b.id == null) return 0;
        return provider.currentStreak(b.id!) - provider.currentStreak(a.id!);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: habits.isEmpty
          ? Center(
              child: Text(
                'Create loops to see stats.',
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
                        label: 'Active loops',
                        value: '${habits.length}',
                        color: Colors.blue,
                        icon: Icons.list_alt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total streak',
                        value: '$totalStreak',
                        color: Colors.orange,
                        icon: Icons.local_fire_department,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  label: 'Average streak',
                  value: avgStreak.toStringAsFixed(1),
                  color: Colors.green,
                  icon: Icons.trending_up,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Breakdown',
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
