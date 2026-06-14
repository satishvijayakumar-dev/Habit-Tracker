import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/services/nutrition_engine.dart';

void main() {
  group('suggest', () {
    test('returns options for every goal', () {
      for (final g in FuelGoal.values) {
        expect(NutritionEngine.suggest(g), isNotEmpty);
      }
    });

    test('vegetarian filter returns only vegetarian options', () {
      final veg = NutritionEngine.suggest(FuelGoal.fullMeal, vegetarian: true);
      expect(veg, isNotEmpty);
      expect(veg.every((f) => f.vegetarian), isTrue);
    });

    test('non-vegetarian set includes meat/fish options', () {
      final all = NutritionEngine.suggest(FuelGoal.fullMeal);
      expect(all.any((f) => !f.vegetarian), isTrue);
    });

    test('snack options are lighter than full-meal options on average', () {
      double avg(List<FoodOption> l) =>
          l.map((f) => f.approxKcal).reduce((a, b) => a + b) / l.length;
      expect(avg(NutritionEngine.suggest(FuelGoal.snack)),
          lessThan(avg(NutritionEngine.suggest(FuelGoal.fullMeal))));
    });
  });

  group('targets', () {
    test('protein band is 1.4–2.0 g/kg', () {
      final (lo, hi) = NutritionEngine.proteinBand(80);
      expect(lo, 112);
      expect(hi, 160);
    });

    test('gap line mentions calories and protein', () {
      final line = NutritionEngine.gapLine(intakeTarget: 2300, weightKg: 80);
      expect(line, contains('2300'));
      expect(line.toLowerCase(), contains('protein'));
    });

    test('goal labels and approx kcal are sensible', () {
      expect(FuelGoal.snack.approxKcal, lessThan(FuelGoal.fullMeal.approxKcal));
      expect(FuelGoal.postWorkout.label, 'Post-workout');
    });
  });
}
