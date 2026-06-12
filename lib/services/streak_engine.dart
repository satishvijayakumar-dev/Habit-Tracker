import '../models/habit.dart';

/// Pure streak calculations, extracted from the provider so the app's
/// core IP is unit-testable with no database or Flutter dependency.
///
/// All dates passed in must already be normalized day keys
/// (DateTime(y, m, d)).
abstract final class StreakEngine {
  static DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Streak for a habit given its completion data.
  /// [today] is injectable for tests.
  static int currentStreak({
    required Habit habit,
    required Set<DateTime> completedDays,
    required Map<DateTime, Completion> details,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    if (habit.isQuitHabit) {
      return quitStreak(
        completedDays: completedDays,
        createdAt: habit.createdAt,
        today: now,
      );
    }
    if (habit.isAmountTracking) {
      return amountStreak(
        details: details,
        target: habit.targetAmount,
        today: now,
      );
    }
    return checkoffStreak(completedDays: completedDays, today: now);
  }

  /// Consecutive days completed, counting back from today
  /// (or yesterday, if today is not yet done — today being open
  /// must not break an alive streak).
  static int checkoffStreak({
    required Set<DateTime> completedDays,
    required DateTime today,
  }) {
    if (completedDays.isEmpty) return 0;
    var cursor = dayKey(today);
    if (!completedDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Like [checkoffStreak] but a day only counts when the logged amount
  /// reached the target.
  static int amountStreak({
    required Map<DateTime, Completion> details,
    required int target,
    required DateTime today,
  }) {
    if (details.isEmpty) return 0;
    var cursor = dayKey(today);
    final todayDetail = details[cursor];
    if (todayDetail == null || todayDetail.amount < target) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (true) {
      final detail = details[cursor];
      if (detail == null || detail.amount < target) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Quit habits: days since the last slip (or since creation if clean).
  static int quitStreak({
    required Set<DateTime> completedDays,
    required DateTime createdAt,
    required DateTime today,
  }) {
    if (completedDays.isEmpty) {
      final days = dayKey(today).difference(dayKey(createdAt)).inDays;
      return days < 0 ? 0 : days;
    }
    final sorted = completedDays.toList()..sort((a, b) => b.compareTo(a));
    final lastSlip = sorted.first;
    final days = dayKey(today).difference(dayKey(lastSlip)).inDays;
    return days < 0 ? 0 : days;
  }
}
