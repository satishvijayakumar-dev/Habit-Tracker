import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';

class PathOnboardingScreen extends StatelessWidget {
  const PathOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const paths = [
      _PathOption(
        name: 'Health & Energy',
        description: 'Build movement, sleep, hydration, and recovery loops.',
        icon: Icons.bolt_outlined,
        color: Colors.teal,
      ),
      _PathOption(
        name: 'Calm & Reset',
        description: 'Create tiny pauses for stress, mood, and reflection.',
        icon: Icons.self_improvement_outlined,
        color: Colors.indigo,
      ),
      _PathOption(
        name: 'Focus Builder',
        description: 'Protect deep work, study blocks, and digital boundaries.',
        icon: Icons.center_focus_strong_outlined,
        color: Colors.blue,
      ),
      _PathOption(
        name: 'Break a Pattern',
        description: 'Track urges, slips, and recovery plans without shame.',
        icon: Icons.shield_outlined,
        color: Colors.redAccent,
      ),
      _PathOption(
        name: 'Money Mindful',
        description:
            'Add friction before spending and celebrate better choices.',
        icon: Icons.savings_outlined,
        color: Colors.green,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            Text(
              'ActivHealth',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choose the loop you want to improve first',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              'ActivHealth turns goals into tiny behavior loops: anchor, smallest action, fallback, and celebration.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 22),
            ...paths.map((path) => _PathCard(path: path)),
          ],
        ),
      ),
    );
  }
}

class _PathCard extends StatelessWidget {
  final _PathOption path;

  const _PathCard({required this.path});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.read<HabitProvider>().setSelectedPath(path.name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: path.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(path.icon, color: path.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      path.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      path.description,
                      style:
                          TextStyle(color: Colors.grey.shade700, height: 1.3),
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

class _PathOption {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const _PathOption({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
