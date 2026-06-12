import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_tile.dart';
import '../widgets/momentum_ring.dart';
import 'activity_log_screen.dart';
import 'add_edit_habit_screen.dart';
import 'coach_screen.dart';
import 'habit_detail_screen.dart';
import 'paywall_screen.dart';
import 'workout_screen.dart';

/// The day, on one screen: greeting, Momentum Ring, 1-tap loops,
/// today's session, one coach nudge. Nothing else.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Morning'
        : hour < 18
            ? 'Afternoon'
            : 'Evening';
    return name.isEmpty ? '$part.' : '$part, $name.';
  }

  void _addLoop(BuildContext context) {
    final provider = context.read<HabitProvider>();
    if (!provider.canAddLoop) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditHabitScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final textTheme = Theme.of(context).textTheme;
    final dateString = DateFormat('EEEE d MMMM').format(DateTime.now());
    final nudge = _coachNudge(provider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              Ah.gutter, Ah.s12, Ah.gutter, Ah.s48 + Ah.s32),
          children: [
            // -- Header --
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateString, style: textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Text(
                        _greeting(provider.userName),
                        style: textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                if (provider.selectedPath != null)
                  Container(
                    margin: const EdgeInsets.only(top: Ah.s4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: Ah.s12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Ah.tint(Ah.accent),
                      borderRadius: BorderRadius.circular(Ah.rSm),
                    ),
                    child: Text(
                      provider.selectedPath!,
                      style: textTheme.labelMedium
                          ?.copyWith(color: Ah.accent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Ah.s24),

            // -- Momentum Ring --
            Center(
              child: MomentumRing(
                loopsDone: provider.completedTodayCount,
                loopsTotal: habits.length,
                activeMinutes: provider.activeMinutesThisWeek,
                minutesTarget: provider.weeklyMinutesTarget,
              ),
            ),
            const SizedBox(height: Ah.s24),

            // -- One coach nudge, max --
            if (nudge != null) ...[
              _CoachNudgeCard(
                message: nudge,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CoachScreen()),
                ),
              ),
              const SizedBox(height: Ah.s16),
            ],

            // -- Today's session --
            _SessionCard(
              onStart: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WorkoutScreen()),
              ),
              sessionsThisWeek: provider.activitySessionsThisWeek,
              missed: provider.missedPlannedSessionsThisWeek,
            ),
            const SizedBox(height: Ah.s24),

            // -- Loops --
            Row(
              children: [
                Expanded(
                  child:
                      Text("Today's loops", style: textTheme.titleLarge),
                ),
                TextButton.icon(
                  onPressed: () => _addLoop(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New loop'),
                ),
              ],
            ),
            const SizedBox(height: Ah.s8),
            if (habits.isEmpty)
              _EmptyState(onAdd: () => _addLoop(context))
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

  /// Completed loops sink to the bottom — celebrated, not crossed out.
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

    habits.sort((a, b) {
      final aDone = done(a) ? 1 : 0;
      final bDone = done(b) ? 1 : 0;
      return aDone.compareTo(bDone);
    });
    return habits;
  }

  String? _coachNudge(HabitProvider provider) {
    if (!provider.hasCheckedInToday) {
      return 'Quick check-in with your coach — 10 seconds, sets up your day.';
    }
    final soreness = provider.todayCheckIn['soreness'];
    if (soreness == 'High') {
      return 'Recovery mode today: mobility, easy walking, hydration.';
    }
    final remaining = provider.habits.length - provider.completedTodayCount;
    if (remaining == 1) {
      return 'One loop left to close the ring. Small and done beats perfect.';
    }
    return null;
  }
}

class _CoachNudgeCard extends StatelessWidget {
  final String message;
  final VoidCallback onTap;

  const _CoachNudgeCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Ah.rLg),
        child: Padding(
          padding: const EdgeInsets.all(Ah.s16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: Ah.brandGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_alt,
                    color: Ah.onAccent, size: 20),
              ),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.chevron_right, color: Ah.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final VoidCallback onStart;
  final int sessionsThisWeek;
  final int missed;

  const _SessionCard({
    required this.onStart,
    required this.sessionsThisWeek,
    required this.missed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Ah.s16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Ah.tint(Ah.accent),
                borderRadius: BorderRadius.circular(Ah.rMd),
              ),
              child: const Icon(Icons.play_arrow, color: Ah.accent),
            ),
            const SizedBox(width: Ah.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's session", style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    missed == 0
                        ? '$sessionsThisWeek session${sessionsThisWeek == 1 ? '' : 's'} done this week — on track'
                        : '$missed more session${missed == 1 ? '' : 's'} to hit this week',
                    style: textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: Ah.s16),
              ),
              child: const Text('Start'),
            ),
          ],
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
            Text(
              'Design your first loop',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
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
