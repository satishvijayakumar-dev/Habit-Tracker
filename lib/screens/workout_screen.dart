import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../services/habit_provider.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final Set<String> _selected = {};
  String _intensity = 'Moderate';
  double _minutes = 45;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final plan = provider.weeklyExercisePlan;
    final exercises = provider.exerciseLibrary;
    final missed = provider.missedPlannedSessionsThisWeek;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This week',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    missed == 0
                        ? 'You are on track. The next plan will build from this week.'
                        : '$missed planned session${missed == 1 ? "" : "s"} still open. Coach will rebalance the weekend instead of punishing the miss.',
                    style: const TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  ...plan.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Exercise library',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final exercise in exercises)
                FilterChip(
                  label: Text(exercise),
                  selected: _selected.contains(exercise),
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selected.add(exercise);
                      } else {
                        _selected.remove(exercise);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_minutes.round()} minutes',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Slider(
                    value: _minutes,
                    min: 10,
                    max: 120,
                    divisions: 22,
                    label: '${_minutes.round()} min',
                    onChanged: (value) => setState(() => _minutes = value),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Easy',
                        label: Text('Easy'),
                        icon: Icon(Icons.spa_outlined),
                      ),
                      ButtonSegment(
                        value: 'Moderate',
                        label: Text('Moderate'),
                        icon: Icon(Icons.fitness_center),
                      ),
                      ButtonSegment(
                        value: 'Hard',
                        label: Text('Hard'),
                        icon: Icon(Icons.local_fire_department_outlined),
                      ),
                    ],
                    selected: {_intensity},
                    onSelectionChanged: (value) {
                      setState(() => _intensity = value.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty ? null : () => _log(context),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Log selected workout'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _log(BuildContext context) async {
    final provider = context.read<HabitProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final exercises = _selected.join(', ');
    await provider.addActivity(
      ActivityLog(
        type: 'Gym',
        durationMinutes: _minutes.round(),
        intensity: _intensity,
        notes: 'Exercises: $exercises',
        completedAt: DateTime.now(),
      ),
    );
    setState(_selected.clear);
    if (mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Workout logged')));
    }
  }
}
