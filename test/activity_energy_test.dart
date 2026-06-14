import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/user_profile.dart';
import 'package:habit_tracker/services/activity_energy.dart';
import 'package:habit_tracker/services/habit_provider.dart';

import 'helpers/in_memory_store.dart';

void main() {
  group('ActivityEnergy (MET-based calories)', () {
    test('running burns more than walking for the same session', () {
      final run = ActivityEnergy.caloriesBurned(
          type: 'Running', intensity: 'Moderate', minutes: 60, weightKg: 70);
      final walk = ActivityEnergy.caloriesBurned(
          type: 'Walking', intensity: 'Moderate', minutes: 60, weightKg: 70);
      expect(run, greaterThan(walk));
    });

    test('intensity scales burn: Hard > Moderate > Easy', () {
      int at(String i) => ActivityEnergy.caloriesBurned(
          type: 'Running', intensity: i, minutes: 30, weightKg: 70);
      expect(at('Hard'), greaterThan(at('Moderate')));
      expect(at('Moderate'), greaterThan(at('Easy')));
    });

    test('known value: walking, moderate, 60 min, 70 kg ≈ 257 kcal', () {
      // MET 3.5 × 3.5 × 70 / 200 × 60 = 257.25 -> 257
      expect(
        ActivityEnergy.caloriesBurned(
            type: 'Walking', intensity: 'Moderate', minutes: 60, weightKg: 70),
        257,
      );
    });

    test('unknown activity type falls back to the default MET', () {
      final unknown = ActivityEnergy.caloriesBurned(
          type: 'Quidditch', intensity: 'Moderate', minutes: 30, weightKg: 70);
      final gym = ActivityEnergy.caloriesBurned(
          type: 'Gym', intensity: 'Moderate', minutes: 30, weightKg: 70);
      expect(unknown, gym); // default 5.0 == gym base
    });

    test('non-positive minutes or weight yield zero', () {
      expect(
          ActivityEnergy.caloriesBurned(
              type: 'Running', intensity: 'Hard', minutes: 0, weightKg: 70),
          0);
      expect(
          ActivityEnergy.caloriesBurned(
              type: 'Running', intensity: 'Hard', minutes: 30, weightKg: 0),
          0);
    });

    test('type matching is case-insensitive', () {
      expect(
        ActivityEnergy.metFor('RUNNING', 'Moderate'),
        ActivityEnergy.metFor('running', 'Moderate'),
      );
    });
  });

  group('Runner persona weekly plan', () {
    test('runner gets a pace-guided plan with a quality session', () async {
      final p = HabitProvider(store: InMemoryHabitStore());
      await p.load();
      await p.setSelectedPath('The Runner / Walker');
      await p.saveProfile(UserProfile(
        age: 30,
        sex: 'Female',
        heightCm: 168,
        weightKg: 62,
        fitnessGoal: 'Run better',
        activityLevel: 'Some activity',
        areaName: 'Watford',
        shareApproxLocation: false,
        updatedAt: DateTime(2026, 6, 14),
      ));
      final plan = p.weeklyExercisePlan;
      expect(plan.any((d) => d.contains('Intervals')), isTrue);
      expect(plan.any((d) => d.toLowerCase().contains('pace')), isTrue);
      expect(plan.any((d) => d.contains('Long run')), isTrue);
    });
  });
}
