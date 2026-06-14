import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/badges.dart';
import '../services/habit_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/habit_style.dart';
import '../widgets/insights.dart';
import 'paywall_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Progress + body + energy + profile — everything about the user.
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
        title: Text(provider.userName.isEmpty ? 'You' : provider.userName),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          // -- Scientific energy targets --
          _EnergyCard(provider: provider),
          const SizedBox(height: Ah.s16),

          // -- Tappable stats --
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
          const SizedBox(height: Ah.s12),

          // -- Daily streak --
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Ah.tint(Ah.warning),
                  borderRadius: BorderRadius.circular(Ah.rSm),
                ),
                child:
                    const Icon(Icons.local_fire_department, color: Ah.warning),
              ),
              title: Text('${provider.dailyActiveStreak}-day active streak'),
              subtitle: Text(provider.isActiveToday
                  ? 'Active today'
                  : 'Stay active today to extend it'),
            ),
          ),
          const SizedBox(height: Ah.s24),

          // -- Weekly bars --
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
          const SizedBox(height: Ah.s24),

          // -- Streaks --
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                Text('day streak', style: textTheme.labelSmall),
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

          // -- Achievements --
          Row(
            children: [
              Expanded(
                  child: Text('Achievements', style: textTheme.titleLarge)),
              Text('${provider.earnedBadgeCount}/${Badges.all.length}',
                  style: textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: Ah.s12),
          _BadgeGrid(statuses: provider.badgeStatuses),
          const SizedBox(height: Ah.s24),

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

          _ProCard(isPro: provider.isPro),
          const SizedBox(height: Ah.s24),

          Text('More', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Export data as CSV'),
              subtitle: const Text('Copies to clipboard'),
              onTap: () async {
                final csv = provider.exportAsCsv();
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV copied to clipboard')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<int> _minutesByWeekday(HabitProvider provider) {
    final minutes = List<int>.filled(7, 0);
    for (final activity in provider.activitiesThisWeek) {
      minutes[activity.dayKey.weekday - 1] += activity.durationMinutes;
    }
    return minutes;
  }
}

/// Scientific calorie targets (Mifflin–St Jeor → TDEE → goal-adjusted).
class _EnergyCard extends StatelessWidget {
  final HabitProvider provider;
  const _EnergyCard({required this.provider});

  void _explain(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How this is calculated',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: Ah.s12),
            Text(
              'We use the Mifflin–St Jeor equation for your Basal Metabolic Rate '
              '(BMR ${provider.bmr} kcal) — the energy you burn at rest. '
              'Multiplying by your activity level gives your Total Daily Energy '
              'Expenditure (TDEE ${provider.tdee} kcal) — maintenance calories.\n\n'
              'Your intake target adjusts TDEE for your goal (a ~500 kcal deficit '
              'for weight loss, a small surplus for strength). Your burn target is '
              'the activity calories that match your weekly movement goal.\n\n'
              'These are evidence-based estimates, not medical or clinical advice.',
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final intake = provider.dailyIntakeTarget;
    final burn = provider.dailyBurnTarget;

    if (intake == null || burn == null) {
      return Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Ah.tint(Ah.mint),
              borderRadius: BorderRadius.circular(Ah.rSm),
            ),
            child: const Icon(Icons.local_fire_department, color: Ah.mint),
          ),
          title: const Text('Get your calorie targets'),
          subtitle:
              const Text('Complete your profile (age, sex, height, weight).'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Ah.gutter),
      decoration: BoxDecoration(
        color: Ah.surface1,
        borderRadius: BorderRadius.circular(Ah.rXl),
        border: Border.all(color: Ah.mint.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Energy targets', style: textTheme.titleMedium),
              const Spacer(),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _explain(context);
                },
                borderRadius: BorderRadius.circular(Ah.rSm),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      const Icon(Icons.science_outlined,
                          size: 14, color: Ah.textSecondary),
                      const SizedBox(width: 4),
                      Text('How?', style: textTheme.labelSmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Ah.s16),
          Row(
            children: [
              Expanded(
                child: _EnergyStat(
                  label: 'Eat / day',
                  value: intake,
                  icon: Icons.restaurant,
                  color: Ah.mint,
                ),
              ),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: _EnergyStat(
                  label: 'Burn / day',
                  value: burn,
                  icon: Icons.local_fire_department,
                  color: Ah.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: Ah.s12),
          Text(
            'Maintenance (TDEE) ≈ ${provider.tdee} kcal · burned this week '
            '≈ ${provider.estimatedCaloriesThisWeek} kcal',
            style: textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _EnergyStat extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _EnergyStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(Ah.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Ah.rLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: Ah.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$value',
                  style: textTheme.headlineMedium?.copyWith(color: color)),
              const SizedBox(width: 4),
              Text('kcal', style: textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final List<BadgeStatus> statuses;
  const _BadgeGrid({required this.statuses});

  static const _icons = {
    'directions_walk': Icons.directions_walk,
    'event_available': Icons.event_available,
    'local_fire_department': Icons.local_fire_department,
    'fitness_center': Icons.fitness_center,
    'donut_large': Icons.donut_large,
    'star': Icons.star,
    'groups': Icons.groups,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Ah.s8,
      runSpacing: Ah.s8,
      children: statuses.map((s) {
        final earned = s.earned;
        final color = earned ? colorFor(s.def.colorName) : Ah.textTertiary;
        return Container(
          width:
              (MediaQuery.of(context).size.width - Ah.gutter * 2 - Ah.s8) / 2,
          padding: const EdgeInsets.all(Ah.s12),
          decoration: BoxDecoration(
            color: earned
                ? Color.alphaBlend(color.withValues(alpha: 0.12), Ah.surface1)
                : Ah.surface1,
            borderRadius: BorderRadius.circular(Ah.rLg),
            border: Border.all(
                color: earned ? color.withValues(alpha: 0.4) : Ah.hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: earned ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icons[s.def.iconName] ?? Icons.star,
                    color: color, size: 18),
              ),
              const SizedBox(width: Ah.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.def.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: earned ? Ah.textPrimary : Ah.textSecondary,
                            )),
                    Text(
                      earned ? 'Earned' : s.progress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  final List<int> minutesByWeekday;
  const _WeeklyBars({required this.minutesByWeekday});

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final maxMinutes = minutesByWeekday.fold<int>(0, (m, v) => v > m ? v : m);
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
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
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
        border:
            isPro ? Border.all(color: Ah.mint.withValues(alpha: 0.4)) : null,
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
