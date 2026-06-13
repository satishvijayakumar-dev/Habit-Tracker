import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

/// A vibrant, tappable stat tile (duotone block). Tapping drills into detail.
class StatCard extends StatelessWidget {
  final String label;
  final int value;
  final String unit;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      label: '$label: $value $unit. Tap for detail.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(Ah.rLg),
          child: Container(
            padding: const EdgeInsets.all(Ah.s16),
            decoration: BoxDecoration(
              color:
                  Color.alphaBlend(accent.withValues(alpha: 0.14), Ah.surface1),
              borderRadius: BorderRadius.circular(Ah.rLg),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(Ah.rSm),
                      ),
                      child: Icon(icon, color: accent, size: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: accent, size: 18),
                  ],
                ),
                const SizedBox(height: Ah.s12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.toDouble()),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '${v.round()}',
                    style: textTheme.displayMedium?.copyWith(color: accent),
                  ),
                ),
                Text(label, style: textTheme.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Drill-in detail sheets ────────────────────────────────────────────────

void _showSheet(BuildContext context, String title, List<Widget> children) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Text(title, style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: Ah.s16),
          ...children,
        ],
      ),
    ),
  );
}

/// Where the active minutes were spent (breakdown by activity type).
void showActiveMinutesInsight(BuildContext context, HabitProvider p) {
  final breakdown = p.weeklyMinutesByType.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final total = p.activeMinutesThisWeek;
  _showSheet(context, 'Active minutes this week', [
    if (breakdown.isEmpty)
      _emptyRow(context, 'No movement logged yet this week.')
    else
      ...breakdown.map((e) => _BarRow(
            label: e.key,
            value: e.value,
            max: total,
            unit: 'min',
            color: Ah.info,
          )),
    const SizedBox(height: Ah.s12),
    _TotalRow(label: 'Total', value: '$total min', color: Ah.info),
  ]);
}

/// When and how each session happened.
void showSessionsInsight(BuildContext context, HabitProvider p) {
  final sessions = p.activitiesThisWeek;
  _showSheet(context, 'Sessions this week', [
    if (sessions.isEmpty)
      _emptyRow(context, 'No sessions logged yet this week.')
    else
      ...sessions.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: Ah.s8),
            child: Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Ah.tint(Ah.warning),
                    borderRadius: BorderRadius.circular(Ah.rSm),
                  ),
                  child: const Icon(Icons.event_available,
                      color: Ah.warning, size: 20),
                ),
                title: Text('${a.type} · ${a.durationMinutes} min'),
                subtitle: Text(
                  '${a.intensity} · ${DateFormat('EEE d MMM, HH:mm').format(a.completedAt)}',
                ),
              ),
            ),
          )),
  ]);
}

/// How the star points were accumulated.
void showStarPointsInsight(BuildContext context, HabitProvider p) {
  final rows = p.starPointsBreakdown;
  _showSheet(context, 'Star points this week', [
    ...rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: Ah.s8),
          child: Row(
            children: [
              const Icon(Icons.star, color: Ah.accent, size: 18),
              const SizedBox(width: Ah.s12),
              Expanded(
                child: Text(r.label,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              Text('+${r.points}',
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        )),
    const Divider(height: Ah.s24),
    _TotalRow(label: 'Total', value: '${p.starPoints} pts', color: Ah.accent),
  ]);
}

Widget _emptyRow(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Ah.s16),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Ah.textSecondary)),
    );

class _BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final String unit;
  final Color color;

  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: Ah.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.titleSmall)),
              Text('$value $unit',
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Ah.rSm),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, f, _) => LinearProgressIndicator(
                value: f,
                minHeight: 8,
                backgroundColor: Ah.surface3,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TotalRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: color)),
      ],
    );
  }
}
