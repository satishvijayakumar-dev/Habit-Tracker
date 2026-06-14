/// Activity energy expenditure — MET-based calorie estimation.
///
/// Pure (no Flutter) and unit-tested. Uses the standard kcal formula
///   kcal = MET × 3.5 × weightKg / 200 × minutes
/// where the effective MET comes from a compendium-aligned table keyed by
/// activity type, scaled by reported intensity. This makes a 30-min run burn
/// materially more than 30 min of light strength work — type-aware accuracy
/// the old single-MET-by-intensity estimate couldn't give.
class ActivityEnergy {
  ActivityEnergy._();

  /// Compendium-aligned base METs by activity type (moderate effort).
  static const Map<String, double> _baseMet = {
    'walking': 3.5,
    'brisk walk': 4.3,
    'running': 9.8,
    'jogging': 7.0,
    'intervals': 11.0,
    'cycling': 7.5,
    'gym': 5.0,
    'strength': 5.0,
    'bodyweight': 4.5,
    'hiit': 10.0,
    'badminton': 5.5,
    'tennis': 7.3,
    'pickleball': 5.5,
    'padel': 6.0,
    'squash': 7.3,
    'football': 7.0,
    '5-a-side football': 7.0,
    'basketball': 6.5,
    'swimming': 7.0,
    'rowing': 7.0,
    'stretching': 2.5,
    'mobility': 2.5,
    'yoga': 3.0,
  };

  static const double _defaultMet = 5.0;

  /// Multiplier applied to the base MET for the logged effort level.
  static double intensityFactor(String intensity) => switch (intensity) {
        'Hard' => 1.2,
        'Easy' => 0.85,
        _ => 1.0, // Moderate / unknown
      };

  /// Effective MET for an activity type at a given intensity.
  static double metFor(String type, String intensity) {
    final base = _baseMet[type.trim().toLowerCase()] ?? _defaultMet;
    return base * intensityFactor(intensity);
  }

  /// Estimated calories burned for a single session.
  static int caloriesBurned({
    required String type,
    required String intensity,
    required int minutes,
    required double weightKg,
  }) {
    if (minutes <= 0 || weightKg <= 0) return 0;
    final met = metFor(type, intensity);
    return (met * 3.5 * weightKg / 200 * minutes).round();
  }
}
