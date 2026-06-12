import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/streak_engine.dart';

void main() {
  final today = DateTime(2026, 6, 13);
  DateTime day(int daysAgo) => today.subtract(Duration(days: daysAgo));

  group('checkoffStreak', () {
    test('empty completions = 0', () {
      expect(
        StreakEngine.checkoffStreak(completedDays: {}, today: today),
        0,
      );
    });

    test('today done counts as 1', () {
      expect(
        StreakEngine.checkoffStreak(completedDays: {day(0)}, today: today),
        1,
      );
    });

    test('open today does not break a streak ending yesterday', () {
      expect(
        StreakEngine.checkoffStreak(
          completedDays: {day(1), day(2), day(3)},
          today: today,
        ),
        3,
      );
    });

    test('gap breaks the streak', () {
      expect(
        StreakEngine.checkoffStreak(
          completedDays: {day(0), day(1), day(3), day(4)},
          today: today,
        ),
        2,
      );
    });

    test('stale completions far in the past = 0', () {
      expect(
        StreakEngine.checkoffStreak(
          completedDays: {day(10), day(11)},
          today: today,
        ),
        0,
      );
    });
  });

  group('amountStreak', () {
    Completion done(DateTime d, int amount) =>
        Completion(habitId: 1, date: d, amount: amount);

    test('only days meeting the target count', () {
      final details = {
        day(0): done(day(0), 8),
        day(1): done(day(1), 3), // under target
        day(2): done(day(2), 8),
      };
      expect(
        StreakEngine.amountStreak(details: details, target: 8, today: today),
        1,
      );
    });

    test('under-target today falls back to yesterday', () {
      final details = {
        day(0): done(day(0), 2),
        day(1): done(day(1), 8),
        day(2): done(day(2), 8),
      };
      expect(
        StreakEngine.amountStreak(details: details, target: 8, today: today),
        2,
      );
    });

    test('empty = 0', () {
      expect(
        StreakEngine.amountStreak(details: {}, target: 8, today: today),
        0,
      );
    });
  });

  group('quitStreak', () {
    test('never slipped counts from creation', () {
      expect(
        StreakEngine.quitStreak(
          completedDays: {},
          createdAt: day(9),
          today: today,
        ),
        9,
      );
    });

    test('slip resets to days since last slip', () {
      expect(
        StreakEngine.quitStreak(
          completedDays: {day(20), day(4)},
          createdAt: day(30),
          today: today,
        ),
        4,
      );
    });

    test('created today = 0, never negative', () {
      expect(
        StreakEngine.quitStreak(
          completedDays: {},
          createdAt: today,
          today: today,
        ),
        0,
      );
    });
  });

  group('currentStreak dispatch', () {
    test('routes quit habits to quitStreak', () {
      final habit = Habit(
        id: 1,
        name: 'No late snacks',
        habitType: 'quit',
        createdAt: day(5),
      );
      expect(
        StreakEngine.currentStreak(
          habit: habit,
          completedDays: {},
          details: {},
          today: today,
        ),
        5,
      );
    });

    test('routes amount habits to amountStreak', () {
      final habit = Habit(
        id: 1,
        name: 'Water',
        trackingType: 'amount',
        targetAmount: 8,
        createdAt: day(30),
      );
      final details = {
        day(0): Completion(habitId: 1, date: day(0), amount: 9),
      };
      expect(
        StreakEngine.currentStreak(
          habit: habit,
          completedDays: {day(0)},
          details: details,
          today: today,
        ),
        1,
      );
    });
  });
}
