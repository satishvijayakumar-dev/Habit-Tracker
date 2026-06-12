import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  String _energy = 'Steady';
  String _soreness = 'Low';
  String _time = '30 min';
  String _mood = 'Focused';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final profile = provider.profile;
    final plan = provider.weeklyExercisePlan;
    final missed = provider.missedPlannedSessionsThisWeek;
    final activeMinutes = provider.activeMinutesThisWeek;
    final coachLine = _coachLine(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _CoachHero(
            persona: provider.selectedPath ?? 'ActivHealth',
            goal: profile?.fitnessGoal ?? 'Build consistency',
            minutes: activeMinutes,
            points: provider.starPoints,
          ),
          const SizedBox(height: 16),
          if (profile == null)
            _CompleteProfileCard()
          else
            _DailyCheckIn(
              energy: _energy,
              soreness: _soreness,
              time: _time,
              mood: _mood,
              onEnergy: (value) => setState(() => _energy = value),
              onSoreness: (value) => setState(() => _soreness = value),
              onTime: (value) => setState(() => _time = value),
              onMood: (value) => setState(() => _mood = value),
            ),
          const SizedBox(height: 16),
          _TrainerMessage(message: coachLine),
          const SizedBox(height: 16),
          _TodaySessionCard(
            title: _sessionTitle(provider),
            detail: _sessionDetail(provider),
            missed: missed,
            onStart: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutScreen()),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This week',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ...plan.asMap().entries.map(
                (entry) => _PlanStep(
                  index: entry.key + 1,
                  text: entry.value,
                  completed: entry.key < provider.activitySessionsThisWeek,
                ),
              ),
          const SizedBox(height: 16),
          _SafetyCard(soreness: _soreness),
        ],
      ),
    );
  }

  String _coachLine(HabitProvider provider) {
    if (_soreness == 'High') {
      return 'I am switching you to recovery mode today. Mobility, walking, hydration, and sleep protect the long game.';
    }
    if (_energy == 'Low') {
      return 'Low energy logged. Your minimum effective dose is enough: $_time of easy work, then stop with confidence.';
    }
    if (provider.missedPlannedSessionsThisWeek > 0) {
      return 'You missed a planned session. No drama. I will rebalance the week so the next session matters.';
    }
    if ((provider.profile?.fitnessGoal ?? '')
        .toLowerCase()
        .contains('strength')) {
      return 'Strength focus confirmed. Today we protect form first, then add volume only if energy stays steady.';
    }
    return 'You are ready for a focused session. I will keep it realistic for your time, energy, soreness, and goal.';
  }

  String _sessionTitle(HabitProvider provider) {
    final goal = provider.profile?.fitnessGoal.toLowerCase() ?? '';
    if (_soreness == 'High') return 'Recovery session';
    if (goal.contains('run')) return 'Run/walk progression';
    if (goal.contains('strength') ||
        (provider.selectedPath ?? '').contains('Gym')) {
      return 'Strength trainer session';
    }
    return 'Full-body consistency session';
  }

  String _sessionDetail(HabitProvider provider) {
    if (_soreness == 'High') {
      return 'Easy mobility, light walk, no heavy loading. Rate pain before doing more.';
    }
    if (_time == '15 min') {
      return 'Short plan: warm up, two focused exercises, one easy finish.';
    }
    return 'Warm up, main block, simple finisher, then log how it felt.';
  }
}

class _CoachHero extends StatelessWidget {
  final String persona;
  final String goal;
  final int minutes;
  final int points;

  const _CoachHero({
    required this.persona,
    required this.goal,
    required this.minutes,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFFFB74D), Color(0xFF26A69A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.favorite, color: Color(0xFFE53935)),
              ),
              SizedBox(width: 10),
              Text(
                'ActivHealth Trainer',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            persona,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            goal,
            style: const TextStyle(color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroPill(label: 'Minutes', value: '$minutes'),
              const SizedBox(width: 10),
              _HeroPill(label: 'Star points', value: '$points'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_add_alt),
        title: const Text('Complete your trainer profile'),
        subtitle: const Text(
            'Age, body metrics, goal, and City/Town power better coaching.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
    );
  }
}

class _DailyCheckIn extends StatelessWidget {
  final String energy;
  final String soreness;
  final String time;
  final String mood;
  final ValueChanged<String> onEnergy;
  final ValueChanged<String> onSoreness;
  final ValueChanged<String> onTime;
  final ValueChanged<String> onMood;

  const _DailyCheckIn({
    required this.energy,
    required this.soreness,
    required this.time,
    required this.mood,
    required this.onEnergy,
    required this.onSoreness,
    required this.onTime,
    required this.onMood,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily check-in',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _ChoiceRow(
              label: 'Energy',
              values: const ['Low', 'Steady', 'High'],
              selected: energy,
              onChanged: onEnergy,
            ),
            _ChoiceRow(
              label: 'Soreness',
              values: const ['Low', 'Medium', 'High'],
              selected: soreness,
              onChanged: onSoreness,
            ),
            _ChoiceRow(
              label: 'Time',
              values: const ['15 min', '30 min', '45 min'],
              selected: time,
              onChanged: onTime,
            ),
            _ChoiceRow(
              label: 'Mood',
              values: const ['Tired', 'Focused', 'Driven'],
              selected: mood,
              onChanged: onMood,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final String label;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChoiceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: values
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: selected == value,
                    onSelected: (_) => onChanged(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TrainerMessage extends StatelessWidget {
  final String message;

  const _TrainerMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF101828),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE53935),
              child: Icon(Icons.favorite, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coach says',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySessionCard extends StatelessWidget {
  final String title;
  final String detail;
  final int missed;
  final VoidCallback onStart;

  const _TodaySessionCard({
    required this.title,
    required this.detail,
    required this.missed,
    required this.onStart,
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
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.play_arrow, color: Color(0xFFE53935)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        missed == 0
                            ? 'On track'
                            : '$missed session${missed == 1 ? "" : "s"} to rebalance',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(detail, style: const TextStyle(height: 1.35)),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Open today workout'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanStep extends StatelessWidget {
  final int index;
  final String text;
  final bool completed;

  const _PlanStep({
    required this.index,
    required this.text,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              completed ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
          child: Icon(
            completed ? Icons.check : Icons.calendar_today,
            color:
                completed ? const Color(0xFF15803D) : const Color(0xFF2563EB),
          ),
        ),
        title: Text('Session $index'),
        subtitle: Text(text),
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final String soreness;

  const _SafetyCard({required this.soreness});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: soreness == 'High' ? const Color(0xFFFFF1F2) : null,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety_outlined, color: Color(0xFFE53935)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Safety first: stop for sharp pain, chest pain, dizziness, or unusual breathlessness. ActivHealth gives coaching support, not medical diagnosis.',
                style: TextStyle(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
