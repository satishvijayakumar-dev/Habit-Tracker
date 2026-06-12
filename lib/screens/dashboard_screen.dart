import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import 'activity_log_screen.dart';
import 'add_edit_habit_screen.dart';
import 'all_habits_screen.dart';
import 'profile_screen.dart';
import 'workout_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final path = provider.selectedPath ?? 'ActivHealth';
    final activeMinutes = provider.activeMinutesThisWeek;
    final sessions = provider.activitySessionsThisWeek;
    final loopsDone = provider.completedTodayCount;
    final loopsTotal = provider.habits.length;
    final latest = provider.latestActivity;
    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ActivHealth'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (!provider.hasProfile) ...[
            _ProfilePrompt(),
            const SizedBox(height: 16),
          ],
          _HeroPanel(
            path: path,
            activeMinutes: activeMinutes,
            sessions: sessions,
            loopsDone: loopsDone,
            loopsTotal: loopsTotal,
            starPoints: provider.starPoints,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ActivityLogScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Log activity'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Workout plan',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                ),
                icon: const Icon(Icons.fitness_center),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Create loop',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddEditHabitScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_task),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'View loops',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AllHabitsScreen()),
                ),
                icon: const Icon(Icons.list_alt),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _CoachBrief(
            path: path,
            activeMinutes: activeMinutes,
            sessions: sessions,
            loopsDone: loopsDone,
            loopsTotal: loopsTotal,
          ),
          const SizedBox(height: 16),
          _LatestActivityCard(
              latestType: latest?.type, minutes: latest?.durationMinutes),
          const SizedBox(height: 16),
          if (profile != null) ...[
            _BodyCard(
              bmi: profile.bmi,
              bmiLabel: profile.bmiLabel,
              calories: provider.estimatedCaloriesThisWeek,
              missed: provider.missedPlannedSessionsThisWeek,
            ),
            const SizedBox(height: 16),
          ],
          _PrivacyCard(area: profile?.areaName),
        ],
      ),
    );
  }
}

class _ProfilePrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_add_alt),
        title: const Text('Complete your body profile'),
        subtitle: const Text(
          'Age, sex, height, weight, goal, and area unlock better plans and reports.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String path;
  final int activeMinutes;
  final int sessions;
  final int loopsDone;
  final int loopsTotal;
  final int starPoints;

  const _HeroPanel({
    required this.path,
    required this.activeMinutes,
    required this.sessions,
    required this.loopsDone,
    required this.loopsTotal,
    required this.starPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            path,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Your plan adapts around real activity, tiny behavior loops, and local support.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Active mins',
                  value: '$activeMinutes',
                  icon: Icons.directions_run,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Sessions',
                  value: '$sessions',
                  icon: Icons.event_available,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Star pts',
                  value: '$starPoints',
                  icon: Icons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _CoachBrief extends StatelessWidget {
  final String path;
  final int activeMinutes;
  final int sessions;
  final int loopsDone;
  final int loopsTotal;

  const _CoachBrief({
    required this.path,
    required this.activeMinutes,
    required this.sessions,
    required this.loopsDone,
    required this.loopsTotal,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_alt_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  'Today focus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(recommendation, style: const TextStyle(height: 1.35)),
          ],
        ),
      ),
    );
  }

  String _recommendation() {
    if (activeMinutes == 0) {
      return 'Start with a 10-minute easy walk or stretch. ActivHealth will build your week from what you actually do, not from a rigid plan.';
    }
    if (activeMinutes < 90) {
      return 'You have momentum. Add one low-friction session and protect $loopsDone of $loopsTotal loops today.';
    }
    if (path.toLowerCase().contains('gym')) {
      return 'Good training volume this week. Add mobility or an easy recovery walk before chasing another hard session.';
    }
    return 'Strong week. Keep today simple: one active session, one food or recovery choice, and one behavior loop protected.';
  }
}

class _LatestActivityCard extends StatelessWidget {
  final String? latestType;
  final int? minutes;

  const _LatestActivityCard({required this.latestType, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.timeline),
        title: const Text('Latest activity'),
        subtitle: Text(
          latestType == null
              ? 'No activity logged yet.'
              : '$latestType for $minutes minutes',
        ),
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final String? area;

  const _PrivacyCard({this.area});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                area == null || area!.isEmpty
                    ? 'Groups use approximate areas only. Complete your profile before community matching.'
                    : 'Community matching is set to $area. Exact GPS and user-to-user invites need the secure backend phase.',
                style: const TextStyle(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  final double bmi;
  final String bmiLabel;
  final int calories;
  final int missed;

  const _BodyCard({
    required this.bmi,
    required this.bmiLabel,
    required this.calories,
    required this.missed,
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
              'Body and progress',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'BMI',
                    value: bmi.toStringAsFixed(1),
                    detail: bmiLabel,
                  ),
                ),
                Expanded(
                  child: _MiniStat(
                    label: 'Calories',
                    value: '$calories',
                    detail: 'estimated this week',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              missed == 0
                  ? 'No planned sessions missed this week.'
                  : '$missed session${missed == 1 ? "" : "s"} still open. Coach will rebalance the week.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String detail;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(detail, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
