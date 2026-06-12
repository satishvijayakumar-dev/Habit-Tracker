import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_style.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';
import 'share_screen.dart';

/// Progress, body, streaks, profile, and settings — everything about
/// the user, in one place.
class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final textTheme = Theme.of(context).textTheme;
    final profile = provider.profile;
    final latestMetric =
        provider.bodyMetrics.isEmpty ? null : provider.bodyMetrics.first;
    final firstMetric =
        provider.bodyMetrics.isEmpty ? null : provider.bodyMetrics.last;
    final weightChange = latestMetric == null || firstMetric == null
        ? null
        : latestMetric.weightKg - firstMetric.weightKg;

    final sortedHabits = [...provider.habits]..sort((a, b) {
        if (a.id == null || b.id == null) return 0;
        return provider.currentStreak(b.id!) - provider.currentStreak(a.id!);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.userName.isEmpty ? 'You' : provider.userName,
        ),
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            icon: const Icon(Icons.manage_accounts_outlined),
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
          // -- This week, as bars --
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Ah.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your week', style: textTheme.titleMedium),
                  const SizedBox(height: Ah.s16),
                  _WeeklyBars(minutesByWeekday: _minutesByWeekday(provider)),
                ],
              ),
            ),
          ),
          const SizedBox(height: Ah.s12),

          // -- Stat tiles --
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Active min',
                  value: provider.activeMinutesThisWeek,
                  color: Ah.info,
                ),
              ),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: _StatTile(
                  label: 'Sessions',
                  value: provider.activitySessionsThisWeek,
                  color: Ah.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: Ah.s12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Calories est.',
                  value: provider.estimatedCaloriesThisWeek,
                  color: Ah.mint,
                ),
              ),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: _StatTile(
                  label: 'Star points',
                  value: provider.starPoints,
                  color: Ah.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: Ah.s24),

          // -- Streaks with 14-day heat strips --
          if (sortedHabits.isNotEmpty) ...[
            Text('Loop streaks', style: textTheme.titleLarge),
            const SizedBox(height: Ah.s12),
            ...sortedHabits.take(6).map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: Ah.s8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(Ah.s12),
                        child: Row(
                          children: [
                            Icon(iconFor(h.iconName),
                                color: colorFor(h.colorName), size: 20),
                            const SizedBox(width: Ah.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(h.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.titleSmall),
                                  const SizedBox(height: Ah.s8),
                                  if (h.id != null)
                                    _HeatStrip(
                                      completions:
                                          provider.completionsFor(h.id!),
                                      color: colorFor(h.colorName),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Ah.s12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  h.id == null
                                      ? '0'
                                      : '${provider.currentStreak(h.id!)}',
                                  style: textTheme.headlineSmall,
                                ),
                                Text('day streak',
                                    style: textTheme.labelSmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: Ah.s16),
          ],

          // -- Body --
          if (profile != null) ...[
            Text('Body', style: textTheme.titleLarge),
            const SizedBox(height: Ah.s12),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.monitor_weight_outlined, color: Ah.info),
                title: Text(
                  'BMI ${profile.bmi.toStringAsFixed(1)} · ${profile.bmiLabel}',
                ),
                subtitle: Text(
                  weightChange == null
                      ? 'Add body check-ins to track change over time.'
                      : 'Weight change since start: ${weightChange >= 0 ? "+" : ""}${weightChange.toStringAsFixed(1)} kg',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
            ),
            const SizedBox(height: Ah.s24),
          ],

          // -- Pro --
          _ProCard(isPro: provider.isPro),
          const SizedBox(height: Ah.s24),

          // -- More --
          Text('More', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('Invite a friend'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ShareScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Export data as CSV'),
                  subtitle: const Text('Copies to clipboard'),
                  onTap: () async {
                    final csv = provider.exportAsCsv();
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('CSV copied to clipboard')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Minutes per weekday (Mon..Sun) for the current week.
  List<int> _minutesByWeekday(HabitProvider provider) {
    final minutes = List<int>.filled(7, 0);
    for (final activity in provider.activitiesThisWeek) {
      final weekday = activity.dayKey.weekday; // 1=Mon..7=Sun
      minutes[weekday - 1] += activity.durationMinutes;
    }
    return minutes;
  }
}

class _WeeklyBars extends StatelessWidget {
  final List<int> minutesByWeekday;

  const _WeeklyBars({required this.minutesByWeekday});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxMinutes =
        minutesByWeekday.fold<int>(0, (m, v) => v > m ? v : m);
    final todayIndex = DateTime.now().weekday - 1;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final value = minutesByWeekday[i];
          final fraction = maxMinutes == 0 ? 0.0 : value / maxMinutes;
          final barHeight = 8 + 84 * fraction;
          final isToday = i == todayIndex;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (value > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Ah.s4),
                    child: Text('$value',
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: barHeight,
                  margin: const EdgeInsets.symmetric(horizontal: Ah.s4),
                  decoration: BoxDecoration(
                    gradient: value > 0 ? Ah.brandGradient : null,
                    color: value > 0 ? null : Ah.surface3,
                    borderRadius: BorderRadius.circular(Ah.rSm),
                  ),
                ),
                const SizedBox(height: Ah.s8),
                Text(
                  _labels[i],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isToday ? Ah.accent : Ah.textTertiary,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Stat tile with a count-up number.
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Ah.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            ),
            const SizedBox(height: Ah.s8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                '${v.round()}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 14-day completion heat strip (GitHub-style, graded by recency).
class _HeatStrip extends StatelessWidget {
  final Set<DateTime> completions;
  final Color color;

  const _HeatStrip({required this.completions, required this.color});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    return Row(
      children: List.generate(14, (i) {
        final day = todayKey.subtract(Duration(days: 13 - i));
        final done = completions.contains(day);
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i == 13 ? 0 : 3),
            decoration: BoxDecoration(
              color: done ? color : Ah.surface3,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

class _ProCard extends StatelessWidget {
  final bool isPro;

  const _ProCard({required this.isPro});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: isPro ? null : Ah.brandGradient,
        color: isPro ? Ah.surface1 : null,
        borderRadius: BorderRadius.circular(Ah.rLg),
        border: isPro ? Border.all(color: Ah.mint.withValues(alpha: 0.4)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(Ah.rLg),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Ah.s16),
            child: Row(
              children: [
                Icon(
                  isPro ? Icons.verified : Icons.workspace_premium,
                  color: isPro ? Ah.mint : Ah.onAccent,
                  size: 28,
                ),
                const SizedBox(width: Ah.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? 'ActivHealth Pro — active' : 'ActivHealth Pro',
                        style: textTheme.titleMedium?.copyWith(
                          color: isPro ? Ah.textPrimary : Ah.onAccent,
                        ),
                      ),
                      Text(
                        isPro
                            ? 'Unlimited loops, full insights, early features'
                            : 'Unlimited loops, deeper insights, and more',
                        style: textTheme.labelMedium?.copyWith(
                          color: isPro
                              ? Ah.textSecondary
                              : Ah.onAccent.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: isPro ? Ah.textTertiary : Ah.onAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
