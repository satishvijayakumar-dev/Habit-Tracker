/// Natural-food recommendation engine. Given a calorie goal and dietary
/// preference, returns practical whole-food options — "fuel guidance, not
/// dieting" per the product blueprint. Pure (no Flutter), so it's testable
/// and can run offline.
library;

enum FuelGoal { snack, fullMeal, postWorkout }

extension FuelGoalInfo on FuelGoal {
  String get label => switch (this) {
        FuelGoal.snack => 'Light snack',
        FuelGoal.fullMeal => 'Full meal',
        FuelGoal.postWorkout => 'Post-workout',
      };

  /// Rough target the suggestions aim for.
  int get approxKcal => switch (this) {
        FuelGoal.snack => 300,
        FuelGoal.fullMeal => 700,
        FuelGoal.postWorkout => 700,
      };
}

class FoodOption {
  final String name;
  final int approxKcal;
  final bool vegetarian;
  const FoodOption(this.name, this.approxKcal, {this.vegetarian = false});
}

abstract final class NutritionEngine {
  static const _snack = [
    FoodOption('Banana with peanut butter', 300, vegetarian: true),
    FoodOption('Boiled eggs and fruit', 240, vegetarian: true),
    FoodOption('Greek yoghurt with berries', 220, vegetarian: true),
    FoodOption('Hummus with carrots and pita', 280, vegetarian: true),
    FoodOption('Oats with milk', 300, vegetarian: true),
    FoodOption('Handful of nuts and fruit', 290, vegetarian: true),
    FoodOption('Cottage cheese and fruit', 250, vegetarian: true),
    FoodOption('Tuna on a rice cake', 220),
  ];

  static const _fullMeal = [
    FoodOption('Chicken, rice and vegetables', 650),
    FoodOption('Salmon, potatoes and greens', 680),
    FoodOption('Lentil dal with rice', 620, vegetarian: true),
    FoodOption('Paneer wrap with salad', 600, vegetarian: true),
    FoodOption('Tuna jacket potato', 560),
    FoodOption('Tofu stir fry with noodles', 600, vegetarian: true),
    FoodOption('Turkey wrap with yoghurt', 590),
    FoodOption('Chickpea curry with rice', 640, vegetarian: true),
  ];

  static const _postWorkout = [
    FoodOption('Chicken, rice and vegetables', 700),
    FoodOption('Salmon, potatoes and greens', 720),
    FoodOption('Lentil curry with rice', 680, vegetarian: true),
    FoodOption('Paneer and chapati with salad', 700, vegetarian: true),
    FoodOption('Tofu noodles with vegetables', 660, vegetarian: true),
    FoodOption('Turkey wrap with yoghurt', 690),
    FoodOption('Eggs, wholemeal toast and avocado', 650, vegetarian: true),
  ];

  /// Natural food options for a goal, filtered by preference.
  static List<FoodOption> suggest(FuelGoal goal, {bool vegetarian = false}) {
    final pool = switch (goal) {
      FuelGoal.snack => _snack,
      FuelGoal.fullMeal => _fullMeal,
      FuelGoal.postWorkout => _postWorkout,
    };
    final list = vegetarian ? pool.where((f) => f.vegetarian).toList() : pool;
    return list;
  }

  /// Protein target band (g/day) from bodyweight — 1.4–2.0 g/kg.
  static (int, int) proteinBand(double weightKg) =>
      ((weightKg * 1.4).round(), (weightKg * 2.0).round());

  /// A short, practical line about closing the gap.
  static String gapLine({required int intakeTarget, required int weightKg}) {
    final band = proteinBand(weightKg.toDouble());
    return 'Aim for about $intakeTarget kcal today and ${band.$1}–${band.$2} g '
        'protein. Pick natural foods you enjoy — consistency beats perfection.';
  }
}
