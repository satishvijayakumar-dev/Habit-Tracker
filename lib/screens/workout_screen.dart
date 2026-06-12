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

  static const _exercises = [
    _Exercise(
      name: 'Goblet Squat',
      group: 'Legs',
      sets: '4',
      reps: '8-12',
      safety: 'Knees track toes, chest tall.',
      cue: 'Controlled down, strong drive up.',
      color: Color(0xFFE53935),
      icon: Icons.accessibility_new,
    ),
    _Exercise(
      name: 'Romanian Deadlift',
      group: 'Posterior chain',
      sets: '3',
      reps: '8-10',
      safety: 'Hinge from hips, neutral spine.',
      cue: 'Push hips back, feel hamstrings load.',
      color: Color(0xFF7C3AED),
      icon: Icons.fitness_center,
    ),
    _Exercise(
      name: 'Shoulder Press',
      group: 'Shoulders',
      sets: '4',
      reps: '8-10',
      safety: 'Brace core, avoid back arch.',
      cue: 'Press up in a smooth vertical path.',
      color: Color(0xFF2563EB),
      icon: Icons.upload,
    ),
    _Exercise(
      name: 'Lat Pulldown',
      group: 'Back',
      sets: '4',
      reps: '8-12',
      safety: 'Pull to upper chest, no swinging.',
      cue: 'Lead with elbows, squeeze shoulder blades.',
      color: Color(0xFF0E9F6E),
      icon: Icons.keyboard_double_arrow_down,
    ),
    _Exercise(
      name: 'Push-Up',
      group: 'Chest',
      sets: '3',
      reps: 'Quality reps',
      safety: 'Straight line from head to heel.',
      cue: 'Slow lower, strong press.',
      color: Color(0xFFF59E0B),
      icon: Icons.open_in_full,
    ),
    _Exercise(
      name: 'Easy Run / Walk',
      group: 'Cardio',
      sets: '1',
      reps: '20-45 min',
      safety: 'Keep conversational pace.',
      cue: 'Tall posture, relaxed shoulders.',
      color: Color(0xFF0891B2),
      icon: Icons.directions_run,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final plan = provider.weeklyExercisePlan;
    final missed = provider.missedPlannedSessionsThisWeek;

    return Scaffold(
      appBar: AppBar(title: const Text('Today workout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _WorkoutHero(missed: missed, minutes: _minutes.round()),
          const SizedBox(height: 16),
          const Text(
            'AI trainer plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...plan.take(4).map((item) => Card(
                  child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(item),
              ))),
          const SizedBox(height: 16),
          const Text(
            'Select what you completed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ..._exercises.map(
            (exercise) => _ExerciseCard(
              exercise: exercise,
              selected: _selected.contains(exercise.name),
              onTap: () {
                setState(() {
                  if (_selected.contains(exercise.name)) {
                    _selected.remove(exercise.name);
                  } else {
                    _selected.add(exercise.name);
                  }
                });
              },
            ),
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
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
                      minimumSize: const Size.fromHeight(50),
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
        type: _selected.any((name) => name.contains('Run')) ? 'Running' : 'Gym',
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

class _WorkoutHero extends StatelessWidget {
  final int missed;
  final int minutes;

  const _WorkoutHero({required this.missed, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motion-guided session',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  missed == 0
                      ? 'Follow the plan, protect form, log honestly.'
                      : 'Rebalanced for $missed open session${missed == 1 ? "" : "s"}.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFFB74D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                '$minutes',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _Exercise exercise;
  final bool selected;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? exercise.color.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 86,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      exercise.color.withValues(alpha: 0.95),
                      exercise.color.withValues(alpha: 0.45),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(exercise.icon, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${exercise.group} - ${exercise.sets} x ${exercise.reps}'),
                    const SizedBox(height: 6),
                    Text(
                      exercise.cue,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Safety: ${exercise.safety}',
                      style: const TextStyle(
                        color: Color(0xFF0E9F6E),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.add_circle_outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Exercise {
  final String name;
  final String group;
  final String sets;
  final String reps;
  final String safety;
  final String cue;
  final Color color;
  final IconData icon;

  const _Exercise({
    required this.name,
    required this.group,
    required this.sets,
    required this.reps,
    required this.safety,
    required this.cue,
    required this.color,
    required this.icon,
  });
}
