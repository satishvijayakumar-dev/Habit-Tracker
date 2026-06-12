import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

/// "Fuel" — a coach topic, not a destination. Simple, honest guidance.
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final weight = provider.profile?.weightKg ?? 75;
    final proteinLow = (weight * 1.4).round();
    final proteinHigh = (weight * 1.8).round();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel')),
      body: ListView(
        padding:
            const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Container(
            padding: const EdgeInsets.all(Ah.gutter),
            decoration: BoxDecoration(
              color: Ah.surface2,
              borderRadius: BorderRadius.circular(Ah.rXl),
              border: Border.all(color: Ah.mint.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Ah.tint(Ah.mint),
                    borderRadius: BorderRadius.circular(Ah.rMd),
                  ),
                  child: const Icon(Icons.restaurant_menu,
                      color: Ah.mint, size: 26),
                ),
                const SizedBox(height: Ah.s16),
                Text('Fuel the plan', style: textTheme.headlineMedium),
                const SizedBox(height: Ah.s8),
                Text(
                  'Today aim for roughly $proteinLow–$proteinHigh g protein, steady hydration, and one simple meal you can repeat.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: Ah.textSecondary, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: Ah.s16),
          const _NutritionCard(
            title: 'Before training',
            detail:
                'Water plus an easy carbohydrate if the session is longer or harder.',
            icon: Icons.water_drop_outlined,
            color: Ah.info,
          ),
          const _NutritionCard(
            title: 'After training',
            detail: 'Protein and a normal meal. Recovery beats restriction.',
            icon: Icons.egg_alt_outlined,
            color: Ah.mint,
          ),
          const _NutritionCard(
            title: 'Office or remote day',
            detail:
                'Plan one snack and one water cue before the afternoon slump.',
            icon: Icons.work_outline,
            color: Ah.warning,
          ),
          const SizedBox(height: Ah.s8),
          Text(
            'Nutrition guidance is general wellbeing support. For medical, diabetic, pregnancy, eating disorder, or clinical nutrition needs, use professional advice.',
            style: textTheme.labelSmall?.copyWith(height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _NutritionCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Ah.s8),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Ah.tint(color),
              borderRadius: BorderRadius.circular(Ah.rSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title),
          subtitle: Text(detail),
        ),
      ),
    );
  }
}
