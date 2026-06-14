import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/activity.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

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
      icon: Icons.accessibility_new,
    ),
    _Exercise(
      name: 'Romanian Deadlift',
      group: 'Posterior chain',
      sets: '3',
      reps: '8-10',
      safety: 'Hinge from hips, neutral spine.',
      cue: 'Push hips back, feel hamstrings load.',
      icon: Icons.fitness_center,
    ),
    _Exercise(
      name: 'Shoulder Press',
      group: 'Shoulders',
      sets: '4',
      reps: '8-10',
      safety: 'Brace core, avoid back arch.',
      cue: 'Press up in a smooth vertical path.',
      icon: Icons.upload,
    ),
    _Exercise(
      name: 'Lat Pulldown',
      group: 'Back',
      sets: '4',
      reps: '8-12',
      safety: 'Pull to upper chest, no swinging.',
      cue: 'Lead with elbows, squeeze shoulder blades.',
      icon: Icons.keyboard_double_arrow_down,
    ),
    _Exercise(
      name: 'Push-Up',
      group: 'Chest',
      sets: '3',
      reps: 'Quality reps',
      safety: 'Straight line from head to heel.',
      cue: 'Slow lower, strong press.',
      icon: Icons.open_in_full,
    ),
    _Exercise(
      name: 'Easy Run / Walk',
      group: 'Cardio',
      sets: '1',
      reps: '20-45 min',
      safety: 'Keep conversational pace.',
      cue: 'Tall posture, relaxed shoulders.',
      icon: Icons.directions_walk,
      category: 'running',
      pace: '5:30-6:30 /km · easy',
    ),
    _Exercise(
      name: 'Intervals',
      group: 'Cardio',
      sets: '1',
      reps: '6×1 min hard / 2 min easy',
      safety: 'Warm up 10 min first; stop if sharp pain.',
      cue: 'Strong but smooth on the hard reps.',
      icon: Icons.speed,
      category: 'running',
      pace: '4:00-4:45 /km on efforts',
    ),
    _Exercise(
      name: 'Tempo Run',
      group: 'Cardio',
      sets: '1',
      reps: '25-40 min',
      safety: 'Comfortably hard — not all-out.',
      cue: 'Settle into a steady, controlled effort.',
      icon: Icons.trending_up,
      category: 'running',
      pace: '4:30-5:10 /km',
    ),
    _Exercise(
      name: 'Long Run',
      group: 'Cardio',
      sets: '1',
      reps: '45-75 min',
      safety: 'Hydrate; ease off if form fades.',
      cue: 'Relaxed and steady the whole way.',
      icon: Icons.route,
      category: 'running',
      pace: '5:45-6:45 /km',
    ),
    _Exercise(
      name: 'Hill Repeats',
      group: 'Cardio',
      sets: '1',
      reps: '6-10 × 60-90s',
      safety: 'Strong arm drive up; walk down to recover.',
      cue: 'Powerful uphill, easy controlled descent.',
      icon: Icons.terrain,
      category: 'running',
      pace: 'Hard effort uphill',
    ),
    _Exercise(
      name: 'Recovery Run',
      group: 'Cardio',
      sets: '1',
      reps: '20-35 min',
      safety: 'Very easy — this is active recovery.',
      cue: 'Light, bouncy steps, relaxed shoulders.',
      icon: Icons.self_improvement,
      category: 'running',
      pace: '6:30-7:30 /km',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final plan = provider.weeklyExercisePlan;
    final missed = provider.missedPlannedSessionsThisWeek;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Session')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          _WorkoutHero(missed: missed, minutes: _minutes.round()),
          const SizedBox(height: Ah.s24),
          Text("This week's plan", style: textTheme.titleLarge),
          const SizedBox(height: Ah.s8),
          ...plan.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: Ah.s8),
                  child: Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.event_note_outlined, color: Ah.info),
                      title: Text(item),
                    ),
                  ),
                ),
              ),
          const SizedBox(height: Ah.s16),
          Text('Select what you completed', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s8),
          ..._exercises.map(
            (exercise) => _ExerciseCard(
              exercise: exercise,
              selected: _selected.contains(exercise.name),
              onTap: () {
                HapticFeedback.selectionClick();
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
          const SizedBox(height: Ah.s16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Ah.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_minutes.round()} minutes',
                      style: textTheme.titleMedium),
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
                      HapticFeedback.selectionClick();
                      setState(() => _intensity = value.first);
                    },
                  ),
                  const SizedBox(height: Ah.s16),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty ? null : () => _log(context),
                    icon: const Icon(Icons.done_all),
                    label: const Text('Log session'),
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
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final exercises = _selected.join(', ');
    // Type from the selected exercises' categories so calorie burn uses the
    // right MET (running ≫ light strength at the same duration).
    final anyRunning = _exercises
        .where((e) => _selected.contains(e.name))
        .any((e) => e.category == 'running');
    await provider.addActivity(
      ActivityLog(
        type: anyRunning ? 'Running' : 'Gym',
        durationMinutes: _minutes.round(),
        intensity: _intensity,
        notes: 'Exercises: $exercises',
        completedAt: DateTime.now(),
      ),
    );
    HapticFeedback.mediumImpact();
    setState(_selected.clear);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Ah.mint, size: 20),
            SizedBox(width: Ah.s8),
            Expanded(child: Text('Session logged — ring updated')),
          ],
        ),
      ),
    );
    // Back to Today so the ring visibly advances: effort -> progress.
    if (navigator.canPop()) navigator.pop();
  }
}

class _WorkoutHero extends StatelessWidget {
  final int missed;
  final int minutes;

  const _WorkoutHero({required this.missed, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Ah.gutter),
      decoration: BoxDecoration(
        color: Ah.surface2,
        borderRadius: BorderRadius.circular(Ah.rXl),
        border: Border.all(color: Ah.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guided session', style: textTheme.headlineSmall),
                const SizedBox(height: Ah.s8),
                Text(
                  missed == 0
                      ? 'Follow the plan, protect form, log honestly.'
                      : '$missed open session${missed == 1 ? "" : "s"} left this week — this one counts.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Ah.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: Ah.s12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: Ah.brandGradient,
              borderRadius: BorderRadius.circular(Ah.rLg),
            ),
            child: Center(
              child: Text(
                '$minutes',
                style: textTheme.headlineSmall?.copyWith(color: Ah.onAccent),
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
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: Ah.s8),
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(Ah.tint(Ah.accent), Ah.surface1)
            : Ah.surface1,
        borderRadius: BorderRadius.circular(Ah.rLg),
        border: Border.all(
          color: selected ? Ah.accent : Ah.hairline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Ah.rLg),
          child: Padding(
            padding: const EdgeInsets.all(Ah.s12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? Ah.tint(Ah.accent) : Ah.surface3,
                    borderRadius: BorderRadius.circular(Ah.rMd),
                  ),
                  child: Icon(
                    exercise.icon,
                    color: selected ? Ah.accent : Ah.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: Ah.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.name, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.group} · ${exercise.sets} × ${exercise.reps}',
                        style: textTheme.labelMedium,
                      ),
                      if (exercise.pace != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 13, color: Ah.info),
                            const SizedBox(width: 4),
                            Text(exercise.pace!,
                                style: textTheme.labelSmall
                                    ?.copyWith(color: Ah.info)),
                          ],
                        ),
                      ],
                      const SizedBox(height: Ah.s4),
                      Text(
                        exercise.cue,
                        style: textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.safety,
                        style: textTheme.labelSmall?.copyWith(color: Ah.mint),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.add_circle_outline,
                  color: selected ? Ah.accent : Ah.textTertiary,
                ),
              ],
            ),
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
  final IconData icon;

  /// 'gym' or 'running' — drives which activity type the session logs as, so
  /// calorie burn is estimated against the right MET.
  final String category;

  /// Optional pace guidance for running workouts (e.g. "5:30-6:30 /km").
  final String? pace;

  const _Exercise({
    required this.name,
    required this.group,
    required this.sets,
    required this.reps,
    required this.safety,
    required this.cue,
    required this.icon,
    this.category = 'gym',
    this.pace,
  });
}
