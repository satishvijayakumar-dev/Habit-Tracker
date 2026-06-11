import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';

class PathOnboardingScreen extends StatefulWidget {
  const PathOnboardingScreen({super.key});

  @override
  State<PathOnboardingScreen> createState() => _PathOnboardingScreenState();
}

class _PathOnboardingScreenState extends State<PathOnboardingScreen> {
  int _step = 0;
  final Map<int, _AnswerOption> _answers = {};
  _Persona? _result;
  bool _saving = false;

  static const _questions = [
    _Question(
      title: 'Which routine looks most like your life right now?',
      subtitle: 'This helps ActivHealth choose loops that fit your day.',
      answers: [
        _AnswerOption(
          label: 'Gym or training focused',
          description: 'My day works better when exercise leads the plan.',
          personaKey: 'gym',
          icon: Icons.fitness_center,
        ),
        _AnswerOption(
          label: 'Office going',
          description: 'Commute, desk time, meetings, and packed days.',
          personaKey: 'office',
          icon: Icons.business_center_outlined,
        ),
        _AnswerOption(
          label: 'Home or remote worker',
          description: 'I need boundaries between work, food, and rest.',
          personaKey: 'remote',
          icon: Icons.home_work_outlined,
        ),
        _AnswerOption(
          label: 'Normal mixed routine',
          description: 'A bit of everything, and I want simple consistency.',
          personaKey: 'balanced',
          icon: Icons.balance_outlined,
        ),
      ],
    ),
    _Question(
      title: 'What should your first loops improve?',
      subtitle: 'Pick the outcome you want to feel first.',
      answers: [
        _AnswerOption(
          label: 'Strength and energy',
          description: 'Movement, hydration, recovery, and gym readiness.',
          personaKey: 'gym',
          icon: Icons.bolt_outlined,
        ),
        _AnswerOption(
          label: 'Focus at work',
          description: 'Deep work, meeting resets, and end-of-day shutdown.',
          personaKey: 'office',
          icon: Icons.center_focus_strong_outlined,
        ),
        _AnswerOption(
          label: 'Home-work boundaries',
          description: 'Start rituals, breaks, meals, and screen limits.',
          personaKey: 'remote',
          icon: Icons.door_front_door_outlined,
        ),
        _AnswerOption(
          label: 'Better everyday rhythm',
          description: 'Small wins that make the whole day calmer.',
          personaKey: 'balanced',
          icon: Icons.route_outlined,
        ),
      ],
    ),
    _Question(
      title: 'What usually breaks your routine?',
      subtitle: 'Your fallback loops will be designed around this.',
      answers: [
        _AnswerOption(
          label: 'Low energy',
          description: 'I need a tiny version when motivation drops.',
          personaKey: 'gym',
          icon: Icons.battery_2_bar_outlined,
        ),
        _AnswerOption(
          label: 'Back-to-back work',
          description: 'I forget basics when my calendar fills up.',
          personaKey: 'office',
          icon: Icons.event_busy_outlined,
        ),
        _AnswerOption(
          label: 'No clear separation',
          description: 'Work, breaks, food, and rest blend together.',
          personaKey: 'remote',
          icon: Icons.blur_on_outlined,
        ),
        _AnswerOption(
          label: 'Too many goals',
          description: 'I want fewer loops that I can actually keep.',
          personaKey: 'balanced',
          icon: Icons.filter_3_outlined,
        ),
      ],
    ),
    _Question(
      title: 'How should food and daily basics be handled?',
      subtitle: 'ActivHealth uses routine prompts, not medical diet advice.',
      answers: [
        _AnswerOption(
          label: 'Fuel training',
          description:
              'Remind me to prep simple food and hydration around workouts.',
          personaKey: 'gym',
          icon: Icons.restaurant_menu_outlined,
        ),
        _AnswerOption(
          label: 'Office-friendly basics',
          description: 'Desk water, packed snacks, and a lunch cue.',
          personaKey: 'office',
          icon: Icons.lunch_dining_outlined,
        ),
        _AnswerOption(
          label: 'Home grazing control',
          description: 'Make meals intentional when the kitchen is nearby.',
          personaKey: 'remote',
          icon: Icons.kitchen_outlined,
        ),
        _AnswerOption(
          label: 'Keep it simple',
          description:
              'Hydration, one mindful meal cue, and no complicated plan.',
          personaKey: 'balanced',
          icon: Icons.water_drop_outlined,
        ),
      ],
    ),
  ];

  static const _personas = {
    'gym': _Persona(
      key: 'gym',
      name: 'Gym-Focused',
      description:
          'Loops for training readiness, energy, hydration, and recovery.',
      icon: Icons.fitness_center,
      color: Colors.teal,
    ),
    'office': _Persona(
      key: 'office',
      name: 'Office Professional',
      description:
          'Loops for desk energy, work focus, meals, and shutdown rituals.',
      icon: Icons.business_center_outlined,
      color: Colors.blue,
    ),
    'remote': _Persona(
      key: 'remote',
      name: 'Remote Worker',
      description:
          'Loops for home-work boundaries, movement, food cues, and screen resets.',
      icon: Icons.home_work_outlined,
      color: Colors.indigo,
    ),
    'balanced': _Persona(
      key: 'balanced',
      name: 'Balanced Everyday',
      description:
          'Loops for simple consistency across health, focus, and calm.',
      icon: Icons.balance_outlined,
      color: Colors.green,
    ),
  };

  void _select(_AnswerOption answer) {
    setState(() {
      _answers[_step] = answer;
      if (_step < _questions.length - 1) {
        _step++;
      } else {
        _result = _scorePersona();
      }
    });
  }

  _Persona _scorePersona() {
    final scores = {for (final key in _personas.keys) key: 0};
    for (final answer in _answers.values) {
      scores[answer.personaKey] = (scores[answer.personaKey] ?? 0) + 1;
    }
    final best = scores.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    return _personas[best.key]!;
  }

  Future<void> _finish({required bool addStarterLoops}) async {
    if (_saving) return;
    setState(() => _saving = true);

    final persona = _result ?? _personas['balanced']!;
    final provider = context.read<HabitProvider>();
    await provider.setSelectedPath(persona.name);
    if (addStarterLoops) {
      for (final habit in _starterLoops(persona)) {
        await provider.addHabit(habit);
      }
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  Future<void> _selfGuided() async {
    if (_saving) return;
    setState(() => _saving = true);
    await context.read<HabitProvider>().setSelectedPath('Self-guided');
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  List<Habit> _starterLoops(_Persona persona) {
    final now = DateTime.now();
    switch (persona.key) {
      case 'gym':
        return [
          Habit(
            name: 'Pack training gear',
            description: 'Remove friction before the workout window.',
            colorName: 'green',
            iconName: 'fitness_center',
            createdAt: now,
            anchor: 'After dinner',
            fallbackBehavior: 'Put shoes by the door',
            celebration: 'I am ready before the day starts',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Drink water before caffeine',
            description: 'A simple hydration cue, not a diet plan.',
            colorName: 'blue',
            iconName: 'water_drop',
            createdAt: now,
            anchor: 'After I wake up',
            fallbackBehavior: 'Take three sips',
            celebration: 'That is my first health vote',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Recovery walk',
            description: 'Keep momentum on non-training days.',
            colorName: 'orange',
            iconName: 'directions_walk',
            createdAt: now,
            anchor: 'After lunch',
            fallbackBehavior: 'Walk for two minutes',
            celebration: 'I kept the chain alive',
            pathName: persona.name,
            difficulty: 'manageable',
          ),
        ];
      case 'office':
        return [
          Habit(
            name: 'Desk water reset',
            description: 'A visible cue for basic energy at work.',
            colorName: 'blue',
            iconName: 'water_drop',
            createdAt: now,
            anchor: 'When I sit at my desk',
            fallbackBehavior: 'Fill half a bottle',
            celebration: 'I set up my day',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Two-minute meeting reset',
            description: 'Protect focus between calendar blocks.',
            colorName: 'purple',
            iconName: 'self_improvement',
            createdAt: now,
            anchor: 'After a meeting ends',
            fallbackBehavior: 'Take three slow breaths',
            celebration: 'I reclaimed my attention',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Plan tomorrow shutdown',
            description: 'Close the day with one clear next action.',
            colorName: 'green',
            iconName: 'edit_note',
            createdAt: now,
            anchor: 'Before closing the laptop',
            fallbackBehavior: 'Write one next task',
            celebration: 'Work is parked',
            pathName: persona.name,
            difficulty: 'manageable',
          ),
        ];
      case 'remote':
        return [
          Habit(
            name: 'Start-work boundary',
            description: 'Tell your brain the workday has started.',
            colorName: 'purple',
            iconName: 'laptop_mac',
            createdAt: now,
            anchor: 'After opening my laptop',
            fallbackBehavior: 'Write today\'s first task',
            celebration: 'I am in work mode',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Kitchen pause',
            description: 'Make home food choices more intentional.',
            colorName: 'orange',
            iconName: 'restaurant',
            createdAt: now,
            anchor: 'Before opening the kitchen cupboard',
            fallbackBehavior: 'Drink water and wait one minute',
            celebration: 'I chose with intention',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Screen break walk',
            description: 'Add movement without leaving the house for long.',
            colorName: 'green',
            iconName: 'directions_walk',
            createdAt: now,
            anchor: 'After two focus blocks',
            fallbackBehavior: 'Stand up and stretch',
            celebration: 'I reset my body',
            pathName: persona.name,
            difficulty: 'manageable',
          ),
        ];
      default:
        return [
          Habit(
            name: 'Morning water',
            description: 'Start with one tiny health vote.',
            colorName: 'blue',
            iconName: 'water_drop',
            createdAt: now,
            anchor: 'After I wake up',
            fallbackBehavior: 'Take three sips',
            celebration: 'That counts',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'One focus block',
            description: 'Make progress visible without overplanning.',
            colorName: 'purple',
            iconName: 'center_focus_strong',
            createdAt: now,
            anchor: 'After breakfast or first coffee',
            fallbackBehavior: 'Work for five minutes',
            celebration: 'I started before waiting to feel ready',
            pathName: persona.name,
            difficulty: 'manageable',
          ),
          Habit(
            name: 'Evening reset',
            description: 'A small close-down ritual for tomorrow.',
            colorName: 'green',
            iconName: 'bedtime',
            createdAt: now,
            anchor: 'Before I charge my phone',
            fallbackBehavior: 'Put one thing back in place',
            celebration: 'Tomorrow is easier now',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) {
      return _PersonaResultScreen(
        persona: result,
        saving: _saving,
        onUseStarterLoops: () => _finish(addStarterLoops: true),
        onCreateOwn: () => _finish(addStarterLoops: false),
        onBack: () => setState(() => _result = null),
      );
    }

    final question = _questions[_step];
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
            Text(
              'Question ${_step + 1} of ${_questions.length}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              question.title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              question.subtitle,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 22),
            ...question.answers.map(
              (answer) => _AnswerCard(
                answer: answer,
                selected: _answers[_step] == answer,
                onTap: () => _select(answer),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _saving ? null : _selfGuided,
              child: const Text('Skip and follow my own instructions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final _AnswerOption answer;
  final bool selected;
  final VoidCallback onTap;

  const _AnswerCard({
    required this.answer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  answer.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      answer.description,
                      style:
                          TextStyle(color: Colors.grey.shade700, height: 1.3),
                    ),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonaResultScreen extends StatelessWidget {
  final _Persona persona;
  final bool saving;
  final VoidCallback onUseStarterLoops;
  final VoidCallback onCreateOwn;
  final VoidCallback onBack;

  const _PersonaResultScreen({
    required this.persona,
    required this.saving,
    required this.onUseStarterLoops,
    required this.onCreateOwn,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            IconButton(
              alignment: Alignment.centerLeft,
              onPressed: saving ? null : onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: persona.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(persona.icon, color: persona.color, size: 42),
                  const SizedBox(height: 14),
                  const Text(
                    'Your ActivHealth persona',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    persona.name,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    persona.description,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ActivHealth can start with three suggested loops, or you can ignore the suggestions and create your own.',
              style: TextStyle(height: 1.35),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : onUseStarterLoops,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(saving ? 'Setting up...' : 'Use suggested loops'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: saving ? null : onCreateOwn,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('I will create my own loops'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Question {
  final String title;
  final String subtitle;
  final List<_AnswerOption> answers;

  const _Question({
    required this.title,
    required this.subtitle,
    required this.answers,
  });
}

class _AnswerOption {
  final String label;
  final String description;
  final String personaKey;
  final IconData icon;

  const _AnswerOption({
    required this.label,
    required this.description,
    required this.personaKey,
    required this.icon,
  });
}

class _Persona {
  final String key;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const _Persona({
    required this.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
