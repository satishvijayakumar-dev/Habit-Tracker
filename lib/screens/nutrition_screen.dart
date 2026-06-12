import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/habit_provider.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final weight = provider.profile?.weightKg ?? 75;
    final proteinLow = (weight * 1.4).round();
    final proteinHigh = (weight * 1.8).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition coach')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E9F6E), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.restaurant_menu,
                    color: Colors.white, size: 40),
                const SizedBox(height: 16),
                const Text(
                  'Fuel the plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Today aim for roughly $proteinLow-$proteinHigh g protein, steady hydration, and one simple meal you can repeat.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _NutritionCard(
            title: 'Before training',
            detail:
                'Water plus an easy carbohydrate if the session is longer or harder.',
            icon: Icons.water_drop_outlined,
            color: Color(0xFF2563EB),
          ),
          const _NutritionCard(
            title: 'After training',
            detail: 'Protein and a normal meal. Recovery beats restriction.',
            icon: Icons.egg_alt_outlined,
            color: Color(0xFF0E9F6E),
          ),
          const _NutritionCard(
            title: 'Office or remote day',
            detail:
                'Plan one snack and one water cue before the afternoon slump.',
            icon: Icons.work_outline,
            color: Color(0xFFF59E0B),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nutrition guidance is general wellbeing support. For medical, diabetic, pregnancy, eating disorder, or clinical nutrition needs, use professional advice.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ),
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
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(detail),
      ),
    );
  }
}
