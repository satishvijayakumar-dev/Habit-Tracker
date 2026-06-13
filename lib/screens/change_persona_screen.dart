import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';
import '../theme/app_theme.dart';

/// Lets the user switch persona/path at any time (it shapes the coach voice,
/// home focus, and recommended minutes). Existing loops are kept.
class ChangePersonaScreen extends StatelessWidget {
  const ChangePersonaScreen({super.key});

  static const _personas = [
    (
      name: 'The Gym Builder',
      icon: Icons.fitness_center,
      color: Ah.accent,
      blurb: 'Strength plans, form cues, recovery, progression.'
    ),
    (
      name: 'The Runner / Walker',
      icon: Icons.directions_run,
      color: Ah.info,
      blurb: 'Pace, distance, active minutes, safe progression.'
    ),
    (
      name: 'The Social Sports User',
      icon: Icons.sports_tennis,
      color: Color(0xFF9B8AFB),
      blurb: 'Group activity, local accountability, shared sessions.'
    ),
    (
      name: 'Office Professional',
      icon: Icons.business_center,
      color: Ah.info,
      blurb: 'Desk energy, focus resets, shutdown rituals.'
    ),
    (
      name: 'Remote Worker',
      icon: Icons.home_work,
      color: Color(0xFF9B8AFB),
      blurb: 'Home-work boundaries, movement, food cues, screen breaks.'
    ),
    (
      name: 'The Starter',
      icon: Icons.flag,
      color: Ah.mint,
      blurb: 'Beginner-safe actions for confidence and consistency.'
    ),
    (
      name: 'Balanced Everyday',
      icon: Icons.balance,
      color: Ah.mint,
      blurb: 'Simple consistency across health, focus, and calm.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final current = provider.selectedPath;

    return Scaffold(
      appBar: AppBar(title: const Text('Change persona')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ah.gutter, Ah.s8, Ah.gutter, Ah.s32),
        children: [
          Text(
            'Your persona tailors the coach, your home focus, and the minutes the coach recommends. Switch any time — your loops stay.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Ah.textSecondary, height: 1.4),
          ),
          const SizedBox(height: Ah.s16),
          ..._personas.map((p) {
            final selected = current == p.name;
            return Padding(
              padding: const EdgeInsets.only(bottom: Ah.s8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(Ah.rLg),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    provider.setSelectedPath(p.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Persona set to ${p.name}')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(Ah.s16),
                    decoration: BoxDecoration(
                      color: selected
                          ? Color.alphaBlend(
                              p.color.withValues(alpha: 0.14), Ah.surface1)
                          : Ah.surface1,
                      borderRadius: BorderRadius.circular(Ah.rLg),
                      border: Border.all(
                        color: selected ? p.color : Ah.hairline,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: p.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(Ah.rMd),
                          ),
                          child: Icon(p.icon, color: p.color, size: 22),
                        ),
                        const SizedBox(width: Ah.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(p.blurb,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, color: p.color, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
