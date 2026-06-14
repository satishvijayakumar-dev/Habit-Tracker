import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/coach_brain.dart';
import '../services/community_service.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/coach_popup.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';
import 'sign_in_screen.dart';
import 'workout_screen.dart';

/// The coach: a conversational assistant (free-text chat, rule-based today,
/// LLM-ready) plus today's session, the week at a glance, and topics.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _ChatMsg {
  final String text;
  final bool fromCoach;
  const _ChatMsg(this.text, {required this.fromCoach});
}

class _CoachScreenState extends State<CoachScreen> {
  final _input = TextEditingController();
  final _community = CommunityService();
  final List<_ChatMsg> _chat = [];
  bool _seeded = false;
  bool _thinking = false;

  CoachContext _ctx(HabitProvider p) => CoachContext(
        name: p.userName,
        persona: p.selectedPath ?? '',
        goal: p.profile?.fitnessGoal ?? '',
        energy: p.todayCheckIn['energy'] ?? 'Steady',
        missedSessions: p.missedPlannedSessionsThisWeek,
        loopsRemaining: p.habits.length - p.completedTodayCount,
        dailyStreak: p.dailyActiveStreak,
      );

  Future<void> _send(HabitProvider provider) async {
    final text = _input.text.trim();
    if (text.isEmpty || _thinking) return;
    HapticFeedback.selectionClick();
    setState(() {
      _chat.add(_ChatMsg(text, fromCoach: false));
      _input.clear();
      _thinking = true;
    });

    // Try the smart server-side coach first; fall back to the on-device
    // rule-based brain when offline / signed out / unconfigured.
    final remote = await _community.coachReply(text, {
      'name': provider.userName,
      'persona': provider.selectedPath ?? '',
      'goal': provider.profile?.fitnessGoal ?? '',
      'energy': provider.todayCheckIn['energy'] ?? 'Steady',
    });
    final reply = remote ?? CoachBrain.reply(text, _ctx(provider));
    if (!mounted) return;
    setState(() {
      _chat.add(_ChatMsg(reply, fromCoach: true));
      _thinking = false;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final profile = provider.profile;
    final textTheme = Theme.of(context).textTheme;

    if (!_seeded) {
      _chat.add(_ChatMsg(_coachLine(provider), fromCoach: true));
      _seeded = true;
    }

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
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Row(
            children: [
              const CoachAvatar(size: 52),
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

          // Invite sign-in so the adaptive (LLM) coach is reachable — when
          // signed out the coach still works, just with on-device replies.
          if (!_community.isSignedIn) ...[
            _SmartCoachBanner(
              onSignIn: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
              ),
            ),
            const SizedBox(height: Ah.s16),
          ],

          // -- Conversation --
          ..._chat.map((m) => _ChatBubble(msg: m)),
          if (_thinking) const _TypingBubble(),
          const SizedBox(height: Ah.s8),
          _ChatInput(controller: _input, onSend: () => _send(provider)),
          const SizedBox(height: Ah.s8),
          _SuggestionChips(onTap: (s) {
            _input.text = s;
            _send(provider);
          }),
          const SizedBox(height: Ah.s24),

          // Today's session.
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Ah.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sessionTitle(provider), style: textTheme.titleMedium),
                  const SizedBox(height: Ah.s4),
                  Text(_sessionDetail(provider),
                      style: textTheme.bodyMedium
                          ?.copyWith(color: Ah.textSecondary)),
                  const SizedBox(height: Ah.s16),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start session'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Ah.s24),

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
                  completed: entry.key < provider.activitySessionsThisWeek,
                ),
              ),
          const SizedBox(height: Ah.s24),

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
                child: const Icon(Icons.restaurant, color: Ah.mint, size: 20),
              ),
              title: const Text('Fuel'),
              subtitle: const Text('Calorie & protein targets + natural foods'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NutritionScreen()),
              ),
            ),
          ),
          const SizedBox(height: Ah.s24),

          Center(
            child: TextButton.icon(
              onPressed: () => _showSafetySheet(context),
              icon: const Icon(Icons.health_and_safety_outlined,
                  size: 16, color: Ah.textTertiary),
              label: Text('Coaching support, not medical advice',
                  style: textTheme.labelSmall),
            ),
          ),
        ],
      ),
    );
  }

  String _coachLine(HabitProvider provider) {
    final name = provider.userName.isEmpty ? '' : '${provider.userName}, ';
    final c = provider.todayCheckIn;
    final energy = c['energy'] ?? 'Steady';
    final soreness = c['soreness'] ?? 'Low';
    final mood = c['mood'] ?? 'Focused';
    final time = c['time'] ?? '30 min';
    if (soreness == 'High') {
      return '${name}recovery mode today. Mobility, walking, hydration and sleep protect the long game. Ask me to adjust anything.';
    }
    if (energy == 'Low' || mood == 'Tired') {
      return '${name}low battery noted. Your minimum effective dose is enough: $time of easy work. Tell me your time or energy and I\'ll adapt.';
    }
    if (provider.missedPlannedSessionsThisWeek > 0) {
      return '${name}you have an open session this week. Make the next one count — ask me to make it shorter or easier if needed.';
    }
    return '${name}you\'re set for a focused session. Ask me anything — time, difficulty, swaps, injuries, or food.';
  }

  String _sessionTitle(HabitProvider provider) {
    final goal = provider.profile?.fitnessGoal.toLowerCase() ?? '';
    if (provider.todayCheckIn['soreness'] == 'High') return 'Recovery session';
    if (goal.contains('run')) return 'Run/walk progression';
    if (goal.contains('strength') ||
        (provider.selectedPath ?? '').contains('Gym')) {
      return 'Strength session';
    }
    return 'Full-body consistency session';
  }

  String _sessionDetail(HabitProvider provider) {
    if (provider.todayCheckIn['soreness'] == 'High') {
      return 'Easy mobility, light walk, no heavy loading. Rate pain before doing more.';
    }
    return 'Warm up, main block, simple finisher, then log how it felt.';
  }

  void _showSafetySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
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

class _ChatBubble extends StatelessWidget {
  final _ChatMsg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final coach = msg.fromCoach;
    return Align(
      alignment: coach ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: Ah.s8),
        padding:
            const EdgeInsets.symmetric(horizontal: Ah.s12, vertical: Ah.s12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: coach ? Ah.surface2 : Ah.accent,
          borderRadius: BorderRadius.circular(Ah.rLg),
          border: coach ? Border.all(color: Ah.hairline) : null,
        ),
        child: Text(
          msg.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: coach ? Ah.textPrimary : Ah.onAccent,
                height: 1.45,
              ),
        ),
      ),
    );
  }
}

/// Sign-in invite shown on the Coach tab when signed out. The coach still
/// answers on-device; signing in unlocks the smarter, adaptive (LLM) replies.
class _SmartCoachBanner extends StatelessWidget {
  final VoidCallback onSignIn;
  const _SmartCoachBanner({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Ah.s16),
      decoration: BoxDecoration(
        gradient: Ah.brandGradient,
        borderRadius: BorderRadius.circular(Ah.rLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Ah.onAccent, size: 22),
          const SizedBox(width: Ah.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unlock your smart coach',
                    style: textTheme.titleSmall?.copyWith(color: Ah.onAccent)),
                const SizedBox(height: 2),
                Text(
                  'Sign in and the coach adapts to whatever you tell it — your time, energy, injuries, even the food in your cupboard.',
                  style: textTheme.labelMedium?.copyWith(
                    color: Ah.onAccent.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: Ah.s12),
                FilledButton(
                  onPressed: onSignIn,
                  style: FilledButton.styleFrom(
                    backgroundColor: Ah.onAccent,
                    foregroundColor: Ah.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "coach is typing…" placeholder shown while the AI reply is in
/// flight. Styled like a coach bubble so the wait feels conversational.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: Ah.s8),
        padding:
            const EdgeInsets.symmetric(horizontal: Ah.s12, vertical: Ah.s12),
        decoration: BoxDecoration(
          color: Ah.surface2,
          borderRadius: BorderRadius.circular(Ah.rLg),
          border: Border.all(color: Ah.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Ah.textSecondary),
              ),
            ),
            const SizedBox(width: Ah.s8),
            Text('Coach is thinking…',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Ah.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _ChatInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: const InputDecoration(
              hintText: 'Ask your coach…',
            ),
          ),
        ),
        const SizedBox(width: Ah.s8),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: Ah.accent,
            foregroundColor: Ah.onAccent,
          ),
          onPressed: onSend,
          icon: const Icon(Icons.send),
        ),
      ],
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _SuggestionChips({required this.onTap});

  static const _suggestions = [
    'I only have 20 minutes',
    'My knees hurt',
    'Make it easier',
    'What should I eat?',
    'Plan my day',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Ah.s8,
      runSpacing: Ah.s8,
      children: _suggestions
          .map((s) => ActionChip(
                label: Text(s),
                onPressed: () => onTap(s),
              ))
          .toList(),
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
              border: Border.all(color: isDone ? Ah.mint : Ah.hairline),
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
  const _PlanStep(
      {required this.index, required this.text, required this.completed});

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
