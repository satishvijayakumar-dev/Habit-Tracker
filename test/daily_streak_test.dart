import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/activity.dart';
import 'package:habit_tracker/services/habit_provider.dart';

import 'helpers/in_memory_store.dart';

/// The forgiving daily streak: any health-positive action (a logged activity
/// or a closed loop) keeps the chain alive; a recovery action can protect it.
void main() {
  late HabitProvider provider;
  final now = DateTime.now();

  setUp(() async {
    provider = HabitProvider(store: InMemoryHabitStore());
    await provider.load();
  });

  Future<void> activityOn(DateTime day) => provider.addActivity(ActivityLog(
        type: 'Walking',
        durationMinutes: 15,
        completedAt: DateTime(day.year, day.month, day.day, 9),
      ));

  test('no activity = zero streak, not active today', () {
    expect(provider.dailyActiveStreak, 0);
    expect(provider.isActiveToday, isFalse);
  });

  test('consecutive active days build the streak', () async {
    await activityOn(now);
    await activityOn(now.subtract(const Duration(days: 1)));
    await activityOn(now.subtract(const Duration(days: 2)));
    expect(provider.dailyActiveStreak, 3);
    expect(provider.isActiveToday, isTrue);
  });

  test('a gap breaks the streak', () async {
    await activityOn(now);
    await activityOn(now.subtract(const Duration(days: 2))); // skip yesterday
    expect(provider.dailyActiveStreak, 1);
  });

  test('an open today does not break a streak ending yesterday', () async {
    await activityOn(now.subtract(const Duration(days: 1)));
    await activityOn(now.subtract(const Duration(days: 2)));
    expect(provider.isActiveToday, isFalse);
    expect(provider.dailyActiveStreak, 2); // protected by the grace day
  });

  test('logRecoveryAction protects the streak today', () async {
    expect(provider.isActiveToday, isFalse);
    await provider.logRecoveryAction();
    expect(provider.isActiveToday, isTrue);
    expect(provider.dailyActiveStreak, 1);
  });
}
