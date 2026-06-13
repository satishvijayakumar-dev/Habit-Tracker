import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/coach_popup.dart';
import '../widgets/habit_tile.dart';
import '../widgets/insights.dart';
import '../widgets/momentum_ring.dart';
import 'activity_log_screen.dart';
import 'add_edit_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'nutrition_screen.dart';
import 'paywall_screen.dart';
import 'settings_screen.dart';
import 'workout_screen.dart';

/// The day, on one screen: persona Focus banner (what to do) → Momentum Ring
/// (progress) → tappable stats (detail) → 1-tap loops (do). The coach greets
/// the user in a pop-up on open instead of a static card.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      maybeShowCoachOnOpen(context, context.read<HabitProvider>());
    });
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Morning'
        : hour < 18
            ? 'Afternoon'
            : 'Evening';
    return name.isEmpty ? '$part.' : '$part, $name.';
  }

  void _addLoop() {
    final provider = context.read<HabitProvider>();
    if (!provider.canAddLoop) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddEditHabitScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final textTheme = Theme.of(context).textTheme;
    final dateString = DateFormat('EEEE d MMMM').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Ah.gutter, Ah.s12, Ah.gutter, Ah.s48 + Ah.s32),
          children: [
            // -- Header --
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateString, style: textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(_greeting(provider.userName),
                          style: textTheme.headlineMedium),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Ah.s16),

            // -- Persona Focus banner --
            _FocusBanner(
              persona: provider.selectedPath ?? 'Your plan',
              summary: _focusSummary(provider),
              onLog: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActivityLogScreen()),
              ),
              onSession: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutScreen()),
              ),
              onFuel: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NutritionScreen()),
              ),
            ),
            const SizedBox(height: Ah.s24),

            // -- Momentum Ring --
            Center(
              child: MomentumRing(
                loopsDone: provider.completedTodayCount,
                loopsTotal: habits.length,
                activeMinutes: provider.activeMinutesThisWeek,
                minutesTarget: provider.weeklyMinutesTarget,
                size: 190,
              ),
            ),
            const SizedBox(height: Ah.s24),

            // -- Tappable stats (now interactive) --
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Active min',
                    value: provider.activeMinutesThisWeek,
                    unit: 'min',
                    icon: Icons.bolt,
                    accent: Ah.info,
                    onTap: () => showActiveMinutesInsight(context, provider),
                  ),
                ),
                const SizedBox(width: Ah.s12),
                Expanded(
                  child: StatCard(
                    label: 'Sessions',
                    value: provider.activitySessionsThisWeek,
                    unit: 'sessions',
                    icon: Icons.event_available,
                    accent: Ah.warning,
                    onTap: () => showSessionsInsight(context, provider),
                  ),
                ),
                const SizedBox(width: Ah.s12),
                Expanded(
                  child: StatCard(
                    label: 'Star points',
                    value: provider.starPoints,
                    unit: 'points',
                    icon: Icons.star,
                    accent: Ah.accent,
                    onTap: () => showStarPointsInsight(context, provider),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Ah.s24),

            // -- Loops --
            Row(
              children: [
                Expanded(
                    child: Text("Today's loops", style: textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: _addLoop,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New loop'),
                ),
              ],
            ),
            const SizedBox(height: Ah.s8),
            if (habits.isEmpty)
              _EmptyState(onAdd: _addLoop)
            else
              ..._sortedHabits(provider).map(
                (habit) => HabitTile(
                  habit: habit,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HabitDetailScreen(habitId: habit.id!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        heroTag: 'today_fab',
        backgroundColor: Ah.accent,
        foregroundColor: Ah.onAccent,
        tooltip: 'Log activity',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ActivityLogScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Persona-aware one-liner: what to do + where they're lacking.
  String _focusSummary(HabitProvider p) {
    final remaining = p.habits.length - p.completedTodayCount;
    final missed = p.missedPlannedSessionsThisWeek;
    final path = (p.selectedPath ?? '').toLowerCase();

    if (p.habits.isEmpty) {
      return 'Design your first loop to get your day moving.';
    }
    if (remaining > 0) {
      final extra = (path.contains('remote') || path.contains('office'))
          ? ' A short walk resets posture and focus.'
          : '';
      return 'Close $remaining loop${remaining == 1 ? '' : 's'} today.$extra';
    }
    if (missed > 0) {
      return 'Loops done. $missed session${missed == 1 ? '' : 's'} left this '
          'week — fit one in to stay on target.';
    }
    return "You're on track today and for the week. Keep it gentle and fuel well.";
  }

  List<Habit> _sortedHabits(HabitProvider provider) {
    final habits = [...provider.habits];
    bool done(Habit h) {
      if (h.id == null) return false;
      if (h.isQuitHabit) return !provider.isCompletedToday(h.id!);
      if (h.isAmountTracking) {
        return provider.todayAmount(h.id!) >= h.targetAmount;
      }
      return provider.isCompletedToday(h.id!);
    }

    habits.sort((a, b) => (done(a) ? 1 : 0).compareTo(done(b) ? 1 : 0));
    return habits;
  }
}

class _FocusBanner extends StatelessWidget {
  final String persona;
  final String summary;
  final VoidCallback onLog;
  final VoidCallback onSession;
  final VoidCallback onFuel;

  const _FocusBanner({
    required this.persona,
    required this.summary,
    required this.onLog,
    required this.onSession,
    required this.onFuel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Ah.gutter),
      decoration: BoxDecoration(
        gradient: Ah.brandGradient,
        borderRadius: BorderRadius.circular(Ah.rXl),
        boxShadow: Ah.accentGlow(opacity: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Ah.onAccent, size: 18),
              const SizedBox(width: 6),
              Text("TODAY'S FOCUS",
                  style: textTheme.labelSmall?.copyWith(
                    color: Ah.onAccent,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: Ah.s8, vertical: 2),
                decoration: BoxDecoration(
                  color: Ah.onAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Ah.rSm),
                ),
                child: Text(persona,
                    style: textTheme.labelSmall?.copyWith(color: Ah.onAccent)),
              ),
            ],
          ),
          const SizedBox(height: Ah.s12),
          Text(summary,
              style: textTheme.titleLarge
                  ?.copyWith(color: Ah.onAccent, height: 1.3)),
          const SizedBox(height: Ah.s16),
          Row(
            children: [
              _FocusAction(icon: Icons.add, label: 'Log', onTap: onLog),
              const SizedBox(width: Ah.s8),
              _FocusAction(
                  icon: Icons.play_arrow, label: 'Session', onTap: onSession),
              const SizedBox(width: Ah.s8),
              _FocusAction(
                  icon: Icons.restaurant, label: 'Fuel', onTap: onFuel),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FocusAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Ah.onAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Ah.rMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Ah.rMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Ah.s12),
            child: Column(
              children: [
                Icon(icon, color: Ah.onAccent, size: 20),
                const SizedBox(height: 4),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: Ah.onAccent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Ah.s32),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: Ah.brandGradient,
                borderRadius: BorderRadius.circular(Ah.rLg),
              ),
              child: const Icon(Icons.route, color: Ah.onAccent, size: 32),
            ),
            const SizedBox(height: Ah.s16),
            Text('Design your first loop',
                textAlign: TextAlign.center, style: textTheme.titleLarge),
            const SizedBox(height: Ah.s8),
            Text(
              'An anchor, a tiny action, a fallback for busy days, and a celebration. That\'s a loop.',
              style: textTheme.bodyMedium?.copyWith(color: Ah.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Ah.s24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create loop'),
            ),
          ],
        ),
      ),
    );
  }
}
