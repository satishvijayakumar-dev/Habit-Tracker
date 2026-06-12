import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

class PathOnboardingScreen extends StatefulWidget {
  const PathOnboardingScreen({super.key});

  @override
  State<PathOnboardingScreen> createState() => _PathOnboardingScreenState();
}

class _PathOnboardingScreenState extends State<PathOnboardingScreen> {
  bool _welcomed = false;
  String _name = '';
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
          label: 'Runner or walker',
          description: 'I want distance, pace, routes, and consistency.',
          personaKey: 'runner',
          icon: Icons.directions_run,
        ),
        _AnswerOption(
          label: 'Social sports',
          description: 'Badminton, football, tennis, cycling, or group play.',
          personaKey: 'social',
          icon: Icons.groups_outlined,
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
          label: 'First-time starter',
          description: 'I want confidence, safety, and a simple first plan.',
          personaKey: 'starter',
          icon: Icons.flag_outlined,
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
          label: 'Run or walk better',
          description: 'Build pace, distance, and weekly rhythm.',
          personaKey: 'runner',
          icon: Icons.route_outlined,
        ),
        _AnswerOption(
          label: 'Find active people',
          description: 'Use sport and accountability to stay consistent.',
          personaKey: 'social',
          icon: Icons.handshake_outlined,
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
          label: 'Confidence first',
          description: 'Small wins that make starting feel safe.',
          personaKey: 'starter',
          icon: Icons.verified_outlined,
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
          label: 'Weather or route friction',
          description: 'I need backup plans when I cannot get outside.',
          personaKey: 'runner',
          icon: Icons.cloud_outlined,
        ),
        _AnswerOption(
          label: 'No one to train with',
          description: 'I need people, events, or accountability.',
          personaKey: 'social',
          icon: Icons.person_search_outlined,
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
          label: 'Starting feels too big',
          description: 'I need a beginner-safe first step.',
          personaKey: 'starter',
          icon: Icons.stairs_outlined,
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
          label: 'Fuel runs and walks',
          description: 'Hydration and simple meals around movement.',
          personaKey: 'runner',
          icon: Icons.water_drop_outlined,
        ),
        _AnswerOption(
          label: 'Group-day basics',
          description: 'Food, hydration, and recovery around events.',
          personaKey: 'social',
          icon: Icons.sports_outlined,
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
          personaKey: 'starter',
          icon: Icons.water_drop_outlined,
        ),
      ],
    ),
  ];

  static const _personas = {
    'gym': _Persona(
      key: 'gym',
      name: 'The Gym Builder',
      description: 'Strength plans, form cues, recovery, and progression.',
      icon: Icons.fitness_center,
      color: Ah.accent,
    ),
    'runner': _Persona(
      key: 'runner',
      name: 'The Runner / Walker',
      description: 'Pace, distance, active minutes, and safer progression.',
      icon: Icons.directions_run,
      color: Ah.info,
    ),
    'social': _Persona(
      key: 'social',
      name: 'The Social Sports User',
      description: 'Group activity, local accountability, and shared sessions.',
      icon: Icons.groups_outlined,
      color: Color(0xFF9B8AFB),
    ),
    'office': _Persona(
      key: 'office',
      name: 'Office Professional',
      description:
          'Loops for desk energy, work focus, meals, and shutdown rituals.',
      icon: Icons.business_center_outlined,
      color: Ah.info,
    ),
    'remote': _Persona(
      key: 'remote',
      name: 'Remote Worker',
      description:
          'Loops for home-work boundaries, movement, food cues, and screen resets.',
      icon: Icons.home_work_outlined,
      color: Color(0xFF9B8AFB),
    ),
    'balanced': _Persona(
      key: 'balanced',
      name: 'Balanced Everyday',
      description:
          'Loops for simple consistency across health, focus, and calm.',
      icon: Icons.balance_outlined,
      color: Ah.mint,
    ),
    'starter': _Persona(
      key: 'starter',
      name: 'The Starter',
      description: 'Beginner-safe actions for confidence and consistency.',
      icon: Icons.flag_outlined,
      color: Ah.mint,
    ),
  };

  void _select(_AnswerOption answer) {
    HapticFeedback.selectionClick();
    setState(() {
      _answers[_step] = answer;
      if (_step < _questions.length - 1) {
        _step++;
      } else {
        HapticFeedback.mediumImpact();
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
    if (_name.isNotEmpty) {
      await provider.setUserName(_name);
    }
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
    final provider = context.read<HabitProvider>();
    if (_name.isNotEmpty) {
      await provider.setUserName(_name);
    }
    await provider.setSelectedPath('Self-guided');
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
      case 'runner':
        return [
          Habit(
            name: 'Shoes by the door',
            description: 'Make the next walk or run easier to start.',
            colorName: 'blue',
            iconName: 'directions_run',
            createdAt: now,
            anchor: 'After dinner',
            fallbackBehavior: 'Put socks and shoes together',
            celebration: 'Tomorrow already started',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Easy movement window',
            description: 'Protect one low-pressure walk or run slot.',
            colorName: 'green',
            iconName: 'route',
            createdAt: now,
            anchor: 'After work or lunch',
            fallbackBehavior: 'Walk for five minutes',
            celebration: 'I kept the rhythm',
            pathName: persona.name,
            difficulty: 'manageable',
          ),
        ];
      case 'social':
        return [
          Habit(
            name: 'Check activity group',
            description: 'Keep local accountability visible.',
            colorName: 'purple',
            iconName: 'groups',
            createdAt: now,
            anchor: 'After lunch',
            fallbackBehavior: 'Send one message or check one event',
            celebration: 'I stayed connected',
            pathName: persona.name,
            difficulty: 'tiny',
          ),
          Habit(
            name: 'Pack sport kit',
            description: 'Remove friction before a group session.',
            colorName: 'orange',
            iconName: 'sports_tennis',
            createdAt: now,
            anchor: 'Before bed',
            fallbackBehavior: 'Put one item by the door',
            celebration: 'I made showing up easier',
            pathName: persona.name,
            difficulty: 'tiny',
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
    if (!_welcomed) {
      return _WelcomeStep(
        onContinue: (name) {
          HapticFeedback.mediumImpact();
          setState(() {
            _name = name;
            _welcomed = true;
          });
        },
      );
    }

    final result = _result;
    if (result != null) {
      return _PersonaResultScreen(
        persona: result,
        name: _name,
        saving: _saving,
        onUseStarterLoops: () => _finish(addStarterLoops: true),
        onCreateOwn: () => _finish(addStarterLoops: false),
        onBack: () => setState(() => _result = null),
      );
    }

    final question = _questions[_step];
    final textTheme = Theme.of(context).textTheme;
    final progress = (_step + 1) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Ah.gutter, Ah.s24, Ah.gutter, Ah.s24),
          children: [
            // Animated progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(Ah.rSm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: Ah.s24),
            Text(
              'Question ${_step + 1} of ${_questions.length}',
              style: textTheme.labelMedium,
            ),
            const SizedBox(height: Ah.s8),
            Text(question.title, style: textTheme.headlineMedium),
            const SizedBox(height: Ah.s8),
            Text(
              question.subtitle,
              style: textTheme.bodyMedium
                  ?.copyWith(color: Ah.textSecondary, height: 1.4),
            ),
            const SizedBox(height: Ah.s24),
            ...question.answers.map(
              (answer) => _AnswerCard(
                answer: answer,
                selected: _answers[_step] == answer,
                onTap: () => _select(answer),
              ),
            ),
            const SizedBox(height: Ah.s8),
            TextButton(
              onPressed: _saving ? null : _selfGuided,
              child: Text(
                'Skip — I\'ll guide myself',
                style: textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beat 0: brand moment + name capture, before any questions.
class _WelcomeStep extends StatefulWidget {
  final ValueChanged<String> onContinue;

  const _WelcomeStep({required this.onContinue});

  @override
  State<_WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<_WelcomeStep> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Ah.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: Ah.brandGradient,
                  borderRadius: BorderRadius.circular(Ah.rLg),
                  boxShadow: Ah.accentGlow(opacity: 0.25),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Ah.rLg),
                  child: Image.asset(
                    'assets/images/activhealth_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.favorite,
                      color: Ah.onAccent,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Ah.s24),
              Text('ActivHealth', style: textTheme.displayMedium),
              const SizedBox(height: Ah.s8),
              Text(
                'Small loops. Real momentum.',
                style: textTheme.titleMedium?.copyWith(color: Ah.accent),
              ),
              const SizedBox(height: Ah.s16),
              Text(
                'A coach-led fitness companion that designs tiny behavior loops around your real life — and celebrates every one you protect.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: Ah.textSecondary, height: 1.5),
              ),
              const SizedBox(height: Ah.s32),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'What should your coach call you?',
                  hintText: 'First name',
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    widget.onContinue(_nameController.text.trim()),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Find my path'),
              ),
            ],
          ),
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
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: Ah.s8),
      decoration: BoxDecoration(
        color: Ah.surface1,
        borderRadius: BorderRadius.circular(Ah.rLg),
        border: Border.all(
          color: selected ? Ah.accent : Ah.hairline,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected ? Ah.accentGlow(opacity: 0.12) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Ah.rLg),
          child: Padding(
            padding: const EdgeInsets.all(Ah.s16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Ah.tint(Ah.accent),
                    borderRadius: BorderRadius.circular(Ah.rMd),
                  ),
                  child: Icon(answer.icon, color: Ah.accent, size: 22),
                ),
                const SizedBox(width: Ah.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(answer.label, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        answer.description,
                        style: textTheme.bodySmall?.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.chevron_right,
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

class _PersonaResultScreen extends StatelessWidget {
  final _Persona persona;
  final String name;
  final bool saving;
  final VoidCallback onUseStarterLoops;
  final VoidCallback onCreateOwn;
  final VoidCallback onBack;

  const _PersonaResultScreen({
    required this.persona,
    required this.name,
    required this.saving,
    required this.onUseStarterLoops,
    required this.onCreateOwn,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Ah.gutter, Ah.s16, Ah.gutter, Ah.s24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: saving ? null : onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(height: Ah.s16),
            // The reveal: persona glyph scales in with a glow.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => Transform.scale(
                scale: 0.8 + 0.2 * t,
                child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(Ah.s24),
                decoration: BoxDecoration(
                  color: Ah.surface2,
                  borderRadius: BorderRadius.circular(Ah.rXl),
                  border: Border.all(
                    color: persona.color.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: persona.color.withValues(alpha: 0.2),
                      blurRadius: 32,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Ah.tint(persona.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: persona.color, width: 2),
                      ),
                      child:
                          Icon(persona.icon, color: persona.color, size: 30),
                    ),
                    const SizedBox(height: Ah.s16),
                    Text(
                      name.isEmpty
                          ? 'Your path'
                          : '$name, your path is',
                      style: textTheme.labelMedium,
                    ),
                    const SizedBox(height: Ah.s4),
                    Text(persona.name, style: textTheme.headlineLarge),
                    const SizedBox(height: Ah.s8),
                    Text(
                      persona.description,
                      style: textTheme.bodyMedium?.copyWith(
                          color: Ah.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Ah.s24),
            Text(
              'Your coach can start you with three suggested loops, or you can build your own from scratch.',
              style: textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: Ah.s24),
            FilledButton.icon(
              onPressed: saving ? null : onUseStarterLoops,
              icon: const Icon(Icons.route),
              label: Text(saving ? 'Setting up…' : 'Start my first loops'),
            ),
            const SizedBox(height: Ah.s8),
            OutlinedButton.icon(
              onPressed: saving ? null : onCreateOwn,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('I\'ll create my own'),
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
