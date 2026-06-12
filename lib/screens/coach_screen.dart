import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';

/// The coach: one daily check-in, one message, one session, one week view.
/// Rule-based guidance today (labelled honestly), staged for a real
/// LLM coach once the backend lands — check-ins are persisted so the
/// future model has history to work with.
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
  bool _restoredFromToday = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final profile = provider.profile;
    final textTheme = Theme.of(context).textTheme;

    // Restore today's saved check-in once, so the coach remembers.
    if (!_restoredFromToday && provider.hasCheckedInToday) {
      final saved = provider.todayCheckIn;
      _energy = saved['energy'] ?? _energy;
      _soreness = saved['soreness'] ?? _soreness;
      _time = saved['time'] ?? _time;
      _mood = saved['mood'] ?? _mood;
      _restoredFromToday = true;
    }

    final coachLine = _coachLine(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach'),
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
        padding:
            const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          // -- Coach identity --
          Row(
            children: [
              const _CoachOrb(),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your coach', style: textTheme.titleLarge),
                    Text(
                      profile == null
                          ? 'Tuned to your path'
                          : 'Tuned to ${provider.selectedPath ?? "your path"} · ${profile.fitnessGoal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Ah.s16),

          if (profile == null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_add_alt, color: Ah.accent),
                title: const Text('Complete your profile'),
                subtitle: const Text(
                    'Age, body metrics, and your goal sharpen every recommendation.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ),
            const SizedBox(height: Ah.s16),
          ],

          // -- Daily check-in --
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Ah.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Daily check-in',
                            style: textTheme.titleMedium),
                      ),
                      if (provider.hasCheckedInToday)
                        const Icon(Icons.check_circle,
                            color: Ah.mint, size: 18),
                    ],
                  ),
                  const SizedBox(height: Ah.s12),
                  _ChoiceRow(
                    label: 'Energy',
                    values: const ['Low', 'Steady', 'High'],
                    selected: _energy,
                    onChanged: (v) => _saveCheckIn(provider, energy: v),
                  ),
                  _ChoiceRow(
                    label: 'Soreness',
                    values: const ['Low', 'Medium', 'High'],
                    selected: _soreness,
                    onChanged: (v) => _saveCheckIn(provider, soreness: v),
                  ),
                  _ChoiceRow(
                    label: 'Time',
                    values: const ['15 min', '30 min', '45 min'],
                    selected: _time,
                    onChanged: (v) => _saveCheckIn(provider, time: v),
                  ),
                  _ChoiceRow(
                    label: 'Mood',
                    values: const ['Tired', 'Focused', 'Driven'],
                    selected: _mood,
                    onChanged: (v) => _saveCheckIn(provider, mood: v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Ah.s16),

          // -- Coach message (types in) --
          _CoachMessage(message: coachLine),
          const SizedBox(height: Ah.s16),

          // -- Today's session: one primary CTA --
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Ah.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sessionTitle(provider),
                      style: textTheme.titleMedium),
                  const SizedBox(height: Ah.s4),
                  Text(
                    _sessionDetail(provider),
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Ah.textSecondary),
                  ),
                  const SizedBox(height: Ah.s16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const WorkoutScreen()),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start session'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Ah.s24),

          // -- This week as a 7-dot strip --
          Text('This week', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s12),
          _WeekStrip(
            done: provider.activitySessionsThisWeek,
            target: provider.activitySessionsThisWeek +
                provider.missedPlannedSessionsThisWeek,
          ),
          const SizedBox(height: Ah.s8),
          ...provider.weeklyExercisePlan.asMap().entries.map(
                (entry) => _PlanStep(
                  index: entry.key + 1,
                  text: entry.value,
                  completed:
                      entry.key < provider.activitySessionsThisWeek,
                ),
              ),
          const SizedBox(height: Ah.s24),

          // -- Topics --
          Text('Coach topics', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s12),
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Ah.tint(Ah.mint),
                  borderRadius: BorderRadius.circular(Ah.rSm),
                ),
                child:
                    const Icon(Icons.restaurant, color: Ah.mint, size: 20),
              ),
              title: const Text('Fuel'),
              subtitle:
                  const Text('Protein target and simple eating guidance'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NutritionScreen()),
              ),
            ),
          ),
          const SizedBox(height: Ah.s24),

          // -- Safety: one quiet line, details behind a tap --
          Center(
            child: TextButton.icon(
              onPressed: () => _showSafetySheet(context),
              icon: const Icon(Icons.health_and_safety_outlined,
                  size: 16, color: Ah.textTertiary),
              label: Text(
                'Coaching support, not medical advice',
                style: textTheme.labelSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveCheckIn(
    HabitProvider provider, {
    String? energy,
    String? soreness,
    String? time,
    String? mood,
  }) {
    HapticFeedback.selectionClick();
    setState(() {
      _energy = energy ?? _energy;
      _soreness = soreness ?? _soreness;
      _time = time ?? _time;
      _mood = mood ?? _mood;
    });
    provider.saveCheckIn(
      energy: _energy,
      soreness: _soreness,
      time: _time,
      mood: _mood,
    );
  }

  String _coachLine(HabitProvider provider) {
    final name =
        provider.userName.isEmpty ? '' : '${provider.userName}, ';
    if (_soreness == 'High') {
      return '${name}recovery mode today. Mobility, walking, hydration, and sleep protect the long game.';
    }
    if (_energy == 'Low' || _mood == 'Tired') {
      return '${name}low battery noted. Your minimum effective dose is enough: $_time of easy work, then stop with confidence.';
    }
    if (provider.missedPlannedSessionsThisWeek > 0) {
      return '${name}you have an open session this week. No drama — make the next one count and the week still wins.';
    }
    if (_mood == 'Driven') {
      return '${name}you came to play today. We\'ll use that: full session, quality reps, and finish strong.';
    }
    if ((provider.profile?.fitnessGoal ?? '')
        .toLowerCase()
        .contains('strength')) {
      return '${name}strength focus confirmed. Form first, then volume — only if energy stays steady.';
    }
    return '${name}you\'re set for a focused $_time session, tuned to your energy and goal.';
  }

  String _sessionTitle(HabitProvider provider) {
    final goal = provider.profile?.fitnessGoal.toLowerCase() ?? '';
    if (_soreness == 'High') return 'Recovery session';
    if (goal.contains('run')) return 'Run/walk progression';
    if (goal.contains('strength') ||
        (provider.selectedPath ?? '').contains('Gym')) {
      return 'Strength session';
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

  void _showSafetySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Safety first', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: Ah.s12),
            Text(
              'Stop immediately for sharp pain, chest pain, dizziness, or unusual breathlessness. '
              'ActivHealth gives coaching support, not medical diagnosis. '
              'If you have a health condition, check with your GP before changing your exercise routine.',
              style: Theme.of(ctx)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Ah.textSecondary, height: 1.5),
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
      padding: const EdgeInsets.only(bottom: Ah.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: Ah.s8),
          Wrap(
            spacing: Ah.s8,
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

/// Small pulsing gradient orb — the coach's visual identity.
class _CoachOrb extends StatefulWidget {
  const _CoachOrb();

  @override
  State<_CoachOrb> createState() => _CoachOrbState();
}

class _CoachOrbState extends State<_CoachOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (!WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = 0.15 + _controller.value * 0.20;
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: Ah.brandGradient,
            shape: BoxShape.circle,
            boxShadow: Ah.accentGlow(opacity: pulse),
          ),
          child: const Icon(Icons.psychology_alt,
              color: Ah.onAccent, size: 24),
        );
      },
    );
  }
}

/// Coach reply that types in when the message changes.
class _CoachMessage extends StatelessWidget {
  final String message;

  const _CoachMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Container(
      padding: const EdgeInsets.all(Ah.s16),
      decoration: BoxDecoration(
        color: Ah.surface2,
        borderRadius: BorderRadius.circular(Ah.rLg),
        border: Border.all(color: Ah.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COACH',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Ah.accent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: Ah.s8),
          TweenAnimationBuilder<double>(
            key: ValueKey(message),
            tween: Tween(begin: 0, end: 1),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, t, _) {
              final chars = (message.length * t).round();
              return Text(
                message.substring(0, chars),
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.5),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final int done;
  final int target;

  const _WeekStrip({required this.done, required this.target});

  @override
  Widget build(BuildContext context) {
    final total = target.clamp(1, 7);
    return Row(
      children: List.generate(7, (i) {
        final isPlanned = i < total;
        final isDone = i < done;
        return Expanded(
          child: Container(
            height: 10,
            margin: EdgeInsets.only(right: i == 6 ? 0 : Ah.s8),
            decoration: BoxDecoration(
              color: isDone
                  ? Ah.mint
                  : isPlanned
                      ? Ah.surface3
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(Ah.rSm),
              border: Border.all(
                color: isDone ? Ah.mint : Ah.hairline,
              ),
            ),
          ),
        );
      }),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: Ah.s8),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: completed ? Ah.tint(Ah.mint) : Ah.surface3,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : Icons.calendar_today_outlined,
              size: 18,
              color: completed ? Ah.mint : Ah.textSecondary,
            ),
          ),
          title: Text('Session $index'),
          subtitle: Text(text),
        ),
      ),
    );
  }
}
