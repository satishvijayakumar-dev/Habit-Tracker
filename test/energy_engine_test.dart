import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/user_profile.dart';
import 'package:habit_tracker/services/habit_provider.dart';

import 'helpers/in_memory_store.dart';

/// Scientific energy targets (Mifflin–St Jeor) and AI-recommended minutes.
void main() {
  Future<HabitProvider> providerWith({
    String sex = 'Male',
    int age = 35,
    double height = 178,
    double weight = 80,
    String goal = 'Build strength',
    String level = 'Active',
    String path = 'The Gym Builder',
  }) async {
    final p = HabitProvider(store: InMemoryHabitStore());
    await p.load();
    await p.setSelectedPath(path);
    await p.saveProfile(UserProfile(
      age: age,
      sex: sex,
      heightCm: height,
      weightKg: weight,
      fitnessGoal: goal,
      activityLevel: level,
      areaName: 'Watford',
      shareApproxLocation: false,
      updatedAt: DateTime(2026, 6, 13),
    ));
    return p;
  }

  group('energy targets', () {
    test('null until a complete profile exists', () async {
      final p = HabitProvider(store: InMemoryHabitStore());
      await p.load();
      expect(p.bmr, isNull);
      expect(p.tdee, isNull);
      expect(p.dailyIntakeTarget, isNull);
      expect(p.dailyBurnTarget, isNull);
    });

    test('Mifflin–St Jeor BMR for a known male profile', () async {
      final p = await providerWith();
      // 10*80 + 6.25*178 - 5*35 + 5 = 1742.5 -> 1743
      expect(p.bmr, 1743);
    });

    test('female offset differs from male by 166 kcal', () async {
      final male = await providerWith(sex: 'Male');
      final female = await providerWith(sex: 'Female');
      expect(male.bmr! - female.bmr!, 166); // +5 vs -161
    });

    test('TDEE applies the active multiplier', () async {
      final p = await providerWith(level: 'Active');
      expect(p.tdee, (1743 * 1.725).round()); // 3007
    });

    test('weight-loss goal creates a ~500 kcal deficit vs maintenance',
        () async {
      final p = await providerWith(goal: 'Lose weight');
      expect(p.dailyIntakeTarget, p.tdee! - 500);
    });

    test('strength goal adds a small surplus', () async {
      final p = await providerWith(goal: 'Build strength');
      expect(p.dailyIntakeTarget, p.tdee! + 250);
    });

    test('daily burn target is positive and derived from movement goal',
        () async {
      final p = await providerWith();
      expect(p.dailyBurnTarget, greaterThan(0));
      expect(p.weeklyBurnTarget, p.dailyBurnTarget! * 7);
    });
  });

  group('AI-recommended minutes', () {
    test('scales down for a beginner, up for an active user', () async {
      final beginner = await providerWith(level: 'Getting started');
      final active = await providerWith(level: 'Active');
      // Gym base 45: beginner *0.8 = 36 -> 35; active *1.2 = 54 -> 55
      expect(beginner.recommendedMinutesFor('Gym'), 35);
      expect(active.recommendedMinutesFor('Gym'), 55);
    });

    test('remote/office persona gets extra walking minutes', () async {
      final remote =
          await providerWith(path: 'Remote Worker', level: 'Some activity');
      final gym =
          await providerWith(path: 'The Gym Builder', level: 'Some activity');
      // Walking base 30; remote adds 10 before the level factor (×1.0)
      expect(remote.recommendedMinutesFor('Walking'), 40);
      expect(gym.recommendedMinutesFor('Walking'), 30);
    });

    test('rounds to the nearest 5 minutes', () async {
      final p = await providerWith(level: 'Some activity');
      expect(p.recommendedMinutesFor('Tennis') % 5, 0);
      expect(p.recommendedMinutesFor('Stretching') % 5, 0);
    });
  });
}
