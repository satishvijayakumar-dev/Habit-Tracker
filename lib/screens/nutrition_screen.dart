import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../services/nutrition_engine.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';

/// "Fuel" — practical food guidance, not dieting. Shows calorie + protein
/// targets and natural food options to close the gap, by goal and preference.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  FuelGoal _goal = FuelGoal.fullMeal;
  bool _vegetarian = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final profile = provider.profile;
    final intake = provider.dailyIntakeTarget;
    final textTheme = Theme.of(context).textTheme;
    final options = NutritionEngine.suggest(_goal, vegetarian: _vegetarian);

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          // -- Targets --
          Container(
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Ah.tint(Ah.mint),
                        borderRadius: BorderRadius.circular(Ah.rMd),
                      ),
                      child: const Icon(Icons.restaurant_menu,
                          color: Ah.mint, size: 22),
                    ),
                    const SizedBox(width: Ah.s12),
                    Text('Fuel the plan', style: textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: Ah.s12),
                if (intake == null)
                  _ProfileCta()
                else
                  Text(
                    NutritionEngine.gapLine(
                      intakeTarget: intake,
                      weightKg: (profile?.weightKg ?? 75).round(),
                    ),
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Ah.textSecondary, height: 1.5),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Ah.s24),

          // -- What do you need? --
          Text('What do you need?', style: textTheme.titleLarge),
          const SizedBox(height: Ah.s12),
          SegmentedButton<FuelGoal>(
            segments: FuelGoal.values
                .map((g) => ButtonSegment(value: g, label: Text(g.label)))
                .toList(),
            selected: {_goal},
            onSelectionChanged: (s) {
              HapticFeedback.selectionClick();
              setState(() => _goal = s.first);
            },
          ),
          const SizedBox(height: Ah.s12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vegetarian options only'),
            value: _vegetarian,
            onChanged: (v) => setState(() => _vegetarian = v),
          ),
          const SizedBox(height: Ah.s8),

          // -- Natural food options --
          Text('Natural options (~${_goal.approxKcal} kcal)',
              style: textTheme.titleMedium),
          const SizedBox(height: Ah.s8),
          ...options.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: Ah.s8),
                child: Card(
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Ah.tint(f.vegetarian ? Ah.mint : Ah.warning),
                        borderRadius: BorderRadius.circular(Ah.rSm),
                      ),
                      child: Icon(
                        f.vegetarian ? Icons.eco : Icons.set_meal,
                        color: f.vegetarian ? Ah.mint : Ah.warning,
                        size: 20,
                      ),
                    ),
                    title: Text(f.name),
                    subtitle: Text('~${f.approxKcal} kcal'),
                  ),
                ),
              )),
          const SizedBox(height: Ah.s16),
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

class _ProfileCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete your profile to see your calorie and protein targets.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Ah.textSecondary, height: 1.4),
        ),
        const SizedBox(height: Ah.s12),
        OutlinedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: const Text('Complete profile'),
        ),
      ],
    );
  }
}
